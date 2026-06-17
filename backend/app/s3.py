import boto3
from botocore.config import Config

from app.core.config import settings

_CONTENT_TYPE_MAP = {
    "jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png",
    "webp": "image/webp", "heic": "image/heic", "bmp": "image/bmp",
}
_PRESIGNED_EXPIRES = 86400  # 24 giờ


def _client():
    return boto3.client(
        "s3",
        endpoint_url=settings.S3_ENDPOINT,
        aws_access_key_id=settings.S3_ACCESS_KEY_ID,
        aws_secret_access_key=settings.S3_SECRET_ACCESS_KEY,
        region_name=settings.S3_REGION,
        config=Config(
            signature_version="s3v4",
            s3={"addressing_style": "virtual"},
        ),
    )


def upload_bytes(data: bytes, key: str, ext: str = "jpg") -> str:
    content_type = _CONTENT_TYPE_MAP.get(ext.lstrip(".").lower(), "image/jpeg")
    _client().put_object(
        Bucket=settings.S3_BUCKET,
        Key=key,
        Body=data,
        ContentType=content_type,
    )
    return key


def presigned_url(key: str) -> str:
    if not key or not settings.S3_BUCKET:
        return ""
    try:
        return _client().generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.S3_BUCKET, "Key": key},
            ExpiresIn=_PRESIGNED_EXPIRES,
        )
    except Exception:
        return ""


def download_bytes(key: str) -> bytes:
    resp = _client().get_object(Bucket=settings.S3_BUCKET, Key=key)
    return resp["Body"].read()
