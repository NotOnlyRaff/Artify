from sqlalchemy import TEXT, Column, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from models.base import Base


class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(TEXT, primary_key=True)

    song_id = Column(
        TEXT,
        ForeignKey("songs.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id = Column(
        TEXT,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    __table_args__ = (
        UniqueConstraint("user_id", "song_id", name="uq_user_song_favorite"),
    )

    song = relationship("Song", back_populates="favorites")
    user = relationship("User", back_populates="favorites")
