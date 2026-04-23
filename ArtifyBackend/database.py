from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker

from core.config import settings

def _normalize_database_url(raw_url: str) -> str:
    database_url = raw_url.strip()

    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql://", 1)

    url = make_url(database_url)
    host = (url.host or "").lower()

    if (
        (host.endswith("supabase.co") or host.endswith("supabase.com"))
        and "sslmode" not in url.query
    ):
        url = url.update_query_dict({"sslmode": "require"})

    return url.render_as_string(hide_password=False)


engine = create_engine(
    _normalize_database_url(settings.DATABASE_URL),
    pool_pre_ping=True,
    pool_recycle=300,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
