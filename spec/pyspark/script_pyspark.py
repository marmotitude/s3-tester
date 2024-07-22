import boto3
from pyspark.sql import SparkSession
from pyspark.sql import Row
from datetime import datetime, date
import os
import pytest

#os.environ['JAVA_HOME'] = '/usr/lib/jvm/java-17-openjdk-amd64'

session = boto3.Session(profile_name='default')
credentials = session.get_credentials().get_frozen_credentials()

s3_endpoint_url = 'https://br-se1.magaluobjects.com'

def get_spark_session():
    return SparkSession.builder.appName("Demo") \
        .config("spark.jars.packages", "org.apache.hadoop:hadoop-aws:3.3.1,com.amazonaws:aws-java-sdk-pom:1.12.365") \
        .config("spark.hadoop.fs.s3a.access.key", credentials.access_key) \
        .config("spark.hadoop.fs.s3a.secret.key", credentials.secret_key) \
        .config("spark.hadoop.fs.s3a.endpoint", s3_endpoint_url) \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider") \
        .getOrCreate()

@pytest.fixture(scope="session")
def spark():
    spark = get_spark_session()
    spark.sparkContext.setLogLevel("DEBUG")  
    spark.stop()

def test_write_and_read_from_s3(spark):
    # Criar um DataFrame
    df = spark.createDataFrame([
        Row(a=1, b=2.0, c='string1', d=date(2000, 1, 1), e=datetime(2000, 1, 1, 12, 0)),
        Row(a=2, b=3.0, c='string2', d=date(2000, 2, 1), e=datetime(2000, 1, 2, 12, 0)),
        Row(a=4, b=5.0, c='string3', d=date(2000, 3, 1), e=datetime(2000, 1, 3, 12, 0)),
        Row(a=1, b=2.0, c='string1', d=date(2000, 1, 1), e=datetime(2000, 1, 1, 12, 0)),
        Row(a=2, b=3.0, c='string2', d=date(2000, 2, 1), e=datetime(2000, 1, 2, 12, 0)),
        Row(a=4, b=5.0, c='string3', d=date(2000, 3, 1), e=datetime(2000, 1, 3, 12, 0))
    ])

    try:
        df.write.parquet("s3a://hadoop/teste-parquet", mode="overwrite")
        print("Dados escritos com sucesso.")
    except Exception as e:
        print(f"Erro ao escrever dados: {str(e)}")
        assert False, f"Erro ao escrever dados: {str(e)}"

    bucket_name = 'hadoop'
    prefix = 'teste-parquet/'

    s3 = session.resource('s3', endpoint_url=s3_endpoint_url)
    bucket = s3.Bucket(bucket_name)

    objects = list(bucket.objects.filter(Prefix=prefix))
    assert len(objects) > 0, "Nenhum objeto encontrado no bucket."

    print("Objetos no bucket:")
    for obj in objects:
        print(obj.key)

    try:
        read_df = spark.read.parquet("s3a://hadoop/teste-parquet")
        read_df.show()
        assert read_df.count() == df.count(), "A contagem de registros não corresponde."
        assert read_df.columns == df.columns, "As colunas não correspondem."
    except Exception as e:
        print(f"Erro ao ler dados: {str(e)}")
        assert False, f"Erro ao ler dados: {str(e)}"

if __name__ == "__main__":
    pytest.main([__file__])
