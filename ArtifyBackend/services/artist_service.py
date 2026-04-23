import mimetypes
import re

import cloudinary
import cloudinary.uploader
from fastapi import HTTPException, UploadFile, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from models.album import Album
from models.albumArtist import AlbumArtist
from models.artist import Artist
from models.enums import AlbumArtistRole, SongArtistRole, UserRole  # FIX: da enums.py
from models.song import Song
from models.songArtist import SongArtist
from models.user import User
from schemas.artist_schema import ArtistCreate, ArtistUpdate  # FIX: type annotation payload
from core.config import settings


class ArtistService:

    # ------------------------------------------------------------------ #
    #  Query base                                                         #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _base_query(db: Session):
        # FIX: joinedload su relazioni rimosse (Artist.songs, Artist.albums)
        # sostituite con le junction table source-of-truth.
        return db.query(Artist).options(
            joinedload(Artist.song_artist_links).joinedload(SongArtist.song),
            joinedload(Artist.album_artist_links).joinedload(AlbumArtist.album),
            joinedload(Artist.user),
        )

    @staticmethod
    def get_artist_or_404(artist_id: str, db: Session) -> Artist:
        # FIX: rimosso str(artist_id) ridondante.
        artist = ArtistService._base_query(db).filter(Artist.id == artist_id).first()
        if not artist:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Artist not found",
            )
        return artist

    # ------------------------------------------------------------------ #
    #  Lista e ricerca                                                    #
    # ------------------------------------------------------------------ #

    @staticmethod
    def list_artists(
        db: Session,
        limit: int = 20,    # FIX: paginazione — restituire tutto il catalogo in una
        offset: int = 0,    # query con joinedload è bloccante a scala.
    ) -> dict:
        base = ArtistService._base_query(db).order_by(Artist.name.asc())
        total = db.query(Artist).count()
        artists = base.offset(offset).limit(limit).all()
        return {"items": artists, "total": total, "limit": limit, "offset": offset}

    @staticmethod
    def search_artists(
        db: Session,
        q: str | None = None,
        song_id: str | None = None,
        album_id: str | None = None,
        limit: int = 20,
        offset: int = 0,
    ) -> dict:
        query = ArtistService._base_query(db)

        if q:
            pattern = f"%{q.strip()}%"
            query = query.filter(
                Artist.name.ilike(pattern) | Artist.display_name.ilike(pattern)
            )

        # FIX: join attraverso le junction table — Artist.songs e Artist.albums
        # non esistono più come relazioni dirette sul model.
        if song_id:
            query = (
                query
                .join(Artist.song_artist_links)
                .join(SongArtist.song)
                .filter(Song.id == song_id)
            )

        if album_id:
            query = (
                query
                .join(Artist.album_artist_links)
                .join(AlbumArtist.album)
                .filter(Album.id == album_id)
            )

        total = query.distinct().count()
        artists = query.distinct().offset(offset).limit(limit).all()
        return {"items": artists, "total": total, "limit": limit, "offset": offset}

    # ------------------------------------------------------------------ #
    #  Helper privati                                                     #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _resolve_songs(db: Session, song_ids: list[str]) -> list[Song]:
        if not song_ids:
            return []
        songs = db.query(Song).filter(Song.id.in_(song_ids)).all()
        if len(songs) != len(set(song_ids)):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Some song IDs do not exist",
            )
        return songs

    @staticmethod
    def _resolve_albums(db: Session, album_ids: list[str]) -> list[Album]:
        if not album_ids:
            return []
        albums = db.query(Album).filter(Album.id.in_(album_ids)).all()
        if len(albums) != len(set(album_ids)):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Some album IDs do not exist",
            )
        return albums

    @staticmethod
    def _normalize_slug(slug: str | None) -> str | None:
        if slug is None:
            return None
        normalized = slug.strip().lower()
        if not normalized:
            return None
        normalized = re.sub(r"[^a-z0-9\s-]", "", normalized)
        normalized = re.sub(r"\s+", "-", normalized)
        normalized = re.sub(r"-+", "-", normalized)
        normalized = normalized.strip("-")
        return normalized or None

    @staticmethod
    def _ensure_slug_available(
        db: Session,
        slug: str | None,
        exclude_artist_id: str | None = None,
    ) -> str | None:
        normalized = ArtistService._normalize_slug(slug)
        if normalized is None:
            return None
        query = db.query(Artist).filter(Artist.slug == normalized)
        if exclude_artist_id:
            query = query.filter(Artist.id != exclude_artist_id)
        if query.first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Artist slug already exists",
            )
        return normalized

    # ------------------------------------------------------------------ #
    #  Upload immagine                                                    #
    # ------------------------------------------------------------------ #

    @staticmethod
    def upload_artist_image(image: UploadFile, current_user: User) -> str:
        content_type = image.content_type
        guessed_type, _ = mimetypes.guess_type(image.filename or "")
        is_image_type = (
            (content_type and content_type.startswith("image/"))
            or (guessed_type and guessed_type.startswith("image/"))
            or content_type == "application/octet-stream"
        )
        if not is_image_type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid image file type",
            )
        # Configura Cloudinary esplicitamente ad ogni chiamata.
        # Fix difensivo: garantisce che le credenziali siano presenti anche se
        # cloudinary.config() in main.py non è ancora stato eseguito (es. in test
        # o se il lifespan non è stato aggiornato).
        cloudinary.config(
            cloud_name=settings.CLOUDINARY_CLOUD_NAME,
            api_key=settings.CLOUDINARY_API_KEY,
            api_secret=settings.CLOUDINARY_API_SECRET,
            secure=True,
        )
        try:
            upload_res = cloudinary.uploader.upload(
                image.file,
                resource_type="image",
                folder=f"artify/artists/{current_user.id}",
                overwrite=False,
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error uploading artist image: {e}",
            )
        image_url = upload_res.get("secure_url")
        if not image_url:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Image upload succeeded but no secure_url was returned",
            )
        return image_url

    # ------------------------------------------------------------------ #
    #  Creazione                                                          #
    # ------------------------------------------------------------------ #

    @staticmethod
    def create_artist(
        payload: ArtistCreate,  # FIX: type annotation esplicita
        db: Session,
        current_user: User,
    ) -> Artist:
        if current_user.role == UserRole.ARTIST and current_user.artist_id is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You already have an artist profile linked to your account",
            )

        slug = ArtistService._ensure_slug_available(db, payload.slug)
        songs = ArtistService._resolve_songs(db, payload.song_ids or [])
        albums = ArtistService._resolve_albums(db, payload.album_ids or [])

        # FIX: id non passato — generato dal default del model.
        # FIX: AnyHttpUrl convertita a str.
        db_artist = Artist(
            name=payload.name,
            display_name=payload.display_name,
            slug=slug,
            image_url=str(payload.image_url) if payload.image_url else None,
            bio=payload.bio,
            country=payload.country,
        )

        # FIX: id SongArtist non passato — default del model.
        db_artist.song_artist_links = [
            SongArtist(song=song, artist=db_artist, role=SongArtistRole.PRIMARY)
            for song in songs
        ]

        # FIX: role=None rimosso — violava il NOT NULL del model aggiornato.
        # FIX: id AlbumArtist non passato — default del model.
        db_artist.album_artist_links = [
            AlbumArtist(album=album, artist=db_artist, role=AlbumArtistRole.PRIMARY)
            for album in albums
        ]

        try:
            db.add(db_artist)

            if current_user.role == UserRole.ARTIST:
                db.flush()  # ottieni db_artist.id prima di assegnarlo
                current_user.artist_id = db_artist.id
                db.add(current_user)

            db.commit()

        except IntegrityError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Integrity error while creating artist: {str(e.orig)}",
            )
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Artist creation failed: {str(e)}",
            )

        return ArtistService.get_artist_or_404(db_artist.id, db)

    # ------------------------------------------------------------------ #
    #  Aggiornamento                                                      #
    # ------------------------------------------------------------------ #

    @staticmethod
    def update_artist(
        artist_id: str,
        payload: ArtistUpdate,  # FIX: type annotation esplicita
        db: Session,
        current_user: User,
    ) -> Artist:
        if current_user.role == UserRole.ARTIST and current_user.artist_id != artist_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update another artist's profile",
            )

        artist = ArtistService.get_artist_or_404(artist_id, db)

        if payload.name is not None:
            artist.name = payload.name
        if payload.display_name is not None:
            artist.display_name = payload.display_name
        if payload.slug is not None:
            artist.slug = ArtistService._ensure_slug_available(
                db, payload.slug, exclude_artist_id=artist_id
            )
        if payload.image_url is not None:
            # FIX: AnyHttpUrl convertita a str.
            artist.image_url = str(payload.image_url)
        if payload.bio is not None:
            artist.bio = payload.bio
        if payload.country is not None:
            artist.country = payload.country

        # song_ids e album_ids sono opzionali in ArtistUpdate (rimossi dalla schema review).
        # Si gestiscono tramite endpoint dedicati — non direttamente nell'update artista.
        song_ids = getattr(payload, 'song_ids', None)
        if song_ids is not None:
            songs = ArtistService._resolve_songs(db, song_ids)
            artist.song_artist_links.clear()
            for song in songs:
                artist.song_artist_links.append(
                    SongArtist(song=song, artist=artist, role=SongArtistRole.PRIMARY)
                )

        album_ids = getattr(payload, 'album_ids', None)
        if album_ids is not None:
            albums = ArtistService._resolve_albums(db, album_ids)
            artist.album_artist_links.clear()
            for album in albums:
                artist.album_artist_links.append(
                    AlbumArtist(album=album, artist=artist, role=AlbumArtistRole.PRIMARY)
                )

        try:
            db.commit()
        except IntegrityError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Integrity error while updating artist: {str(e.orig)}",
            )
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Artist update failed: {str(e)}",
            )

        return ArtistService.get_artist_or_404(artist_id, db)

    # ------------------------------------------------------------------ #
    #  Eliminazione                                                       #
    # ------------------------------------------------------------------ #

    @staticmethod
    def delete_artist(artist_id: str, db: Session) -> None:
        artist = db.query(Artist).filter(Artist.id == artist_id).first()
        if not artist:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Artist not found",
            )

        # FIX: rimossa la nullificazione manuale di User.artist_id.
        # Il FK ondelete="SET NULL" su User.artist_id gestisce questo
        # automaticamente a livello DB — il codice manuale era ridondante
        # e introduceva una finestra di race condition.
        try:
            db.delete(artist)
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Artist deletion failed: {str(e)}",
            )