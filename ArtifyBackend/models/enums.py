import enum


class AlbumArtistRole(str, enum.Enum):
    PRIMARY = "primary"
    FEATURED = "featured"
    GUEST = "guest"


class SongArtistRole(str, enum.Enum):
    PRIMARY = "primary"
    FEATURED = "featured"
    PRODUCER = "producer"
    MIXER = "mixer"
    WRITER = "writer"


class UserRole(str, enum.Enum):
    ADMIN = "admin"
    ARTIST = "artist"
    USER = "user"