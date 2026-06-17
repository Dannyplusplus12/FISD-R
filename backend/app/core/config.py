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

    # S3-compatible object storage (Railway Bucket)
    S3_BUCKET: str = os.environ.get("S3_BUCKET", "")
    S3_ACCESS_KEY_ID: str = os.environ.get("S3_ACCESS_KEY_ID", "")
    S3_SECRET_ACCESS_KEY: str = os.environ.get("S3_SECRET_ACCESS_KEY", "")
    S3_ENDPOINT: str = os.environ.get("S3_ENDPOINT", "")
    S3_REGION: str = os.environ.get("S3_REGION", "auto")

    # Max size per photo upload (MB)
    MAX_DELIVERY_PHOTO_MB: int = int(os.environ.get("MAX_DELIVERY_PHOTO_MB", "8"))


settings = Settings()
