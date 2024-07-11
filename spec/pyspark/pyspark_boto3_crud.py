import os
from pyspark.sql import SparkSession
import boto3

def create_spark_session():
    spark = SparkSession.builder \
        .appName("S3 CRUD Operations") \
        .getOrCreate()
    return spark

def create_bucket(s3_client, bucket_name):
    s3_client.create_bucket(Bucket=bucket_name)
    print(f"Bucket {bucket_name} criado.")

def read_bucket(s3_client, bucket_name):
    response = s3_client.list_objects_v2(Bucket=bucket_name)
    if 'Contents' in response:
        for obj in response['Contents']:
            print(f"Objeto encontrado: {obj['Key']}")
    else:
        print("Bucket vazio ou não encontrado.")

def upload_object(s3_client, bucket_name, file_name, object_name):
    s3_client.upload_file(file_name, bucket_name, object_name)
    print(f"Arquivo {file_name} enviado como {object_name}.")

def delete_bucket(s3_client, bucket_name):
    response = s3_client.list_objects_v2(Bucket=bucket_name)
    if 'Contents' in response:
        for obj in response['Contents']:
            s3_client.delete_object(Bucket=bucket_name, Key=obj['Key'])
            print(f"Objeto {obj['Key']} deletado.")
    s3_client.delete_bucket(Bucket=bucket_name)
    print(f"Bucket {bucket_name} deletado.")

if __name__ == "__main__":
    spark = create_spark_session()

    s3_client = boto3.client(
        's3',
        endpoint_url='https://br-se1.magaluobjects.com',
        aws_access_key_id=os.getenv('246889f3-2141-4451-98a7-7a41125fd1ba'),
        aws_secret_access_key=os.getenv('3ce28097-ba79-4b84-add7-ae3348d09edf'),
        verify=False  # Disable SSL verification
    )

    bucket_name = "anderso9n894"
    
    create_bucket(s3_client, bucket_name)
    upload_object(s3_client, bucket_name, "local_file.txt", "uploaded_file.txt")
    read_bucket(s3_client, bucket_name)
    delete_bucket(s3_client, bucket_name)
