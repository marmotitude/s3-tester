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

    # Remover a política de todos os buckets antes de continuar o processo de exclusão
    for BUCKET in $OLD_BUCKETS; do
        echo "Removendo a política do bucket: $BUCKET"
        aws s3api delete-bucket-policy --bucket "$BUCKET" --profile "$PROFILE" > /dev/null 2>&1
        sleep 3  # Aguardar um pouco para garantir que a política foi removida antes das próximas ações
    done
    
    # Loop para excluir as versões dos objetos e objetos não versionados
    for BUCKET in $OLD_BUCKETS; do
        echo "Processando bucket: $BUCKET no perfil: $PROFILE"

        # Excluir todas as versões dos objetos no bucket
        versions=$(aws s3api list-object-versions --bucket "$BUCKET" --query "Versions[].[VersionId, Key]" --output text --profile "$PROFILE")

        # Excluir versões dos objetos (se existirem)
        while IFS= read -r line; do
            version_id=$(echo "$line" | awk '{print $1}')
            key=$(echo "$line" | awk '{print $2}')
            aws s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$version_id" --profile "$PROFILE" > /dev/null
        done <<< "$versions"

        # Excluir os objetos não versionados (se houver)
        objects=$(aws s3api list-objects --bucket "$BUCKET" --query "Contents[].[Key]" --output text --profile "$PROFILE")
        while IFS= read -r object; do
            aws s3api delete-object --bucket "$BUCKET" --key "$object" --profile "$PROFILE" > /dev/null
        done <<< "$objects"
        
        echo "Todos os objetos, versões e a política excluídos do bucket: $BUCKET"
        sleep 3
    done
    
    # Agora que todos os objetos e versões foram excluídos, remover os buckets
    for BUCKET in $OLD_BUCKETS; do
        echo "Deletando o bucket vazio: $BUCKET"
        aws s3api delete-bucket --bucket "$BUCKET" --profile "$PROFILE"
        echo "Bucket $BUCKET deletado no perfil: $PROFILE"
    done
done
