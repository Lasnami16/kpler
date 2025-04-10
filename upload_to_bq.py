import pandas as pd
from google.oauth2 import service_account
import pandas_gbq

def pandas_append_to_bq(dataframe, project_id, dataset_id, table_id, credentials_path,if_exists,schema):
    credentials = service_account.Credentials.from_service_account_file(credentials_path)
    # Append DataFrame to BigQuery table
    pandas_gbq.to_gbq(dataframe, f"{dataset_id}.{table_id}", project_id=project_id, if_exists=if_exists, credentials=credentials,table_schema=schema)