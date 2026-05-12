#!/bin/bash
# scripts/init-s3.sh

BUCKET_NAME="cadife-travel-diary"
ENDPOINT="http://localhost:4566"

echo "Initializing LocalStack S3..."

if command -v awslocal >/dev/null 2>&1; then
    awslocal s3 mb "s3://$BUCKET_NAME"
elif command -v aws >/dev/null 2>&1; then
    aws --endpoint-url=$ENDPOINT s3 mb "s3://$BUCKET_NAME"
else
    echo "Error: Neither 'awslocal' nor 'aws' CLI found."
    echo "Please install one of them or run: pip install awscli-local"
    exit 1
fi

echo "Bucket '$BUCKET_NAME' created/verified."
