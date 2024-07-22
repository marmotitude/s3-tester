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

def get_spark_session(path_style_access=True):
    builder = SparkSession.builder.appName("Demo") \
        .config("spark.jars.packages", "org.apache.hadoop:hadoop-aws:3.3.1,com.amazonaws:aws-java-sdk-pom:1.12.365") \
        .config("spark.hadoop.fs.s3a.access.key", credentials.access_key) \
        .config("spark.hadoop.fs.s3a.secret.key", credentials.secret_key) \
        .config("spark.hadoop.fs.s3a.endpoint", s3_endpoint_url) \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")

    if path_style_access:
        builder = builder.config("spark.hadoop.fs.s3a.path.style.access", "true")
    else:
        builder = builder.config("spark.hadoop.fs.s3a.path.style.access", "false")

    return builder.getOrCreate()

@pytest.fixture(scope="session")
def spark_path_style():
    spark = get_spark_session(path_style_access=True)
    spark.sparkContext.setLogLevel("DEBUG") 
    yield spark
    spark.stop()

@pytest.fixture(scope="session")
def spark_vhost_style():
    spark = get_spark_session(path_style_access=False)
    spark.sparkContext.setLogLevel("DEBUG")  
    spark.stop()

def test_write_and_read_from_s3_path_style(spark_path_style):
    _test_write_and_read_from_s3(spark_path_style, "s3a://hadoop/teste-parquet-path")

def test_write_and_read_from_s3_vhost_style(spark_vhost_style):
    _test_write_and_read_from_s3(spark_vhost_style, "s3a://hadoop/teste-parquet-vhost")

def _test_write_and_read_from_s3(spark, s3_path):
    # Criar um DataFrame
    df = spark.createDataFrame([
        Row(a=1, b=2.0, c='string1', d=date(2000, 1, 1), e=datetime(2000, 1, 1, 12, 0)),
        Row(a=2, b=3.0, c='string2', d=date(2000, 2, 1), e=datetime(2000, 1, 2, 12, 0)),
        Row(a=4, b=5.0, c='string3', d=date(2000, 3, 1), e=datetime(2000, 1, 3, 12, 0)),
        Row(a=1, b=2.0, c='string1', d=date(2000, 1, 1), e=datetime(2000, 1, 1, 12, 0)),
        Row(a=2, b=3.0, c='string2', d=date(2000, 2, 1), e=datetime(2000, 1, 2, 12, 0)),
        Row(a=4, b=5.0, c='string3', d=date(2000, 3, 1), e=datetime(2000, 1, 3, 12, 0))
    ])

    # Escrever o DataFrame no S3
    try:
        df.write.parquet(s3_path, mode="overwrite")
        print("Dados escritos com sucesso.")
    except Exception as e:
        print(f"Erro ao escrever dados: {str(e)}")
        assert False, f"Erro ao escrever dados: {str(e)}"

    # Verificar se os dados foram escritos no S3
    bucket_name = 'hadoop'
    prefix = s3_path.split('s3a://hadoop/')[1]

    s3 = session.resource('s3', endpoint_url=s3_endpoint_url)
    bucket = s3.Bucket(bucket_name)

    objects = list(bucket.objects.filter(Prefix=prefix))
    assert len(objects) > 0, "Nenhum objeto encontrado no bucket."

    print("Objetos no bucket:")
    for obj in objects:
        print(obj.key)

    # Ler os dados de volta do S3 e verificar o conteúdo
    try:
        read_df = spark.read.parquet(s3_path)
        read_df.show()
        assert read_df.count() == df.count(), "A contagem de registros não corresponde."
        assert read_df.columns == df.columns, "As colunas não correspondem."
    except Exception as e:
        print(f"Erro ao ler dados: {str(e)}")
        assert False, f"Erro ao ler dados: {str(e)}"

# Execute os testes
if __name__ == "__main__":
    pytest.main([__file__])
