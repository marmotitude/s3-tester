#!/usr/bin/env python3

import pandas as pd
from datetime import datetime

file_path = './report/benchmark.csv'
# Criar um DataFrame a partir dos dados
df = pd.read_csv(file_path)

fixed_headers = ["date", "region", "tool", "size"]

# Adiciona cabeçalhos genéricos para as colunas restantes
num_additional_cols = df.shape[1] - len(fixed_headers)
additional_headers = [f"col_{i+1}" for i in range(num_additional_cols)]

# Atualiza o DataFrame com os cabeçalhos
all_headers = fixed_headers + additional_headers
df.columns = all_headers


def process_data(df):
    # Inicializa listas para armazenar os resultados
    result_list = []
    
    # Itera sobre cada grupo de (date, region, tool, size)
    for (date, region, tool, size), group in df.groupby(['date', 'region', 'tool', 'size']):
        
        # Armazena valores temporários para cálculos
        create_values = []
        read_values = []
        update_values = []
        delete_values = []
        
        # Itera sobre cada linha do grupo
        for _, row in group.iterrows():
            for i in range(4, len(row) - 1, 2):  # Começa a partir do índice 4 (col_1)
                key = row.iloc[i]
                value = row.iloc[i + 1]
                
                
                if pd.notna(value) and pd.notna(key):
                    try:
                        value = float(value)
                    except ValueError:
                        continue  # Ignora se o valor não puder ser convertido para float
                    
                    key = str(key)  # Garante que key é uma string
                    
                    if 'create' in key:
                        create_values.append(value)
                    elif 'read' in key:
                        read_values.append(value)
                    elif 'update' in key:
                        update_values.append(value)
                    elif 'delete' in key:
                        delete_values.append(value)
        
        # Calcula as somas, médias, mínimas e máximas para cada tipo de operação
        create_sum = sum(create_values)
        create_avg = pd.Series(create_values).mean() if create_values else 0
        create_min = pd.Series(create_values).min() if create_values else 0
        create_max = pd.Series(create_values).max() if create_values else 0
        
        read_sum = sum(read_values)
        read_avg = pd.Series(read_values).mean() if read_values else 0
        read_min = pd.Series(read_values).min() if read_values else 0
        read_max = pd.Series(read_values).max() if read_values else 0
        
        update_sum = sum(update_values)
        update_avg = pd.Series(update_values).mean() if update_values else 0
        update_min = pd.Series(update_values).min() if update_values else 0
        update_max = pd.Series(update_values).max() if update_values else 0
        
        delete_sum = sum(delete_values)
        delete_avg = pd.Series(delete_values).mean() if delete_values else 0
        delete_min = pd.Series(delete_values).min() if delete_values else 0
        delete_max = pd.Series(delete_values).max() if delete_values else 0
        
        # Armazena os resultados na lista
        result_list.append({
            'date': date,
            'region': region,
            'tool': tool,
            'size': size,
            'create_sum': create_sum,
            'create_avg': create_avg,
            'create_min': create_min,
            'create_max': create_max,
            'read_sum': read_sum,
            'read_avg': read_avg,
            'read_min': read_min,
            'read_max': read_max,
            'update_sum': update_sum,
            'update_avg': update_avg,
            'update_min': update_min,
            'update_max': update_max,
            'delete_sum': delete_sum,
            'delete_avg': delete_avg,
            'delete_min': delete_min,
            'delete_max': delete_max
        })
    
    # Cria um DataFrame com os resultados
    result_df = pd.DataFrame(result_list)
    
    return result_df

# Processa os dados
processed_df = process_data(df)

# Salva o DataFrame processado em um arquivo CSV
processed_df.to_csv(f'report/{datetime.today().strftime("%Y-%m-%d.%H")}h-processed_data.csv', index=False)
