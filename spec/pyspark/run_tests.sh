#!/bin/bash

# Executa o script PySpark
spark-submit pyspark_boto3_crud.py

# Verifica o resultado do script PySpark
if [ $? -eq 0 ]; then
    echo "Script PySpark executado com sucesso"
else
    echo "Falha ao executar o script PySpark"
    exit 1
fi
