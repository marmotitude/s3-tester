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

# Executa os testes Pytest
pytest test_pyspark_boto3_crud.py

# Verifica o resultado dos testes Pytest
if [ $? -eq 0 ]; then
    echo "Testes Pytest executados com sucesso"
else
    echo "Falha nos testes Pytest"
    exit 1
fi
