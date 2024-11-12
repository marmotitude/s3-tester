#!/bin/bash

# Verifique se o nome do profile foi fornecido como argumento
if [[ -z "$1" ]]; then
    echo "Por favor, forneça o profile da AWS como argumento."
    echo "Uso: $0 <profile-list>"
    exit 1
fi

# Armazenar o profile recebido como argumento
profile_list="$1"

# Caminho para o arquivo .txt contendo a lista de buckets
bucket_list_file="report/buckets_to_delete.txt"

# Certifique-se de que o arquivo de lista existe
if [[ ! -f "$bucket_list_file" ]]; then
    echo "Arquivo de lista de buckets não encontrado: $bucket_list_file"
    exit 1
fi

# Converte a lista de profiles para um array
IFS=',' read -r -a profiles <<< "$profile_list"

# Certifique-se de que o arquivo de lista de buckets existe
if [[ ! -f "$bucket_list_file" ]]; then
    echo "Arquivo de lista de buckets não encontrado: $bucket_list_file"
    exit 1
fi

# Função para excluir objetos e buckets
excluir_bucket() {
    local bucket="$1"
    local profile="$2"
    
    echo "Processando o bucket: $bucket com o profile $profile"

    rclone purge $profile:$bucket
    
    # Excluir todas as versões dos objetos no bucket
    versions=$(aws s3api list-object-versions --bucket "$bucket" --query "Versions[].[VersionId, Key]" --output text --profile "$profile")

    while IFS= read -r line; do
        # Extrair a versão e a chave do objeto
        version_id=$(echo "$line" | awk '{print $1}')
        key=$(echo "$line" | awk '{print $2}')

        # Excluir a versão do objeto
        aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$version_id" --profile "$profile"
        echo "  Excluindo versão: $version_id de $key"
    done <<< "$versions"

    # Excluir os objetos não versionados (se houver)
    objects=$(aws s3api list-objects --bucket "$bucket" --query "Contents[].[Key]" --output text --profile "$profile")

    while IFS= read -r object; do
        aws s3api delete-object --bucket "$bucket" --key "$object" --profile "$profile"
        echo "  Excluindo objeto: $object"
    done <<< "$objects"

    # Remover o bucket vazio
    echo "Removendo o bucket: $bucket"
    aws s3 rb s3://"$bucket" --force --profile "$profile"

    echo "Todos os objetos e versões excluídos do bucket: $bucket"
}

# Leia o arquivo de lista de buckets linha por linha (cada linha é um bucket)
while IFS= read -r bucket; do
    # Verifique se a linha não está vazia
    if [[ -z "$bucket" ]]; then
        continue
    fi
    
    # Flag para determinar se o bucket foi processado
    processed=false

    # Percorre os profiles e verifica se o nome do profile está no nome do bucket
    echo $profiles
    for profile in "${profiles[@]}"; do
        if [[ "$bucket" == *"$profile"* ]]; then
            echo $profile
            excluir_bucket "$bucket" "$profile"
            processed=true
            break
        fi
    done

    if [[ "$processed" == false ]]; then
        echo "Nenhum profile encontrado para o bucket: $bucket"
    fi

done < "$bucket_list_file"
