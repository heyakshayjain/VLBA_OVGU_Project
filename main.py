from google.cloud import bigquery
from google.oauth2 import service_account
from flask import Flask, render_template, request, jsonify
import pandas as pd
import random

# Create the Flask application object
app = Flask(__name__)
app.debug = False

credentials = service_account.Credentials.from_service_account_file('proj-iv-maintenance-service-be58bdb07222.json')
client = bigquery.Client(credentials=credentials)

@app.route('/')
def home():
    return render_template('home.html')

@app.route('/dashboard', methods=['GET', 'POST'])
def dashboard():
    
    selected_task = request.args.get('task')
    selected_quantity = request.args.get('quantity', default=1, type=int)
    selectedRows = request.args.get('rows', default=1, type=int)
    selectedClient = request.args.get('client')


    # Define your BigQuery query with the random task
    query = f"""
            SELECT
  d.ClientID,
  d.ClientName,
  '{selected_task}' AS TaskType,
  i.UniqueTeams,
  p.predicted_label*{selected_quantity} AS TimeTakenInHours,
  d.Distance__km_ AS DistanceInKms,
  d.Time__hrs_ AS TimeTakenToReachInHours
FROM (
  SELECT DISTINCT UniqueTeams
  FROM MwwMsSAPData.Inputdata_train2
) AS i
LEFT JOIN ML.PREDICT(MODEL `MwwMsSAPData.TimePredictionModelwithoutteamid`, (
  SELECT
    '{selected_task}' AS TaskType,
    UniqueTeams
  FROM (
    SELECT DISTINCT UniqueTeams
    FROM MwwMsSAPData.Inputdata_train2
  )
)) AS p
ON i.UniqueTeams = p.UniqueTeams
CROSS JOIN proj-iv-maintenance-service.SampleTestingDataset.DistancesAndTimeServicePointToClient AS d
WHERE d.ClientID = '{selectedClient}'
ORDER BY p.predicted_label ASC;
"""

    # Execute the query and get the results as a Pandas DataFrame
    dataframe = client.query(query).to_dataframe()

    # Convert the DataFrame to a dictionary
    table_data = dataframe.to_dict(orient='records')

    return render_template('dashboard.html', table=table_data)