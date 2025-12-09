from sqlalchemy import TEXT, VARCHAR, Column, LargeBinary
from sqlalchemy.orm import relationship
from models.base import Base


class User(Base):
    __tablename__ = "users"

    # tipicamente un UUID string
    id = Column(TEXT, primary_key=True)

    name = Column(VARCHAR(100), nullable=False)

    # di solito email va unique + indicizzata
    email = Column(
        VARCHAR(100),
        nullable=False,
        unique=True,
        index=True,
    )

    # password già hashata/bcrypt, mai in chiaro
    password = Column(LargeBinary, nullable=False)

    # relazione 1 -> N con Favorite (tabella di join verso Song)
    favorites = relationship(
        "Favorite",
        back_populates="user",
        # opzionale: se metti ondelete="CASCADE" sulla FK in Favorite,
        # questo ti permette di eliminare a cascata le sue favorites
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<User id={self.id!r} email={self.email!r}>"
