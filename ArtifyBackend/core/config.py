import os
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

# carica le variabili dal file .env
load_dotenv()


class Settings(BaseSettings):
    """
    Configurazione centrale dell'applicazione.
    Tutte le variabili di ambiente vengono lette da qui.
    """

    # =========================
    # APP
    # =========================
    APP_NAME: str = "Artify API"
    ENV: str = os.getenv("ENV", "development")

    # =========================
    # DATABASE
    # =========================
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL"
    )

    # =========================
    # JWT AUTH
    # =========================
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY")
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = int(os.getenv("JWT_EXPIRE_MINUTES", 60 * 24))

    # =========================
    # PASSWORD HASH
    # =========================
    BCRYPT_ROUNDS: int = 12

    # =========================
    # STORAGE (future)
    # =========================
    STORAGE_PROVIDER: str = os.getenv("STORAGE_PROVIDER", "local")
    STORAGE_BUCKET: str = os.getenv("STORAGE_BUCKET", "artify")
    
    # =========================
    # CLOUDINARY 
    # =========================
    CLOUDINARY_CLOUD_NAME: str
    CLOUDINARY_API_KEY: str
    CLOUDINARY_API_SECRET: str

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
print(f"DEBUG: Cloud Name caricato -> {getattr(settings, 'CLOUDINARY_CLOUD_NAME', 'NON TROVATO')}")
