from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from database import get_db
from middleware.auth_middleware import auth_middleware, require_role
from models.enums import SongArtistRole, UserRole   # FIX: da enums.py
from models.user import User
from models.songArtist import SongArtist
from models.song import Song
from models.artist import Artist
from schemas.songArtist_schema import SongArtistCreate, SongArtistOut, SongArtistUpdate

router = APIRouter(tags=["song-artists"])


# ------------------------------------------------------------------ #
#  Helper privati                                                     #
# ------------------------------------------------------------------ #

def _get_link_or_404(link_id: str, db: Session) -> SongArtist:
    link = (
        db.query(SongArtist)
        .options(joinedload(SongArtist.song), joinedload(SongArtist.artist))
        .filter(SongArtist.id == link_id)
        .first()
    )
    if not link:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Song–Artist link not found",
        )
    return link


def _ensure_song_and_artist_exist(
    db: Session, song_id: str, artist_id: str
) -> tuple[Song, Artist]:
    song = db.query(Song).filter(Song.id == song_id).first()
    if not song:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Song ID does not exist",
        )
    artist = db.query(Artist).filter(Artist.id == artist_id).first()
    if not artist:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Artist ID does not exist",
        )
    return song, artist


# ------------------------------------------------------------------ #
#  Creazione link                                                     #
# ------------------------------------------------------------------ #

@router.post("/", status_code=status.HTTP_201_CREATED, response_model=SongArtistOut)
def create_song_artist(
    payload: SongArtistCreate,
    db: Session = Depends(get_db),
    # FIX: solo ARTIST e ADMIN possono creare link song–artist.
    # Il vecchio codice usava auth_middleware generico: qualsiasi utente autenticato
    # poteva aggiungere artisti a qualsiasi canzone.
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    song, artist = _ensure_song_and_artist_exist(db, payload.song_id, payload.artist_id)

    # FIX: id non passato — generato dal default del model.
    # FIX: payload.role ha già SongArtistRole.PRIMARY come default nello schema,
    # il fallback `or SongArtistRole.PRIMARY` era quindi dead code ed è rimosso.
    link = SongArtist(song=song, artist=artist, role=payload.role)
    db.add(link)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This song–artist–role combination already exists",
        )

    db.refresh(link)
    return link


# ------------------------------------------------------------------ #
#  Lettura singolo link                                               #
# ------------------------------------------------------------------ #

@router.get("/{link_id}", response_model=SongArtistOut)
def get_song_artist(
    link_id: str,
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
):
    return _get_link_or_404(link_id, db)


# ------------------------------------------------------------------ #
#  Lista link                                                         #
# ------------------------------------------------------------------ #

@router.get("/", response_model=List[SongArtistOut])
def list_song_artists(
    db: Session = Depends(get_db),
    _=Depends(auth_middleware),
    song_id: Optional[str] = None,
    artist_id: Optional[str] = None,
    limit: int = 20,        # FIX: paginazione aggiunta.
    offset: int = 0,
):
    query = db.query(SongArtist).options(
        joinedload(SongArtist.song),
        joinedload(SongArtist.artist),
    )
    if song_id:
        query = query.filter(SongArtist.song_id == song_id)
    if artist_id:
        query = query.filter(SongArtist.artist_id == artist_id)

    total = query.count()
    links = query.offset(offset).limit(limit).all()
    return links


# ------------------------------------------------------------------ #
#  Aggiornamento ruolo                                               #
# ------------------------------------------------------------------ #

@router.patch("/{link_id}", response_model=SongArtistOut)
def update_song_artist(
    link_id: str,
    payload: SongArtistUpdate,
    db: Session = Depends(get_db),
    # FIX: solo ARTIST e ADMIN possono modificare i link.
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    link = _get_link_or_404(link_id, db)

    # FIX: rimosso `if payload.role is not None` — in SongArtistUpdate
    # role è obbligatorio (non Optional), quindi non può mai essere None.
    link.role = payload.role

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A link with this song, artist and role already exists",
        )

    db.refresh(link)
    return link


# ------------------------------------------------------------------ #
#  Eliminazione link                                                  #
# ------------------------------------------------------------------ #

@router.delete("/{link_id}", status_code=status.HTTP_200_OK)
def delete_song_artist(
    link_id: str,
    db: Session = Depends(get_db),
    # FIX: solo ARTIST e ADMIN possono eliminare i link.
    current_user: User = Depends(require_role([UserRole.ARTIST, UserRole.ADMIN])),
):
    link = db.query(SongArtist).filter(SongArtist.id == link_id).first()
    if not link:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Song–Artist link not found",
        )
    db.delete(link)
    db.commit()
    return {"message": "Song–Artist link deleted successfully"}