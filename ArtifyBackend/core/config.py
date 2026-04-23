from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

# Path assoluto verso la root del progetto (ArtifyBackend/)
# __file__ = ArtifyBackend/core/config.py
# .parent   = ArtifyBackend/core/
# .parent   = ArtifyBackend/          ← qui sta il .env
BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Artify API"
    ENV: str = "development"

    # Database
    DATABASE_URL: str

    # JWT
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_DAYS: int = 7

    # Bcrypt
    BCRYPT_ROUNDS: int = 12

    # Cloudinary
    CLOUDINARY_CLOUD_NAME: str
    CLOUDINARY_API_KEY: str
    CLOUDINARY_API_SECRET: str

    model_config = SettingsConfigDict(
        # Path assoluto: non dipende da dove viene avviato fastapi run.
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
    )


settings = Settings()