import mimetypes
from typing import Optional

import cloudinary.uploader
from fastapi import HTTPException, UploadFile, status
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from models.album import Album
from models.albumArtist import AlbumArtist
from models.albumSong import AlbumSong
from models.artist import Artist
from models.enums import AlbumArtistRole, UserRole  # FIX: da enums.py
from models.song import Song
from models.user import User
from schemas.album_schema import AlbumCreate, AlbumUpdate  # FIX: type annotation payload


class AlbumService:

    # ------------------------------------------------------------------ #
    #  Query base                                                         #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _base_query(db: Session):
        # FIX: Album.artists e Album.songs rimossi — relazioni viewonly eliminate.
        # Caricamento tramite junction table source-of-truth.
        return db.query(Album).options(
            joinedload(Album.album_artist_links).joinedload(AlbumArtist.artist),
            joinedload(Album.album_song_links).joinedload(AlbumSong.song),
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
        seen: set[str] = set()
        ordered: list[str] = []
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
        artist_map = {a.id: a for a in artists}
        try:
            return [artist_map[aid] for aid in artist_ids]
        except KeyError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="One or more artist IDs are invalid",
            )

    @staticmethod
    def _resolve_songs(db: Session, song_ids: list[str]) -> dict[str, Song]:
        """Restituisce una mappa song_id → Song per accesso O(1)."""
        if not song_ids:
            return {}
        songs = db.query(Song).filter(Song.id.in_(song_ids)).all()
        song_map = {s.id: s for s in songs}
        missing = [sid for sid in song_ids if sid not in song_map]
        if missing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"One or more song IDs are invalid: {missing}",
            )
        return song_map

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

        # FIX: album.artists rimossa — navigo la junction table source-of-truth.
        album_artist_ids = {link.artist_id for link in album.album_artist_links}
        if requester.artist_id not in album_artist_ids:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to manage this album",
            )

    # ------------------------------------------------------------------ #
    #  Lookup                                                             #
    # ------------------------------------------------------------------ #

    @staticmethod
    def get_album_or_404(album_id: str, db: Session) -> Album:
        # FIX: rimosso str(album_id) ridondante.
        album = AlbumService._base_query(db).filter(Album.id == album_id).first()
        if not album:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Album not found",
            )
        return album

    # ------------------------------------------------------------------ #
    #  Lista                                                              #
    # ------------------------------------------------------------------ #

    @staticmethod
    def list_albums(
        db: Session,
        artist_id: Optional[str] = None,
        limit: int = 20,        # FIX: paginazione aggiunta.
        offset: int = 0,
    ) -> dict:
        query = AlbumService._base_query(db)

        if artist_id:
            # FIX: Album.artists rimossa — join attraverso la junction table.
            query = query.join(Album.album_artist_links).filter(
                AlbumArtist.artist_id == artist_id
            )

        total = db.query(Album).count()
        albums = (
            query
            .order_by(Album.release_date.desc().nullslast(), Album.title.asc())
            .offset(offset)
            .limit(limit)
            .all()
        )
        return {"items": albums, "total": total, "limit": limit, "offset": offset}

    # ------------------------------------------------------------------ #
    #  Upload cover                                                       #
    # ------------------------------------------------------------------ #

    @staticmethod
    def upload_cover(cover: UploadFile, db: Session, requester_id: str) -> str:
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
                detail="Invalid file type — upload an image",
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

    # ------------------------------------------------------------------ #
    #  Creazione                                                          #
    # ------------------------------------------------------------------ #

    @staticmethod
    def create_album(
        payload: AlbumCreate,   # FIX: type annotation esplicita
        db: Session,
        requester_id: str,
    ) -> Album:
        requester = AlbumService._get_requester_or_404(db, requester_id)

        artist_ids = AlbumService._ensure_manageable_artist_ids(
            requester, payload.artist_ids or []
        )
        resolved_artists = AlbumService._resolve_artists(db, artist_ids)

        # FIX: usa payload.song_links (schema aggiornato) invece del vecchio
        # song_ids + new_songs che mescolava creazione e collegamento.
        song_ids = [link.song_id for link in payload.song_links]
        song_map = AlbumService._resolve_songs(db, song_ids)

        # FIX: id non passato — default del model.
        # FIX: cover_url convertita a str da AnyHttpUrl.
        db_album = Album(
            title=payload.title,
            release_date=payload.release_date,
            label=payload.label,
            album_type=payload.album_type,
            genre=payload.genre,
            cover_url=str(payload.cover_url) if payload.cover_url else None,
        )

        try:
            db.add(db_album)
            db.flush()  # ottieni db_album.id prima dei link

            # FIX: AlbumArtistRole.PRIMARY esplicito — role non è più nullable.
            # FIX: id non passato.
            db_album.album_artist_links = [
                AlbumArtist(album=db_album, artist=artist, role=AlbumArtistRole.PRIMARY)
                for artist in resolved_artists
            ]

            # FIX: track_number preso direttamente da payload.song_links.
            # FIX: id non passato.
            # FIX: total_tracks rimosso — campo non presente nel model migrato.
            db_album.album_song_links = [
                AlbumSong(
                    album=db_album,
                    song=song_map[link.song_id],
                    track_number=link.track_number,
                )
                for link in payload.song_links
            ]

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

        return AlbumService.get_album_or_404(db_album.id, db)

    # ------------------------------------------------------------------ #
    #  Aggiornamento                                                      #
    # ------------------------------------------------------------------ #

    @staticmethod
    def update_album(
        album_id: str,
        payload: AlbumUpdate,   # FIX: type annotation esplicita
        db: Session,
        requester_id: str,
    ) -> Album:
        requester = AlbumService._get_requester_or_404(db, requester_id)
        album = AlbumService.get_album_or_404(album_id, db)
        AlbumService._assert_album_ownership(album, requester)

        try:
            update_dict = payload.model_dump(exclude_unset=True)

            for field in ("title", "release_date", "label", "album_type", "genre"):
                if field in update_dict:
                    setattr(album, field, update_dict[field])

            # FIX: cover_url convertita a str da AnyHttpUrl.
            if "cover_url" in update_dict:
                raw = update_dict["cover_url"]
                album.cover_url = str(raw) if raw else None

            if "artist_ids" in update_dict:
                artist_ids = AlbumService._ensure_manageable_artist_ids(
                    requester, update_dict["artist_ids"]
                )
                resolved_artists = AlbumService._resolve_artists(db, artist_ids)
                album.album_artist_links.clear()
                for artist in resolved_artists:
                    # FIX: AlbumArtistRole.PRIMARY — role NOT NULL nel model.
                    # FIX: id non passato.
                    album.album_artist_links.append(
                        AlbumArtist(album=album, artist=artist, role=AlbumArtistRole.PRIMARY)
                    )

            if "song_ids" in update_dict:
                song_ids = AlbumService._normalize_ids(update_dict["song_ids"])
                song_map = AlbumService._resolve_songs(db, song_ids)
                album.album_song_links.clear()
                for index, song_id in enumerate(song_ids):
                    # FIX: id non passato. FIX: total_tracks rimosso.
                    album.album_song_links.append(
                        AlbumSong(album=album, song=song_map[song_id], track_number=index + 1)
                    )

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

    # ------------------------------------------------------------------ #
    #  Eliminazione                                                       #
    # ------------------------------------------------------------------ #

    @staticmethod
    def delete_album(album_id: str, db: Session, requester_id: str) -> None:
        requester = AlbumService._get_requester_or_404(db, requester_id)
        album = AlbumService.get_album_or_404(album_id, db)
        AlbumService._assert_album_ownership(album, requester)

        try:
            # FIX: album.songs rimossa — leggo gli ID dalla junction table.
            linked_song_ids = [link.song_id for link in album.album_song_links]

            # Individua le song che appartengono SOLO a questo album
            # e che quindi possono essere eliminate in sicurezza.
            exclusive_song_ids: list[str] = []
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

            db.delete(album)
            db.flush()

            if exclusive_song_ids:
                for song in db.query(Song).filter(Song.id.in_(exclusive_song_ids)).all():
                    db.delete(song)

            db.commit()

        except HTTPException:
            db.rollback()
            raise
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Album deletion failed: {str(e)}",
            )