#!/bin/bash

# Verificar se os perfis foram fornecidos como argumentos
if [ "$#" -eq 0 ]; then
    echo "Uso: $0 <perfil1> <perfil2> ... <perfilN>"
    exit 1
fi

# Iterar por cada perfil fornecido
for PROFILE in "$@"; do
    echo "Executando para o perfil: $PROFILE"
    
    # Listar todos os buckets com data de criação
    BUCKETS=$(aws s3api list-buckets --profile "$PROFILE" --query "Buckets[].[Name, CreationDate]" --output json)
    
    # Filtrar os buckets com prefixo 'test-' e criados há mais de 24 horas
    OLD_BUCKETS=$(echo "$BUCKETS" | jq -c '
        .[] 
        | select(.[0] | startswith("test-")) 
        | select((now - (.[1] | gsub("\\+00:00$"; "Z") | fromdate)) > 86400) 
        | .[0]
    ' | tr -d '"')
    
    # Verificar se há buckets antigos com prefixo 'test-'
    if [ -z "$OLD_BUCKETS" ]; then
        echo "Nenhum bucket com prefixo 'test-' e mais de 24 horas encontrado para o perfil: $PROFILE"
        continue
    fi
    
    # Loop para deletar cada bucket
    for BUCKET in $OLD_BUCKETS; do
        echo "Processando bucket: $BUCKET no perfil: $PROFILE"
        
        # Deletar a bucket policy
        aws s3api delete-bucket-policy --bucket "$BUCKET" --profile "$PROFILE"

        # Esvaziar o bucket
        aws s3 rm s3://"$BUCKET" --recursive --profile "$PROFILE"
        
        # Deletar o bucket
        aws s3api delete-bucket --bucket "$BUCKET" --profile "$PROFILE"
        
        echo "Bucket $BUCKET deletado no perfil: $PROFILE"
    done
done
