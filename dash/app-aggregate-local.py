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

# assume you have a "long-form" data frame
# see https://plotly.com/python/px-arguments/ for more options
penguins = load_penguins()

app.layout = html.Div(
    className='container-fluid',
    children=[
        dcc.Store(id='inp', data=penguins.to_dict('records')),
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
                                dbc.Button('Download CSV File', className='btn btn-secondary', id='download-btn'),
                                dcc.Download(id='download-inp')
                            ])
                        ]),
                        dbc.Card([
                            dbc.CardHeader('Aggregation'),
                            dbc.CardBody()
                        ]),
                        dbc.Card([
                            dbc.CardHeader('Aggregated data'),
                            dbc.CardBody()
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
                        html.H3('Aggregated data')
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
    Input('download-btn', 'n_clicks'),
    State('inp', 'data'),
    prevent_initial_call=True,
)
def func(n_clicks, data):
    df = pd.DataFrame.from_dict(data)
    return dcc.send_data_frame(df.to_csv, 'dowload-inp.csv', index=False)

@app.callback(Output('table-inp', 'columns'),
              Output('table-inp', 'data'),
              Input('inp', 'data'))
def update_table_inp(data):

    # data is a dict serialization of the DataFrame
    cols = [{'name': i, 'id': i} for i in data[0].keys()]
    return cols, data


if __name__ == '__main__':
    app.run_server(debug=True)
