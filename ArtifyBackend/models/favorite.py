import uuid

from sqlalchemy import TEXT, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base, TimestampMixin


class Favorite(TimestampMixin, Base):
    __tablename__ = "favorites"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid.uuid4()))

    song_id: Mapped[str] = mapped_column(
        TEXT,
        ForeignKey("songs.id", ondelete="CASCADE"),
        index=True,
    )
    user_id: Mapped[str] = mapped_column(
        TEXT,
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
    )

    __table_args__ = (
        UniqueConstraint("user_id", "song_id", name="uq_user_song_favorite"),
    )

    song: Mapped["Song"] = relationship(back_populates="favorites")
    user: Mapped["User"] = relationship(back_populates="favorites")