import mimetypes
import uuid
from typing import Optional

import cloudinary.uploader
from fastapi import HTTPException, UploadFile, status
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from models import album
from models.album import Album
from models.albumArtist import AlbumArtist
from models.albumSong import AlbumSong
from models.artist import Artist
from models.song import Song
from models.songArtist import SongArtist, SongArtistRole
from models.user import User, UserRole


class AlbumService:
    @staticmethod
    def _base_query(db: Session):
        return db.query(Album).options(
            joinedload(Album.artists),
            joinedload(Album.songs),
            joinedload(Album.album_artist_links),
            joinedload(Album.album_song_links),
        )

    @staticmethod
    def _get_requester_or_404(db: Session, user_id: str) -> User:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        return user

    @staticmethod
    def _normalize_ids(values: list[str] | None) -> list[str]:
        if not values:
            return []
        seen = set()
        ordered = []
        for value in values:
            value = str(value).strip()
            if not value or value in seen:
                continue
            seen.add(value)
            ordered.append(value)
        return ordered

    @staticmethod
    def _resolve_artists(db: Session, artist_ids: list[str]) -> list[Artist]:
        if not artist_ids:
            return []

        artists = db.query(Artist).filter(Artist.id.in_(artist_ids)).all()
        artist_map = {artist.id: artist for artist in artists}

        try:
            ordered = [artist_map[artist_id] for artist_id in artist_ids]
        except KeyError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="One or more artist IDs are invalid",
            )

        return ordered

    @staticmethod
    def _resolve_songs(db: Session, song_ids: list[str]) -> list[Song]:
        if not song_ids:
            return []

        songs = db.query(Song).filter(Song.id.in_(song_ids)).all()
        song_map = {song.id: song for song in songs}

        try:
            ordered = [song_map[song_id] for song_id in song_ids]
        except KeyError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="One or more song IDs are invalid",
            )

        return ordered

    @staticmethod
    def _ensure_manageable_artist_ids(
        requester: User,
        artist_ids: list[str],
    ) -> list[str]:
        normalized = AlbumService._normalize_ids(artist_ids)

        if requester.role == UserRole.ADMIN:
            if not normalized:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="At least one artist ID is required",
                )
            return normalized

        if requester.role != UserRole.ARTIST or not requester.artist_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only artists or admins can manage albums",
            )

        if requester.artist_id not in normalized:
            normalized.append(requester.artist_id)

        return normalized

    @staticmethod
    def _assert_album_ownership(album: Album, requester: User) -> None:
        if requester.role == UserRole.ADMIN:
            return

        if requester.role != UserRole.ARTIST or not requester.artist_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to manage this album",
            )

        album_artist_ids = {artist.id for artist in album.artists}
        if requester.artist_id not in album_artist_ids:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to manage this album",
            )

    @staticmethod
    def get_album_or_404(album_id: str, db: Session) -> Album:
        album = (
            AlbumService._base_query(db)
            .filter(Album.id == str(album_id))
            .first()
        )

        if not album:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Album not found",
            )

        return album

    @staticmethod
    def list_albums(
        db: Session,
        artist_id: Optional[str] = None,
    ) -> list[Album]:
        query = AlbumService._base_query(db)

        if artist_id:
            query = query.join(Album.artists).filter(Artist.id == artist_id)

        return query.order_by(Album.release_date.desc().nullslast(), Album.title.asc()).all()

    @staticmethod
    def upload_cover(
        cover: UploadFile,
        db: Session,
        requester_id: str,
    ) -> str:
        requester = AlbumService._get_requester_or_404(db, requester_id)

        if requester.role not in {UserRole.ADMIN, UserRole.ARTIST}:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only artists or admins can upload album covers",
            )

        if requester.role == UserRole.ARTIST and not requester.artist_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Artist profile required to upload album covers",
            )

        content_type = cover.content_type
        guessed_type, _ = mimetypes.guess_type(cover.filename or "")

        is_image_type = (
            (content_type and content_type.startswith("image/"))
            or (guessed_type and guessed_type.startswith("image/"))
            or content_type == "application/octet-stream"
        )

        if not is_image_type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid file type. Upload an image.",
            )

        try:
            upload_res = cloudinary.uploader.upload(
                cover.file,
                resource_type="image",
                folder="artify/albums/covers",
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Album cover upload failed: {str(e)}",
            )

        cover_url = upload_res.get("secure_url")
        if not cover_url:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Album cover upload succeeded but no secure_url was returned",
            )

        return cover_url

    @staticmethod
    def create_album(payload, db: Session, requester_id: str) -> Album:
        requester = AlbumService._get_requester_or_404(db, requester_id)

        artist_ids = AlbumService._ensure_manageable_artist_ids(
            requester,
            getattr(payload, "artist_ids", []),
        )

        resolved_artists = AlbumService._resolve_artists(db, artist_ids)
        existing_song_ids = AlbumService._normalize_ids(getattr(payload, "song_ids", []))
        existing_songs = AlbumService._resolve_songs(db, existing_song_ids)

        album_id = str(uuid.uuid4())
        db_album = Album(
            id=album_id,
            title=payload.title,
            release_date=payload.release_date,
            label=payload.label,
            album_type=payload.album_type,
            genre=payload.genre,
            cover_url=payload.cover_url,
        )

        try:
            db.add(db_album)
            db.flush()

            all_songs_ordered: list[Song] = list(existing_songs)

            for track in getattr(payload, "new_songs", []) or []:
                new_song = Song(
                    id=str(uuid.uuid4()),
                    song_name=track.song_name,
                    song_url=track.song_url,
                    thumbnail_url=track.thumbnail_url or payload.cover_url,
                    release_date=track.release_date or payload.release_date,
                    genre=track.genre or payload.genre,
                    user_id=requester.id,
                )
                db.add(new_song)
                db.flush()

                track_artist_ids = AlbumService._normalize_ids(
                    getattr(track, "artist_ids", None) or artist_ids
                )

                if requester.role == UserRole.ARTIST and requester.artist_id:
                    if requester.artist_id not in track_artist_ids:
                        track_artist_ids.append(requester.artist_id)

                resolved_track_artists = AlbumService._resolve_artists(
                    db,
                    track_artist_ids,
                )

                artist_roles = getattr(track, "artist_roles", None) or {}

                for artist in resolved_track_artists:
                    role = artist_roles.get(artist.id, SongArtistRole.PRIMARY)
                    db.add(
                        SongArtist(
                            id=str(uuid.uuid4()),
                            song=new_song,
                            artist=artist,
                            role=role,
                        )
                    )

                all_songs_ordered.append(new_song)

            db_album.album_artist_links = [
                AlbumArtist(
                    id=str(uuid.uuid4()),
                    album=db_album,
                    artist=artist,
                )
                for artist in resolved_artists
            ]

            db_album.album_song_links = [
                AlbumSong(
                    id=str(uuid.uuid4()),
                    album=db_album,
                    song=song,
                    track_number=index + 1,
                )
                for index, song in enumerate(all_songs_ordered)
            ]

            db_album.total_tracks = len(all_songs_ordered)

            db.commit()
        except IntegrityError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Album creation failed due to integrity error: {str(e.orig)}",
            )
        except HTTPException:
            db.rollback()
            raise
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Album creation failed: {str(e)}",
            )

        return AlbumService.get_album_or_404(album_id, db)

    @staticmethod
    def update_album(album_id: str, payload, db: Session, requester_id: str) -> Album:
        requester = AlbumService._get_requester_or_404(db, requester_id)
        album = AlbumService.get_album_or_404(album_id, db)

        AlbumService._assert_album_ownership(album, requester)

        try:
            update_dict = payload.model_dump(exclude_unset=True)

            for field in [
                "title",
                "release_date",
                "label",
                "album_type",
                "genre",
                "cover_url",
            ]:
                if field in update_dict:
                    setattr(album, field, update_dict[field])

            if "artist_ids" in update_dict:
                artist_ids = AlbumService._ensure_manageable_artist_ids(
                    requester,
                    update_dict["artist_ids"],
                )
                resolved_artists = AlbumService._resolve_artists(db, artist_ids)

                album.album_artist_links.clear()
                for artist in resolved_artists:
                    album.album_artist_links.append(
                        AlbumArtist(
                            id=str(uuid.uuid4()),
                            album=album,
                            artist=artist,
                        )
                    )

            if "song_ids" in update_dict:
                song_ids = AlbumService._normalize_ids(update_dict["song_ids"])
                resolved_songs = AlbumService._resolve_songs(db, song_ids)

                album.album_song_links.clear()
                for index, song in enumerate(resolved_songs):
                    album.album_song_links.append(
                        AlbumSong(
                            id=str(uuid.uuid4()),
                            album=album,
                            song=song,
                            track_number=index + 1,
                        )
                    )

                album.total_tracks = len(resolved_songs)

            db.commit()
        except IntegrityError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Album update failed due to integrity error: {str(e.orig)}",
            )
        except HTTPException:
            db.rollback()
            raise
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Album update failed: {str(e)}",
            )

        return AlbumService.get_album_or_404(album_id, db)

    @staticmethod
    def delete_album(album_id: str, db: Session, requester_id: str) -> None:
        requester = AlbumService._get_requester_or_404(db, requester_id)
        album = AlbumService.get_album_or_404(album_id, db)

        AlbumService._assert_album_ownership(album, requester)

        try:
            # 1. Prendiamo gli ID delle song collegate a questo album
            linked_song_ids = [song.id for song in album.songs]

            # 2. Capire quali song appartengono SOLO a questo album
            #    e quindi possono essere eliminate in sicurezza
            exclusive_song_ids = []
            if linked_song_ids:
                counts = (
                    db.query(
                        AlbumSong.song_id,
                        func.count(AlbumSong.album_id).label("album_count"),
                    )
                    .filter(AlbumSong.song_id.in_(linked_song_ids))
                    .group_by(AlbumSong.song_id)
                    .all()
                )

                exclusive_song_ids = [
                    row.song_id for row in counts if row.album_count == 1
                ]

            # 3. Elimina prima l'album
            db.delete(album)
            db.flush()

            # 4. Elimina le song che esistevano solo dentro questo album
            if exclusive_song_ids:
                songs_to_delete = (
                    db.query(Song)
                    .filter(Song.id.in_(exclusive_song_ids))
                    .all()
                )

                for song in songs_to_delete:
                    db.delete(song)

            db.commit()

        except HTTPException:
            db.rollback()
            raise
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Album deletion failed: error: {str(e)}",
            )