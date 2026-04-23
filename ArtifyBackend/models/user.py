import uuid
from typing import List, Optional

from sqlalchemy import TEXT, VARCHAR, ForeignKey, LargeBinary
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.base import Base, TimestampMixin
from models.enums import UserRole


class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(TEXT, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(VARCHAR(100))
    email: Mapped[str] = mapped_column(VARCHAR(100), unique=True, index=True)
    password: Mapped[bytes] = mapped_column(LargeBinary)  # bcrypt hash, 60 bytes
    role: Mapped[UserRole] = mapped_column(
        SAEnum(
            UserRole,
            name="user_role",
            values_callable=lambda x: [e.value for e in x],
            validate_strings=True,
        ),
        default=UserRole.USER,
    )
    image_url: Mapped[Optional[str]] = mapped_column(TEXT)

    artist_id: Mapped[Optional[str]] = mapped_column(
        TEXT,
        ForeignKey("artists.id", ondelete="SET NULL"),
        unique=True,
        index=True,
    )

    artist_profile: Mapped[Optional["Artist"]] = relationship(
        back_populates="user",
        uselist=False,
        foreign_keys=[artist_id],
    )

    favorites: Mapped[List["Favorite"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )

    # favorite_songs rimosso: usa GET /me/favorites con query dedicata nel service

    def __repr__(self) -> str:
        return f"<User id={self.id!r} email={self.email!r} role={self.role.value!r}>"