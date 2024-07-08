import boto3
import pytest
from moto import mock_s3

@pytest.fixture
def s3_client():
    with mock_s3():
        conn = boto3.client('s3', region_name='us-east-1')
        yield conn

def test_create_bucket(s3_client):
    from pyspark_boto3_crud import create_bucket
    bucket_name = "test-bucket"
    create_bucket(s3_client, bucket_name)
    response = s3_client.list_buckets()
    buckets = [bucket['Name'] for bucket in response['Buckets']]
    assert bucket_name in buckets

def test_upload_and_read_object(s3_client):
    from pyspark_boto3_crud import create_bucket, upload_object, read_bucket
    bucket_name = "test-bucket"
    create_bucket(s3_client, bucket_name)
    
    # Cria um arquivo local para upload
    with open("local_file.txt", "w") as f:
        f.write("Conteúdo de teste.")
    
    upload_object(s3_client, bucket_name, "local_file.txt", "uploaded_file.txt")
    
    response = s3_client.list_objects_v2(Bucket=bucket_name)
    keys = [obj['Key'] for obj in response['Contents']]
    assert "uploaded_file.txt" in keys

def test_delete_bucket(s3_client):
    from pyspark_boto3_crud import create_bucket, delete_bucket
    bucket_name = "test-bucket"
    create_bucket(s3_client, bucket_name)
    delete_bucket(s3_client, bucket_name)
    response = s3_client.list_buckets()
    buckets = [bucket['Name'] for bucket in response['Buckets']]
    assert bucket_name not in buckets
