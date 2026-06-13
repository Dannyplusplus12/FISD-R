import os


class Settings:
    # Database — defaults to local SQLite if not set (Railway injects the real URL)
    DATABASE_URL: str = os.environ.get("DATABASE_URL", "")

    # CORS — comma-separated list of allowed origins, or "*" for all
    CORS_ALLOWED_ORIGINS: str = os.environ.get("CORS_ALLOWED_ORIGINS", "*")

    # Telegram backup (optional — delivery photos are sent here)
    TELEGRAM_BOT_TOKEN: str = (
        os.environ.get("TELEGRAM_DB_BOT_TOKEN") or
        os.environ.get("TELEGRAM_BOT_TOKEN", "")
    )
    TELEGRAM_CHAT_ID: str = (
        os.environ.get("TELEGRAM_DB_CHAT_ID") or
        os.environ.get("TELEGRAM_CHAT_ID", "")
    )

    # Where delivery photos are stored on disk
    DELIVERY_UPLOAD_DIR: str = os.environ.get("DELIVERY_UPLOAD_DIR", "")

    # Max size per delivery photo upload (MB)
    MAX_DELIVERY_PHOTO_MB: int = int(os.environ.get("MAX_DELIVERY_PHOTO_MB", "8"))


settings = Settings()
