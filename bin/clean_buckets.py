#!/usr/bin/env python3
import boto3
import concurrent.futures
from datetime import datetime, timezone
from botocore.exceptions import ClientError

# Função para remover a política de um bucket
def remove_policy(bucket, profile):
    # Criar a sessão com o perfil
    session = boto3.Session(profile_name=profile)
    client = session.client('s3')
    
    print(f"Removendo a política do bucket: {bucket}")
    try:
        client.delete_bucket_policy(Bucket=bucket)
    except Exception as e:
        print(f"Erro ao remover política do bucket {bucket}: {e}")

# Função para excluir objetos e versões de um bucket
def delete_objects_and_versions(bucket, profile):
    # Criar a sessão com o perfil
    session = boto3.Session(profile_name=profile)
    client = session.client('s3')
    
    print(f"Deletando objetos e versões para o bucket: {bucket} no perfil: {profile}")

    # Excluir objetos não versionados
    try:
        response = client.list_object_versions(Bucket=bucket)
        for version in response.get('Versions', []):
            version_id = version['VersionId']
            key = version['Key']
            client.delete_object(Bucket=bucket, Key=key, VersionId=version_id)
    except Exception as e:
        print(f"Erro ao excluir objetos ou versões no bucket {bucket}: {e}")

def delete_all_objects_and_versions(bucket, client):
    try:
        # Excluir objetos não versionados
        response = client.list_objects_v2(Bucket=bucket)
        if 'Contents' in response:
            for obj in response['Contents']:
                print(f"Deletando objeto: {obj['Key']}")
                client.delete_object(Bucket=bucket, Key=obj['Key'])
        
        # Excluir versões dos objetos (se o bucket tiver versionamento ativado)
        response = client.list_object_versions(Bucket=bucket)
        if 'Versions' in response:
            for version in response['Versions']:
                print(f"Deletando versão do objeto: {version['Key']} versão: {version['VersionId']}")
                client.delete_object(Bucket=bucket, Key=version['Key'], VersionId=version['VersionId'])
        if 'DeleteMarkers' in response:
            for marker in response['DeleteMarkers']:
                print(f"Deletando marcador de exclusão do objeto: {marker['Key']} versão: {marker['VersionId']}")
                client.delete_object(Bucket=bucket, Key=marker['Key'], VersionId=marker['VersionId'])

    except ClientError as e:
        print(f"Erro ao excluir objetos ou versões no bucket {bucket}: {e}")

# Função para excluir um bucket vazio com força
def delete_bucket(bucket, profile):
    # Criar a sessão com o perfil
    session = boto3.Session(profile_name=profile)
    client = session.client('s3')
    
    print(f"Deletando o bucket: {bucket}")
    
    try:
        # Primeiro, exclua todos os objetos e versões no bucket
        delete_all_objects_and_versions(bucket, client)
        
        # Depois de excluir tudo, exclua o bucket
        client.delete_bucket(Bucket=bucket)
        print(f"Bucket {bucket} excluído com sucesso.")
    
    except Exception as e:
        print(f"Erro ao excluir o bucket {bucket}: {e}")

# Função principal para processar cada perfil
def process_profile(profile):
    print(f"Executando para o perfil: {profile}")

    # Criar a sessão com o perfil
    session = boto3.Session(profile_name=profile)
    client = session.client('s3')

    # Listar todos os buckets
    response = client.list_buckets()
    
    # Filtrar os buckets com prefixo 'test-' e criados há mais de 24 horas
    old_buckets = []
    for bucket in response['Buckets']:
        name = bucket['Name']
        creation_date = bucket['CreationDate']
        if name.startswith('test-') and (datetime.now(timezone.utc) - creation_date).total_seconds() > 86400:
            old_buckets.append(name)
    
    if not old_buckets:
        print(f"Nenhum bucket com prefixo 'test-' e mais de 24 horas encontrado para o perfil: {profile}")
        return

    # Paralelizar a remoção da política de buckets
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [executor.submit(remove_policy, bucket, profile) for bucket in old_buckets]
        concurrent.futures.wait(futures)

    # Paralelizar a exclusão de objetos e versões dos buckets
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [executor.submit(delete_objects_and_versions, bucket, profile) for bucket in old_buckets]
        concurrent.futures.wait(futures)

    # Paralelizar a exclusão dos buckets vazios
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [executor.submit(delete_bucket, bucket, profile) for bucket in old_buckets]
        concurrent.futures.wait(futures)

# Função principal que processa todos os perfis passados
def main(profiles):
    for profile in profiles:
        process_profile(profile)

if __name__ == "__main__":
    # Verificar se os perfis foram fornecidos como argumentos
    import sys
    if len(sys.argv) < 2:
        print("Uso: python script.py <perfil1> <perfil2> ... <perfilN>")
        sys.exit(1)
    
    profiles = sys.argv[1:]
    main(profiles)
