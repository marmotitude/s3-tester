import boto3
from pyspark.sql import SparkSession
from pyspark.sql import Row
from datetime import datetime, date
import os

# Configurar o JAVA_HOME
os.environ['JAVA_HOME'] = '/usr/lib/jvm/java-17-openjdk-amd64'
os.environ['SPARK_HOME'] = '/opt/spark/spark-3.5.1-bin-hadoop3'

# Configurar o boto3 para usar o perfil configurado no AWS CLI
session = boto3.Session(profile_name='default')

credentials = session.get_credentials().get_frozen_credentials()

s3_endpoint_url = 'https://br-se1.magaluobjects.com'

# Conectar ao Spark configurando o S3
spark = SparkSession.builder.appName("Demo") \
    .config('spark.jars.packages', 'org.apache.hadoop:hadoop-aws:3.3.1,com.amazonaws:aws-java-sdk-bundle:1.11.901') \
    .config('spark.hadoop.fs.s3a.access.key', credentials.access_key) \
    .config('spark.hadoop.fs.s3a.secret.key', credentials.secret_key) \
    .config('spark.hadoop.fs.s3a.endpoint', s3_endpoint_url) \
    .config('spark.hadoop.fs.s3a.impl', 'org.apache.hadoop.fs.s3a.S3AFileSystem') \
    .config('spark.hadoop.fs.s3a.path.style.access', 'true') \
    .enableHiveSupport() \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")

# Criar um DataFrame
df = spark.createDataFrame([
    Row(a=1, b=2.0, c='string1', d=date(2000, 1, 1), e=datetime(2000, 1, 1, 12, 0)),
    Row(a=2, b=3.0, c='string2', d=date(2000, 2, 1), e=datetime(2000, 1, 2, 12, 0)),
    Row(a=4, b=5.0, c='string3', d=date(2000, 3, 1), e=datetime(2000, 1, 3, 12, 0)),
    Row(a=1, b=2.0, c='string1', d=date(2000, 1, 1), e=datetime(2000, 1, 1, 12, 0)),
    Row(a=2, b=3.0, c='string2', d=date(2000, 2, 1), e=datetime(2000, 1, 2, 12, 0)),
    Row(a=4, b=5.0, c='string3', d=date(2000, 3, 1), e=datetime(2000, 1, 3, 12, 0))
])

# Escrever o DataFrame
try:
    df.write.parquet("s3a://hadoop/teste-parquet", mode="overwrite")
    print("Dados escritos com sucesso.")
except Exception as e:
    print(f"Erro ao escrever dados: {str(e)}")

# Verificar se os dados foram escritos no S3
bucket_name = 'hadoop'
prefix = 'teste-parquet/'

s3 = session.resource('s3', endpoint_url=s3_endpoint_url)
bucket = s3.Bucket(bucket_name)
print("Objetos no bucket:")
for obj in bucket.objects.filter(Prefix=prefix):
    print(obj.key)

spark.stop()
