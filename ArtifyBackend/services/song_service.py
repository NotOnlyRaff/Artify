import cloudinary.uploader
from fastapi import HTTPException, UploadFile, status
from sqlalchemy.orm import Session, joinedload

from models.enums import SongArtistRole, UserRole  # FIX: import da enums.py
from models.song import Song
from models.songArtist import SongArtist
from models.albumSong import AlbumSong
from models.favorite import Favorite
from models.artist import Artist
from models.user import User
from schemas.song_schema import SongCreate


class SongService:

    # ------------------------------------------------------------------ #
    #  Upload                                                             #
    # ------------------------------------------------------------------ #

    @staticmethod
    def upload_song(
        db: Session,
        song_file: UploadFile,
        thumbnail_file: UploadFile,
        song_data: SongCreate,          # FIX: SongCreate invece di dict grezzo
    ) -> Song:
        # FIX: validazione artist_links dallo schema, non da un artist_ids separato.
        if not song_data.artist_links:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A song must have at least one artist",
            )

        # Deduplica e verifica esistenza artisti
        artist_ids = list({link.artist_id for link in song_data.artist_links})
        artists = db.query(Artist).filter(Artist.id.in_(artist_ids)).all()
        found_ids = {a.id for a in artists}
        missing = [aid for aid in artist_ids if aid not in found_ids]
        if missing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Artist(s) not found: {missing}",
            )

        song_public_id: str | None = None
        thumb_public_id: str | None = None

        try:
            # Upload audio — Cloudinary già configurato globalmente in main.py
            # FIX: usiamo un placeholder per il folder; l'ID reale lo otteniamo
            # dopo il flush. Cloudinary accetta qualsiasi folder string.
            song_res = cloudinary.uploader.upload(
                song_file.file,
                resource_type="video",
                folder="artify/songs",
            )
            song_public_id = song_res.get("public_id")
            song_url = song_res.get("secure_url")
            if not song_url:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Cloudinary did not return a secure URL for the song file",
                )

            # Upload thumbnail
            thumb_res = cloudinary.uploader.upload(
                thumbnail_file.file,
                resource_type="image",
                folder="artify/thumbnails",
            )
            thumb_public_id = thumb_res.get("public_id")
            thumbnail_url = thumb_res.get("secure_url")
            if not thumbnail_url:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="Cloudinary did not return a secure URL for the thumbnail",
                )

            # FIX: id non passato — generato dal default del model.
            # FIX: composer_id e composer_name entrambi mappati dallo schema.
            new_song = Song(
                song_name=song_data.song_name,
                song_url=song_url,
                thumbnail_url=thumbnail_url,
                release_date=song_data.release_date,
                composer_id=song_data.composer_id,
                composer_name=song_data.composer_name,
                producer_id=song_data.producer_id,
                producer_name=song_data.producer_name,
                genre=song_data.genre,
                lyrics=song_data.lyrics,
                mood=song_data.mood,
                duration_seconds=song_data.duration_seconds,
            )
            db.add(new_song)
            db.flush()  # ottieni new_song.id prima di creare i link

            # FIX: ruoli presi esplicitamente da artist_links, non per posizione.
            # FIX: id SongArtist non passato — generato dal default del model.
            for link in song_data.artist_links:
                db.add(SongArtist(
                    song_id=new_song.id,
                    artist_id=link.artist_id,
                    role=link.role,
                ))

            db.commit()
            db.refresh(new_song)
            return new_song

        except HTTPException:
            db.rollback()
            # FIX: cleanup Cloudinary se il DB fallisce dopo l'upload.
            if song_public_id:
                try:
                    cloudinary.uploader.destroy(song_public_id, resource_type="video")
                except Exception:
                    pass
            if thumb_public_id:
                try:
                    cloudinary.uploader.destroy(thumb_public_id, resource_type="image")
                except Exception:
                    pass
            raise

        except Exception as e:
            db.rollback()
            if song_public_id:
                try:
                    cloudinary.uploader.destroy(song_public_id, resource_type="video")
                except Exception:
                    pass
            if thumb_public_id:
                try:
                    cloudinary.uploader.destroy(thumb_public_id, resource_type="image")
                except Exception:
                    pass
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to upload song: {str(e)}",
            )

        finally:
            try:
                song_file.file.close()
            except Exception:
                pass
            try:
                thumbnail_file.file.close()
            except Exception:
                pass

    # ------------------------------------------------------------------ #
    #  Preferiti                                                          #
    # ------------------------------------------------------------------ #

    @staticmethod
    def toggle_favorite(db: Session, user_id: str, song_id: str) -> bool:
        # FIX: verifica esistenza song prima di procedere.
        if not db.query(Song).filter(Song.id == song_id).first():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Song not found",
            )

        fav = db.query(Favorite).filter_by(user_id=user_id, song_id=song_id).first()

        if fav:
            db.delete(fav)
            db.commit()
            return False

        # FIX: id non passato — generato dal default del model.
        db.add(Favorite(user_id=user_id, song_id=song_id))
        db.commit()
        return True

    # ------------------------------------------------------------------ #
    #  Lettura                                                            #
    # ------------------------------------------------------------------ #

    @staticmethod
    def get_all_songs(
        db: Session,
        limit: int = 20,        # FIX: paginazione — restituire tutto il DB in una query
        offset: int = 0,        # è bloccante e insostenibile con dati in crescita.
    ) -> dict:
        # FIX: joinedload(Song.albums) rimosso — relazione eliminata dal model.
        # Sostituito con album_song_links -> album.
        base_query = db.query(Song).options(
            joinedload(Song.song_artist_links).joinedload(SongArtist.artist),
            joinedload(Song.album_song_links).joinedload(AlbumSong.album),
        )
        total = base_query.count()
        songs = base_query.offset(offset).limit(limit).all()
        return {"items": songs, "total": total, "limit": limit, "offset": offset}

    @staticmethod
    def get_song_by_id(db: Session, song_id: str) -> Song:
        # FIX: joinedload(Song.albums) rimosso — stesso motivo.
        song = (
            db.query(Song)
            .options(
                joinedload(Song.song_artist_links).joinedload(SongArtist.artist),
                joinedload(Song.album_song_links).joinedload(AlbumSong.album),
            )
            .filter(Song.id == song_id)
            .first()
        )
        if not song:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Song not found",
            )
        return song

    # ------------------------------------------------------------------ #
    #  Eliminazione                                                       #
    # ------------------------------------------------------------------ #

    @staticmethod
    def delete_song(db: Session, song_id: str, current_user: User) -> None:
        song = (
            db.query(Song)
            .options(joinedload(Song.song_artist_links))
            .filter(Song.id == song_id)
            .first()
        )
        if not song:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Song not found",
            )

        is_admin = current_user.role == UserRole.ADMIN
        is_artist_owner = any(
            link.artist_id == current_user.artist_id
            for link in song.song_artist_links
        )
        if not is_admin and not is_artist_owner:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to delete this song",
            )

        try:
            db.delete(song)
            db.commit()
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Song deletion failed: {str(e)}",
            )