# Run this app with `python app-aggregate-local.py` and
# visit http://127.0.0.1:8050/ in your web browser.

import dash
from dash import dash_table
from dash import html
from dash import dcc
from dash.dependencies import Input, Output, State
import pandas as pd
from palmerpenguins import load_penguins
import dash_bootstrap_components as dbc
import base64
import io


app = dash.Dash(
    __name__, 
    external_stylesheets=[dbc.themes.BOOTSTRAP]
)

agg_function_choices = ['mean', 'min', 'max']

# assume you have a "long-form" data frame
# see https://plotly.com/python/px-arguments/ for more options
penguins = load_penguins()

app.layout = html.Div(
    className='container-fluid',
    children=[
        dcc.Store(id='inp', data=penguins.to_dict('records')),
        dcc.Store(id='agg', data=[]),
        html.H2('Aggregator'),
        html.Div(
            className='row',
            children =[
                html.Div(
                    className='col-sm-4',
                    children=[
                        dbc.Card([
                            dbc.CardHeader('Input data'),
                            dbc.CardBody([
                                dcc.Upload(
                                    dbc.Button('Upload CSV File', className='btn btn-secondary'),
                                    id='upload-inp'
                                ),      
                                html.P(
                                    html.I('No file loaded, using penguins as default', id='upload-status')
                                ),
                                dbc.Button('Download CSV File', className='btn btn-secondary', id='download-btn-inp'),
                                dcc.Download(id='download-inp')
                            ])
                        ]),
                        dbc.Card([
                            dbc.CardHeader('Aggregation'),
                            dbc.CardBody([
                                dbc.Label('Grouping columns'),
                                dcc.Dropdown(id='cols-group', multi=True),
                                dbc.Label('Aggregation columns'),
                                dcc.Dropdown(id='cols-agg', multi=True),
                                dbc.Label('Aggregation function'),
                                dbc.Select(
                                    id='func-agg',
                                    options=[{'label': i, 'value': i} for i in agg_function_choices],
                                    value=agg_function_choices[0]
                                ),
                                html.Hr(),
                                dbc.Button('Submit', className='btn btn-secondary', id='button-agg')
                            ])
                        ]),
                        dbc.Card([
                            dbc.CardHeader('Aggregated data'),
                            dbc.CardBody([
                                dbc.Button('Download CSV File', className='btn btn-secondary', id='download-btn-agg'),
                                dcc.Download(id='download-agg')
                            ])
                        ])
                    ]
                ),
                html.Div(
                    className='col-sm-8',
                    children=[
                        html.H3('Input data'),
                        dash_table.DataTable(
                            id='table-inp',
                            page_size=10,
                            sort_action='native'
                        ),
                        html.Hr(),
                        html.H3('Aggregated data'),
                        dash_table.DataTable(
                            id='table-agg',
                            page_size=10,
                            sort_action='native'
                        ),
                    ]
                )
            ]
        )
    ]
) 

@app.callback(Output('upload-status', 'children'),
              Input('upload-inp', 'filename'),
              prevent_initial_call=True)
def update_input_file_name(name):
    return name

@app.callback(Output('inp', 'data'),
              Input('upload-inp', 'contents'),
              prevent_initial_call=True)
def parse_input_file_contents(contents):

    try:
        # decode content to DataFrame
        content_type, content_string = contents.split(',')
        decoded = base64.b64decode(content_string)

        df = pd.read_csv(
            io.StringIO(decoded.decode('utf-8'))  
        )
    except Exception as e:
        print(e)
        df = pd.DataFrame()

    # serilize DataFrame to storage
    return df.to_dict('records')

@app.callback(
    Output('download-inp', 'data'),
    Input('download-btn-inp', 'n_clicks'),
    State('inp', 'data'),
    prevent_initial_call=True,
)
def download_inp(n_clicks, data):
    df = pd.DataFrame.from_dict(data)
    return dcc.send_data_frame(df.to_csv, 'download-inp.csv', index=False)

@app.callback(Output('table-inp', 'columns'),
              Output('table-inp', 'data'),
              Input('inp', 'data'))
def update_table_inp(data):
    # data is a dict serialization of the DataFrame
    cols = [{'name': i, 'id': i} for i in data[0].keys()]
    return cols, data

@app.callback(Output('cols-group', 'options'),
              Input('inp', 'data'))
def update_cols_group(data):
    df = pd.DataFrame.from_dict(data)
    col_names = df.select_dtypes(include='object').columns.to_list()
    return [{'label': i, 'value': i} for i in col_names]

@app.callback(Output('cols-agg', 'options'),
              Input('inp', 'data'))
def update_cols_agg(data):
    df = pd.DataFrame.from_dict(data)
    col_names = df.select_dtypes(include='number').columns.to_list()
    return [{'label': i, 'value': i} for i in col_names]

@app.callback(Output('agg', 'data'),
              Input('button-agg', 'n_clicks'),
              State('inp', 'data'),
              State('cols-group', 'value'),
              State('cols-agg', 'value'),
              State('func-agg', 'value'),
              prevent_initial_call=True)
def aggregate(n_clicks, data, cols_group, cols_agg, func_agg):
    # create DataFrame
    df = pd.DataFrame.from_dict(data)

    if (not cols_group is None):
        df = df.groupby(cols_group)

    if (cols_agg is None or len(cols_agg) == 0):
        return []
    
    dict_agg = {}
    for col in cols_agg:
        dict_agg[col] = func_agg
    
    # aggregate DataFrame
    df = df.agg(dict_agg).reset_index()

    # serialize DataFrame
    return df.to_dict('records')

@app.callback(Output('table-agg', 'columns'),
              Output('table-agg', 'data'),
              Input('agg', 'data'))
def update_table_agg(data):
    # data is a dict serialization of the DataFrame
    cols = []
    if (len(data) > 0):
        cols = [{'name': i, 'id': i} for i in data[0].keys()]
    return cols, data

@app.callback(
    Output('download-agg', 'data'),
    Input('download-btn-agg', 'n_clicks'),
    State('agg', 'data'),
    prevent_initial_call=True,
)
def download_agg(n_clicks, data):
    df = pd.DataFrame.from_dict(data)
    return dcc.send_data_frame(df.to_csv, 'download-agg.csv', index=False)

if __name__ == '__main__':
    app.run_server(debug=True)
