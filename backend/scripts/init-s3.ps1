# scripts/init-s3.ps1

Write-Host "Initializing LocalStack S3..." -ForegroundColor Cyan

# 1. Tenta via Docker Exec (Mais robusto no Windows)
Write-Host "Trying to create bucket via docker exec..."
docker exec docker-localstack-1 awslocal s3 mb s3://cadife-travel-diary

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Bucket created/verified via docker exec." -ForegroundColor Green
} else {
    Write-Host "Docker exec failed or container not ready. Trying fallback via Python..." -ForegroundColor Yellow

    # 2. Fallback via Python/Boto3
    $pythonScript = @'
import boto3
from botocore.config import Config

bucket_name = "cadife-travel-diary"
endpoint = "http://127.0.0.1:4566"

s3 = boto3.client(
    's3',
    endpoint_url=endpoint,
    aws_access_key_id='test',
    aws_secret_access_key='test',
    region_name='us-east-1'
)

try:
    s3.create_bucket(Bucket=bucket_name)
    print(f'SUCCESS: Bucket {bucket_name} created via Python.')
except Exception as e:
    if 'BucketAlreadyOwnedByYou' in str(e) or 'BucketAlreadyExists' in str(e):
        print(f'SKIP: Bucket {bucket_name} already exists.')
    else:
        print(f'ERROR: {e}')
        exit(1)
'@

    if (Test-Path "..\.venv\Scripts\python.exe") {
        $pythonScript | ..\.venv\Scripts\python.exe -
    } else {
        $pythonScript | python -
    }
}

Write-Host "Initialization finished." -ForegroundColor Green
