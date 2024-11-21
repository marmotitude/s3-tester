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
    # echo "Arquivo de lista de buckets não encontrado: $bucket_list_file"
    exit 1
fi

# Converte a lista de profiles para um array
IFS=',' read -r -a profiles <<< "$profile_list"

# Certifique-se de que o arquivo de lista de buckets existe
if [[ ! -f "$bucket_list_file" ]]; then
    # echo "Arquivo de lista de buckets não encontrado: $bucket_list_file"
    exit 1
fi

# Função para excluir objetos, políticas e buckets
excluir_bucket() {
    local bucket="$1"
    local profile="$2"
    
    echo "Processando o bucket: $bucket com o profile $profile"

    # Remover a política do bucket (se houver)
    echo "Removendo a política do bucket: $bucket"
    aws s3api delete-bucket-policy --bucket "$bucket" --profile "$profile" > /dev/null 2>&1
    sleep 3
    # Excluir todos os objetos e versões no bucket
    versions=$(aws s3api list-object-versions --bucket "$bucket" --query "Versions[].[VersionId, Key]" --output text --profile "$profile")
    
    # Excluir versões dos objetos (se existirem)
    while IFS= read -r line; do
        version_id=$(echo "$line" | awk '{print $1}')
        key=$(echo "$line" | awk '{print $2}')
        aws s3api delete-object --bucket "$bucket" --key "$key" --version-id "$version_id" --profile "$profile" > /dev/null
    done <<< "$versions"

    # Excluir os objetos não versionados (se houver)
    objects=$(aws s3api list-objects --bucket "$bucket" --query "Contents[].[Key]" --output text --profile "$profile")

    while IFS= read -r object; do
        aws s3api delete-object --bucket "$bucket" --key "$object" --profile "$profile" > /dev/null
    done <<< "$objects"

    # Remover o bucket vazio
    aws s3 rb s3://"$bucket" --force --profile "$profile" > /dev/null

    echo "Todos os objetos, versões e a política excluídos do bucket: $bucket"
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
    for profile in "${profiles[@]}"; do
        if [[ "$bucket" == *"$profile"* ]]; then
            excluir_bucket "$bucket" "$profile"
            processed=true
            break
        fi
    done

    if [[ "$processed" == false ]]; then
        echo "Nenhum profile encontrado para o bucket: $bucket" > /dev/null
    fi

done < "$bucket_list_file"
