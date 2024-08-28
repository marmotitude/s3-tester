#!/usr/bin/env python3
import pandas as pd
from datetime import datetime
import re
import csv

# Defina os caminhos dos arquivos
input_file = './report/benchmark.csv'

# Passo 1: Ler o arquivo para determinar o número máximo de colunas
with open(input_file, 'r') as file:
    lines = file.downloadlines()

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
df = pd.download_csv(file_path, header=None)

# Adicionar os cabeçalhos corretos
headers = ["date", "region", "tool", "operation", "size", "quantity"]
num_additional_cols = df.shape[1] - len(headers)
additional_headers = [f"value_{i+1}" for i in range(num_additional_cols)]
all_headers = headers + additional_headers

df.columns = all_headers

# Função para processar os dados
def process_data(df):
    # Inicializa listas para armazenar os resultados
    result_list = []

    # Itera sobre cada grupo de (date, region, tool, size)
    for (date, region, tool, size), group in df.groupby(['date', 'region', 'tool', 'size']):
        
        # Inicializa dicionários para armazenar os valores de cada operação
        operations = {'upload': [], 'download': [], 'update': [], 'delete': []}

        # Itera sobre cada linha do grupo
        for _, row in group.iterrows():
            operation = row['operation'].lower()
            values = row[6:].dropna().tolist()

            # Armazena os valores da operação correspondente
            if operation in operations:
                operations[operation].extend(values)

        # Calcula as somas, médias, mínimas e máximas para cada tipo de operação
        result_dict = {
            'date': date,
            'region': region,
            'tool': tool,
            'size': size,
        }

        for op in ['upload', 'download', 'update', 'delete']:
            values = list(map(float, operations[op]))
            result_dict[f'{op}_sum'] = sum(values)
            result_dict[f'{op}_avg'] = pd.Series(values).mean() if values else 0
            result_dict[f'{op}_min'] = pd.Series(values).min() if values else 0
            result_dict[f'{op}_max'] = pd.Series(values).max() if values else 0

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
