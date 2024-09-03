import pandas as pd
import plotly.express as px
import json

# Carregar os dados
csv_file = f'report/{datetime.today().strftime("%Y-%m-%d.%H")}h-processed_data.csv'
df = pd.read_csv(csv_file)

# Gerar os dropdowns únicos
regions = df['region'].unique().tolist()
operations = df['operation'].unique().tolist()
sizes = df['size'].unique().tolist()
quantities = df['quantity'].unique().tolist()

# Função para criar o gráfico com base nos filtros
def create_plot(region, operation, size, quantity):
    filtered_df = df[(df['region'] == region) & (df['operation'] == operation) &
                     (df['size'] == size) & (df['quantity'] == quantity)]

    fig = px.bar(filtered_df, x='tool', y=['avg', 'min', 'max'],
                 labels={'value': 'Tempo (ms)', 'tool': 'Ferramenta', 'variable': 'Métrica'},
                 title=f"DEsempenho: {operation.capitalize()} - {region.upper()} (Tamanho: {size} MB, Quantidade: {quantity})",
                 template='plotly_dark')
    fig.update_layout(
        title_font=dict(size=20, color='#F5F5F5', family="Arial"),
        font=dict(color='#F5F5F5'),
        plot_bgcolor='#2a2a2a',
        paper_bgcolor='#1e1e1e',
        xaxis=dict(gridcolor='#4f4f4f'),
        yaxis=dict(gridcolor='#4f4f4f'),
        barmode='group'
    )
    return fig

# Criar gráfico inicial
initial_region = regions[0]
initial_operation = operations[0]
initial_size = sizes[0]
initial_quantity = quantities[0]

fig = create_plot(initial_region, initial_operation, initial_size, initial_quantity)

# Gerar HTML autossuficiente com estilo Grafana e Bootstrap
html_content = f'''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatório de Desempenho S3</title>
    <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {{
            background-color: #1e1e1e;
            color: #F5F5F5;
            font-family: Arial, sans-serif;
        }}
        h1 {{
            text-align: center;
            margin-top: 20px;
            margin-bottom: 40px;
            color: #F5F5F5;
        }}
        .container {{
            width: 80%;
            margin: auto;
            text-align: center;
        }}
        label {{
            margin-right: 10px;
        }}
        select {{
            margin-right: 20px;
            padding: 5px;
            background-color: #333;
            color: #F5F5F5;
            border: 1px solid #4f4f4f;
        }}
        #plotly-div {{
            margin-top: 20px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Relatório de Desempenho de Ferramentas S3</h1>

        <div class="row justify-content-center">
            <div class="col-md-3">
                <label for="region">Região:</label>
                <select class="form-control" id="region" onchange="updatePlot()">
                    {''.join([f'<option value="{region}">{region.upper()}</option>' for region in regions])}
                </select>
            </div>
            <div class="col-md-3">
                <label for="operation">Operação:</label>
                <select class="form-control" id="operation" onchange="updatePlot()">
                    {''.join([f'<option value="{operation}">{operation.capitalize()}</option>' for operation in operations])}
                </select>
            </div>
            <div class="col-md-3">
                <label for="size">Tamanho do Arquivo (MB):</label>
                <select class="form-control" id="size" onchange="updatePlot()">
                    {''.join([f'<option value="{size}">{size}</option>' for size in sizes])}
                </select>
            </div>
            <div class="col-md-3">
                <label for="quantity">Quantidade:</label>
                <select class="form-control" id="quantity" onchange="updatePlot()">
                    {''.join([f'<option value="{quantity}">{quantity}</option>' for quantity in quantities])}
                </select>
            </div>
        </div>

        <div id="plotly-div"></div>
    </div>

    <script type="text/javascript">
        var data = {json.dumps(df.to_dict(orient='records'))};

        function createPlot(region, operation, size, quantity) {{
            var filteredData = data.filter(d => d.region == region && d.operation == operation && 
                                                d.size == size && d.quantity == quantity);
            var traces = [];

            ['avg', 'min', 'max'].forEach(function(metric) {{
                var trace = {{
                    x: [],
                    y: [],
                    type: 'bar',
                    name: metric,
                }};
                filteredData.forEach(function(d) {{
                    trace.x.push(d.tool);
                    trace.y.push(d[metric]);
                }});
                traces.push(trace);
            }});

            var layout = {{
                title: 'Desempenho: ' + operation.charAt(0).toUpperCase() + operation.slice(1) + 
                        ' - ' + region.toUpperCase() + ' (Tamanho: ' + size + ' MB, Quantidade: ' + quantity + ')',
                xaxis: {{ title: 'Ferramenta', gridcolor: '#4f4f4f' }},
                yaxis: {{ title: 'Tempo (ms)', gridcolor: '#4f4f4f' }},
                plot_bgcolor: '#2a2a2a',
                paper_bgcolor: '#1e1e1e',
                font: {{ color: '#F5F5F5' }},
                barmode: 'group'
            }};

            Plotly.newPlot('plotly-div', traces, layout);
        }}

        function updatePlot() {{
            var region = document.getElementById('region').value;
            var operation = document.getElementById('operation').value;
            var size = parseFloat(document.getElementById('size').value);
            var quantity = parseFloat(document.getElementById('quantity').value);
            createPlot(region, operation, size, quantity);
        }}

        document.addEventListener('DOMContentLoaded', function() {{
            createPlot('{initial_region}', '{initial_operation}', {initial_size}, {initial_quantity});
        }});
    </script>
</body>
</html>
'''

# Salvar o HTML no arquivo
html_file = f'report/{datetime.today().strftime("%Y-%m-%d.%H")}h-dashboard.html'
with open(html_file, 'w') as f:
    f.write(html_content)

print(f"Dashboard salvo como '{html_file}'")

