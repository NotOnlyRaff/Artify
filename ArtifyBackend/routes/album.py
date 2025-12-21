# routes/album.py

import uuid
from typing import List, Optional

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.orm import Session, joinedload

from database import get_db
from middleware.auth_middleware import auth_middleware

from models.album import Album
from models.artist import Artist
from models.song import Song
from models.albumArtist import AlbumArtist      # join album–artist
from models.albumSong import AlbumSong          # join album–song

from schemas.album import (
    AlbumCreate,
    AlbumUpdate,
    AlbumOut,
)

router = APIRouter(tags=["albums"])


# ---------- UTILITY INTERNA ----------

def _get_album_or_404(album_id: str, db: Session) -> Album:
    album = (
        db.query(Album)
        .options(
            joinedload(Album.artists),  # relazione M:N viewonly
            joinedload(Album.songs),
        )
        .filter(Album.id == album_id)
        .first()
    )

    if not album:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Album not found",
        )
    return album


def _resolve_artists(
    db: Session,
    artist_ids: List[str],
) -> List[Artist]:
    if not artist_ids:
        return []

    artists = (
        db.query(Artist)
        .filter(Artist.id.in_(artist_ids))
        .all()
    )

    if len(artists) != len(set(artist_ids)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Some artist IDs do not exist",
        )

    return artists


def _resolve_songs(
    db: Session,
    song_ids: List[str],
) -> List[Song]:
    if not song_ids:
        return []

    songs = (
        db.query(Song)
        .filter(Song.id.in_(song_ids))
        .all()
    )

    if len(songs) != len(set(song_ids)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Some song IDs do not exist",
        )

    return songs


# routes/album.py (solo create_album aggiornato)
@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=AlbumOut,
)
def create_album(
    payload: AlbumCreate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    print("=== [create_album] DEBUG START ===")
    print("artist_ids:", payload.artist_ids)
    print("song_ids:", payload.song_ids)
    print("new_songs count:", len(payload.new_songs))
    for i, track in enumerate(payload.new_songs):
        print(
            f"  [NEW {i}] song_name={track.song_name!r}, "
            f"song_url={track.song_url!r}, "
            f"composer_name={track.composer_name!r}, "
            f"artist_ids={track.artist_ids}, "
            f"artist_roles={track.artist_roles}"
        )
    album_id = str(uuid.uuid4())

    # ---------- ARTISTI DELL'ALBUM ----------
    album_artists = _resolve_artists(db, payload.artist_ids)

    # ---------- CANZONI ESISTENTI ----------
    existing_songs: List[Song] = _resolve_songs(db, payload.song_ids)

    # Mantieni l'ordine esatto di song_ids per il track_number
    existing_map = {s.id: s for s in existing_songs}
    ordered_existing_songs: List[Song] = [
        existing_map[s_id] for s_id in payload.song_ids
    ]

    # ---------- NUOVE CANZONI INLINE ----------
    new_song_entities: List[Song] = []

    for track in payload.new_songs:
        song_id = str(uuid.uuid4())

        new_song = Song(
            id=song_id,
            song_name=track.song_name,
            song_url=track.song_url,  # deve essere già valorizzata dal FE
            thumbnail_url=track.thumbnail_url or payload.cover_url,
            release_date=track.release_date or payload.release_date,
            composer_name=track.composer_name,
            producer_name=track.producer_name,
            genre=track.genre or payload.genre,
            lyrics=track.lyrics,
            mood=track.mood,
            # TODO: se il tuo model Song ha un owner/user_id non nullable,
            #       valorizzalo qui usando auth_details.
            # es:
            # user_id = auth_details["user_id"]
        )

        db.add(new_song)
        new_song_entities.append(new_song)

        # TODO (facoltativo, se hai una tabella SongArtist):
        # - collega track.artist_ids alla nuova Song
        #   from models.songArtist import SongArtist
        #   song_artists = _resolve_artists(db, track.artist_ids)
        #   for artist in song_artists:
        #       db.add(
        #           SongArtist(
        #               id=str(uuid.uuid4()),
        #               song_id=song_id,
        #               artist_id=artist.id,
        #               role=None,  # oppure una logica di ruolo
        #           )
        #       )

    # ---------- UNISCI TUTTE LE SONG IN ORDINE ----------
    all_songs_in_order: List[Song] = ordered_existing_songs + new_song_entities

    print("[create_album] existing_songs:", len(ordered_existing_songs))
    print("[create_album] new_song_entities:", len(new_song_entities))
    print("[create_album] all_songs_in_order:", len(all_songs_in_order))

    # ---------- CREA L'ALBUM ----------
    db_album = Album(
        id=album_id,
        title=payload.title,
        release_date=payload.release_date,
        label=payload.label,
        album_type=payload.album_type,
        genre=payload.genre,
        cover_url=payload.cover_url,
        total_tracks=len(all_songs_in_order) if all_songs_in_order else None,
    )

    # Join album–artist
    db_album.album_artist_links = [
        AlbumArtist(
            id=str(uuid.uuid4()),
            album=db_album,
            artist=artist,
            role=None,  # in futuro: 'primary', 'guest', ecc.
        )
        for artist in album_artists
    ]

    # Join album–song con track_number nell'ordine corretto
    db_album.album_song_links = [
        AlbumSong(
            id=str(uuid.uuid4()),
            album=db_album,
            song=song,
            track_number=index + 1,
        )
        for index, song in enumerate(all_songs_in_order)
    ]

    db.add(db_album)
    db.commit()
    print("[create_album] COMMIT OK, album_id:", album_id)


    # Ricarica con joinedload per avere artists/songs valorizzati
    db_album = _get_album_or_404(album_id, db)

    return db_album


# ---------- GET SINGOLO ALBUM ----------

@router.get(
    "/{album_id}",
    response_model=AlbumOut,
)
def get_album(
    album_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Restituisce un album con artisti e tracce.
    """
    album = _get_album_or_404(album_id, db)
    return album


# ---------- LISTA ALBUM ----------

@router.get(
    "",
    response_model=List[AlbumOut],
)
def list_albums(
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
    artist_id: Optional[str] = None,
):
    """
    Lista di album.

    - Se `artist_id` è valorizzato, filtra gli album di quell'artista.
    """
    query = (
        db.query(Album)
        .options(
            joinedload(Album.artists),
            joinedload(Album.songs),
        )
    )

    if artist_id:
        # usa la relazione M:N viewonly verso Artist
        query = query.join(Album.artists).filter(Artist.id == artist_id)

    albums = query.all()
    return albums


# ---------- UPDATE ALBUM ----------

@router.patch(
    "/{album_id}",
    response_model=AlbumOut,
)
def update_album(
    album_id: str,
    payload: AlbumUpdate,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Aggiornamento parziale di un album.

    - Puoi cambiare metadati (titolo, label, ecc.)
    - Puoi riassegnare lista di artisti e songs passando gli ID:
      in questo caso rimpiazziamo le righe di join album_artists / album_songs.
    """
    album = _get_album_or_404(album_id, db)

    # Metadati base
    if payload.title is not None:
        album.title = payload.title
    if payload.release_date is not None:
        album.release_date = payload.release_date
    if payload.label is not None:
        album.label = payload.label
    if payload.album_type is not None:
        album.album_type = payload.album_type
    if payload.cover_url is not None:
        album.cover_url = payload.cover_url
    if payload.genre is not None:
        album.genre = payload.genre

    # 🔹 Aggiornamento relazioni via join tables

    # 1) Artisti
    if payload.artist_ids is not None:
        artists = _resolve_artists(db, payload.artist_ids)

        # Cancella i vecchi link (delete-orphan gestito dalla relationship)
        album.album_artist_links.clear()

        # Crea nuovi link
        for artist in artists:
            album.album_artist_links.append(
                AlbumArtist(
                    id=str(uuid.uuid4()),
                    album=album,
                    artist=artist,
                    role=None,
                )
            )

    # 2) Songs + track_number in base all'ordine di payload.song_ids
    if payload.song_ids is not None:
        songs = _resolve_songs(db, payload.song_ids)

        song_map = {s.id: s for s in songs}
        ordered_songs: List[Song] = [song_map[s_id] for s_id in payload.song_ids]

        # Cancella i vecchi link
        album.album_song_links.clear()

        # Crea nuovi link con il track_number aggiornato
        for index, song in enumerate(ordered_songs):
            album.album_song_links.append(
                AlbumSong(
                    id=str(uuid.uuid4()),
                    album=album,
                    song=song,
                    track_number=index + 1,
                )
            )

        album.total_tracks = len(ordered_songs) if ordered_songs else None

    db.commit()

    # Ricarica con join per avere artists/songs aggiornati
    album = _get_album_or_404(album_id, db)

    return album


# ---------- DELETE ALBUM ----------

@router.delete(
    "/{album_id}",
    status_code=status.HTTP_200_OK,
)
def delete_album(
    album_id: str,
    db: Session = Depends(get_db),
    auth_details: dict = Depends(auth_middleware),
):
    """
    Cancella un album.

    Le join AlbumArtist / AlbumSong vengono eliminate grazie a
    ondelete="CASCADE" + cascade="all, delete-orphan".
    """
    album = db.query(Album).filter(Album.id == album_id).first()
    if not album:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Album not found",
        )

    db.delete(album)
    db.commit()
    return {"message": "Album deleted successfully"}
