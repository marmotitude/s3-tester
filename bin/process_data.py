#!/usr/bin/env python3
import pandas as pd
from datetime import datetime
import re
import csv

# Defina os caminhos dos arquivos
input_file = './report/benchmark.csv'

# Passo 1: Ler o arquivo para determinar o número máximo de colunas
with open(input_file, 'r') as file:
    lines = file.readlines()

# Encontre o número máximo de colunas em qualquer linha
max_cols = max(len(re.split(r',\s*', line)) for line in lines)

# Passo 2: Preencher linhas curtas com vírgulas faltantes
with open(input_file, 'w', newline='') as file:
    writer = csv.writer(file)
    
    for line in lines:
        # Divide a linha em colunas
        columns = re.split(r',\s*', line.strip())
        
        # Adiciona colunas vazias se necessário
        if len(columns) < max_cols:
            columns.extend([''] * (max_cols - len(columns)))
        
        # Escreve a linha no novo CSV
        writer.writerow(columns)

# Passo 3: Carregar os dados do CSV e adicionar cabeçalhos
file_path = './report/benchmark.csv'
df = pd.read_csv(file_path, header=None)

# Adicionar os cabeçalhos corretos
headers = ["date", "region", "tool", "operation", "size", "times", "workers", "quantity"]
num_additional_cols = df.shape[1] - len(headers)
additional_headers = [f"value_{i+1}" for i in range(num_additional_cols)]
all_headers = headers + additional_headers

df.columns = all_headers

# Função para processar os dados
def process_data(df):
    # Inicializa listas para armazenar os resultados
    result_list = []

    # Itera sobre cada grupo de (date, region, tool, size, quantity)
    for (date, region, tool, size, times, workers, quantity), group in df.groupby(['date', 'region', 'tool', 'size', 'times', 'workers', 'quantity']):
        
        # Inicializa dicionários para armazenar os valores de cada operação
        operations = {'upload': [], 'download': [], 'update': [], 'delete': []}

        # Itera sobre cada linha do grupo
        for _, row in group.iterrows():
            operation = row['operation'].lower()
            values = row[8:].dropna().tolist()

            # Armazena os valores da operação correspondente
            if operation in operations:
                operations[operation].extend(values)

        # Cria as linhas de resultado para cada operação
        for op in ['upload', 'download', 'update', 'delete']:
            values = list(map(float, operations[op]))
            if values:  # Processa apenas se houver valores
                result_dict = {
                    'date': date,
                    'region': region,
                    'tool': tool,
                    'size': int(size), 
                    'times': int(times),
                    'workers': int(workers),
                    'quantity': int(quantity),
                    'operation': op,
                    'sum': sum(values),
                    #'avg': pd.Series(values).mean(),
                    'avg': pd.Series(values).median(),
                    'min': pd.Series(values).min(),
                    'max': pd.Series(values).max()
                }
                # Adiciona o resultado ao result_list
                result_list.append(result_dict)

    # Cria um DataFrame com os resultados
    result_df = pd.DataFrame(result_list)
    
    return result_df

# Processa os dados
processed_df = process_data(df)

# Salva o DataFrame processado em um arquivo CSV
output_file = f'report/{datetime.today().strftime("%Y-%m-%d.%H")}h-processed_data.csv'
processed_df.to_csv(output_file, index=False)
