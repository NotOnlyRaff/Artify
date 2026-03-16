import uuid
import cloudinary.uploader
from fastapi import HTTPException, UploadFile
from sqlalchemy.orm import Session, joinedload

from models.song import Song
from models.favorite import Favorite
from models.songArtist import SongArtist, SongArtistRole
from models.artist import Artist
from core.config import settings


class SongService:

    @staticmethod
    def upload_song(
        db: Session,
        song_file: UploadFile,
        thumbnail_file: UploadFile,
        song_data: dict,
        artist_ids: list[str],
    ):
        if not artist_ids:
            raise HTTPException(
                status_code=400,
                detail="A song must have at least one artist"
            )

        # deduplica finale di sicurezza
        artist_ids = list(dict.fromkeys(artist_ids))

        # verifica che tutti gli artisti esistano
        artists = db.query(Artist).filter(Artist.id.in_(artist_ids)).all()
        found_artist_ids = {artist.id for artist in artists}

        missing_artist_ids = [artist_id for artist_id in artist_ids if artist_id not in found_artist_ids]
        if missing_artist_ids:
            raise HTTPException(
                status_code=404,
                detail=f"Artist(s) not found: {missing_artist_ids}"
            )

        song_id = str(uuid.uuid4())

        try:
            # Upload audio
            song_res = cloudinary.uploader.upload(
                song_file.file,
                resource_type="auto",
                folder=f"artify/songs/{song_id}",
                cloud_name=settings.CLOUDINARY_CLOUD_NAME,
                api_key=settings.CLOUDINARY_API_KEY,
                api_secret=settings.CLOUDINARY_API_SECRET,
            )

            # Upload thumbnail
            thumb_res = cloudinary.uploader.upload(
                thumbnail_file.file,
                resource_type="image",
                folder=f"artify/thumbnails/{song_id}",
                cloud_name=settings.CLOUDINARY_CLOUD_NAME,
                api_key=settings.CLOUDINARY_API_KEY,
                api_secret=settings.CLOUDINARY_API_SECRET,
            )

            new_song = Song(
                id=song_id,
                song_name=song_data["song_name"],
                song_url=song_res["url"],
                thumbnail_url=thumb_res["url"],
                release_date=song_data["release_date"],
                composer_name=song_data["composer_name"],
                producer_name=song_data.get("producer_name"),
                genre=song_data.get("genre"),
                lyrics=song_data.get("lyrics"),
                mood=song_data.get("mood"),
            )

            db.add(new_song)
            db.flush()

            for index, artist_id in enumerate(artist_ids):
                role = SongArtistRole.PRIMARY if index == 0 else SongArtistRole.FEATURED

                link = SongArtist(
                    id=str(uuid.uuid4()),
                    song_id=song_id,
                    artist_id=artist_id,
                    role=role,
                )
                db.add(link)

            db.commit()
            db.refresh(new_song)
            return new_song

        except HTTPException:
            db.rollback()
            raise
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=500,
                detail=f"Failed to upload song: {str(e)}"
            )

    @staticmethod
    def toggle_favorite(db: Session, user_id: str, song_id: str):
        fav = db.query(Favorite).filter_by(user_id=user_id, song_id=song_id).first()

        if fav:
            db.delete(fav)
            db.commit()
            return False

        new_fav = Favorite(
            id=str(uuid.uuid4()),
            user_id=user_id,
            song_id=song_id
        )
        db.add(new_fav)
        db.commit()
        return True

    @staticmethod
    def get_all_songs(db: Session):
        return db.query(Song).options(
            joinedload(Song.song_artist_links).joinedload(SongArtist.artist),
            joinedload(Song.albums)
        ).all()
    
    def get_song_by_id(db: Session, song_id: str):
        song = db.query(Song).options(
            joinedload(Song.song_artist_links).joinedload(SongArtist.artist),
            joinedload(Song.albums)
        ).filter(Song.id == song_id).first()

        if not song:
            raise HTTPException(status_code=404, detail="Song not found")

        return song