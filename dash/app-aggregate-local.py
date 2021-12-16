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


app = dash.Dash(
    __name__, 
    external_stylesheets=[dbc.themes.BOOTSTRAP]
)

# assume you have a "long-form" data frame
# see https://plotly.com/python/px-arguments/ for more options
df = load_penguins()

app.layout = html.Div(
    className='container-fluid',
    children=[
        dcc.Store(id='inp'),
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
                                    dbc.Button('Upload CSV File'),
                                    id='upload-inp'
                                ),      
                                html.P(
                                    html.I('No file loaded, using penguins as default', id='upload-status'),
                                )
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
                            id='table',
                            columns=[{'name': i, 'id': i} for i in df.columns],
                            data=df.to_dict('records'),
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
def update_name(name):
    return name

#@app.callback(Output('inp', 'data'),
#              Input('upload-inp', 'content'))


if __name__ == '__main__':
    app.run_server(debug=True)
