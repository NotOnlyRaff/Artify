from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from core.config import settings  # FIX: usa settings invece di os.getenv() diretto


# FIX: engine creato una sola volta usando settings.DATABASE_URL.
# Rimosso load_dotenv() + os.getenv() + RuntimeError — la validazione
# avviene già in pydantic_settings al momento dell'import di settings.
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
)

# FIX: SessionLocal e get_db definiti una sola volta — erano duplicati.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# initialize Connector object
# initialize Cloud SQL Python Connector
#connector = Connector()#

## create connection pool engine
#engine = sqlalchemy.create_engine(
#    "postgresql+pg8000://",
#    creator=lambda: connector.connect(
#        "artify420:europe-west2:artify-db", # Cloud SQL Instance Connection Name
#        "pg8000",
#        user="postgres",
#        password="Artify2025?",
#        db="artify",
#        ip_type="public"  # "private" for private IP

#    ),
#)#

# create SQLAlchemy ORM session
#SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

#def get_db():
##    db = SessionLocal()
#    try:
#        yield db
#    finally:
#        db.close()
