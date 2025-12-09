from sqlalchemy import create_engine
import sqlalchemy
from sqlalchemy.orm import sessionmaker
from google.cloud.sql.connector import Connector

DATABASE_URL = 'postgresql://postgres:Password123@localhost:5432/Artify'


engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit = False, autoflush=False, bind=engine)

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
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
