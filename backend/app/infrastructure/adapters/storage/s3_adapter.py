import logging
from typing import Optional

import aioboto3
from botocore.exceptions import ClientError

from app.infrastructure.config.settings import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class S3StorageAdapter:
    """
    Adapter for S3 compatible object storage (MinIO/AWS S3).
    Handles file uploads and signed URL generation.
    Follows §1.3 of updated claude_local.md.
    """

    def __init__(self):
        self.session = aioboto3.Session()
        self.bucket_name = settings.S3_BUCKET_NAME
        self.endpoint_url = settings.S3_ENDPOINT_URL
        self.access_key = settings.S3_ACCESS_KEY
        self.secret_key = settings.S3_SECRET_KEY
        self.region = settings.S3_REGION

    def _get_client_args(self):
        """Prepares arguments for the aioboto3 client."""
        args = {
            "service_name": "s3",
            "region_name": self.region,
            "aws_access_key_id": self.access_key,
            "aws_secret_access_key": self.secret_key,
        }
        if self.endpoint_url:
            # Required for MinIO or local S3-compatible storage
            args["endpoint_url"] = self.endpoint_url
        return args

    async def upload_file(
        self, file_content: bytes, object_key: str, content_type: str
    ) -> bool:
        """
        Uploads file content to the configured S3 bucket.
        """
        try:
            async with self.session.client(**self._get_client_args()) as s3:
                await s3.put_object(
                    Bucket=self.bucket_name,
                    Key=object_key,
                    Body=file_content,
                    ContentType=content_type,
                )
                logger.info(
                    f"Successfully uploaded {object_key} to {self.bucket_name}"
                )
                return True
        except ClientError as e:
            logger.error(f"Error uploading file to S3: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error during S3 upload: {e}")
            return False

    async def generate_presigned_url(
        self, object_key: str, expires_in: int = 3600
    ) -> Optional[str]:
        """
        Generates a temporary signed URL for a private object.
        Default expiration is 1 hour (3600 seconds) as per requirements.
        """
        try:
            async with self.session.client(**self._get_client_args()) as s3:
                url = await s3.generate_presigned_url(
                    "get_object",
                    Params={"Bucket": self.bucket_name, "Key": object_key},
                    ExpiresIn=expires_in,
                )
                return url
        except ClientError as e:
            logger.error(f"Error generating presigned URL: {e}")
            return None

    async def delete_file(self, object_key: str) -> bool:
        """
        Deletes an object from the S3 bucket.
        """
        try:
            async with self.session.client(**self._get_client_args()) as s3:
                await s3.delete_object(Bucket=self.bucket_name, Key=object_key)
                logger.info(
                    f"Successfully deleted {object_key} from {self.bucket_name}"
                )
                return True
        except ClientError as e:
            logger.error(f"Error deleting file from S3: {e}")
            return False
