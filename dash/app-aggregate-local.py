# Run this app with `python app-aggregate-local.py` and
# visit http://127.0.0.1:8050/ in your web browser.

import dash
from dash import dash_table
from dash import html
import pandas as pd
from palmerpenguins import load_penguins

app = dash.Dash(__name__)

# assume you have a "long-form" data frame
# see https://plotly.com/python/px-arguments/ for more options
df = load_penguins()

app.layout = html.Div(children=[

    dash_table.DataTable(
        id='table',
        columns=[{"name": i, "id": i} for i in df.columns],
        data=df.to_dict('records'),
        page_size=10,
        sort_action='native'
    )

])

if __name__ == '__main__':
    app.run_server(debug=True)
