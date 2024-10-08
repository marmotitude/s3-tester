from prometheus_client import start_http_server, Gauge
import pandas as pd
import time
import glob
import os

# Defina uma métrica Prometheus com o método como um dos rótulos
operation_gauge = Gauge('objs_benchmark', 'Dados de benchmark', ['operation', 'region', 'tool', 'size', 'times', 'workers', 'quantity'])

def read_csv_and_update_metrics():
    # Encontre todos os arquivos que terminam com 'processed_data.csv' na pasta
    files = glob.glob('/home/ubuntu/s3-tester/report/*processed_data.csv')

    # Verifica se há arquivos encontrados
    if not files:
        print("Nenhum arquivo encontrado.")
        return

    # Ordenar os arquivos por data de modificação e pegar o último
    latest_file = max(files, key=os.path.getmtime)

    # Limpe as métricas existentes
    operation_gauge.clear()

    # Agora você pode ler o último arquivo
    with open(latest_file, 'r') as file:
        print(f'Processing file: {file}')
        df = pd.read_csv(file)

        # Atualize as métricas baseadas no CSV
        for _, row in df.iterrows():
            labels = {
                'operation': row['operation'],
                'region': row['region'],
                'tool': row['tool'],
                'size': str(row['size']),
                'times': str(row['times']),
                'workers': str(row['workers']),
                'quantity': str(row['quantity'])
            }
            operation_gauge.labels(**labels).set(row['avg'])

if __name__ == '__main__':
    # Inicie o servidor HTTP na porta 8000
    start_http_server(8000)
    while True:
        read_csv_and_update_metrics()
        time.sleep(600)  # Atualize a cada 600 segundos (10 minutos)
