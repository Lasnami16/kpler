import pandas as pd
from upload_to_bq import pandas_append_to_bq
import os
from dotenv import load_dotenv

load_dotenv()

PROJECT_ID = os.getenv("PROJECT_ID")
DATASET_ID = os.getenv("DATASET_ID")
TABLE_ID = os.getenv("TABLE_ID")

# Read the Excel file (Deals sheet)
df_deals = pd.read_excel('deals.xlsx', sheet_name='Deals')

#change  columns names
df_deals.columns = ['account_id','opportunity_id','stage','prod_type','close_date',
                    'renewal_date','team','service','commodity_family','delta_ARR_USD','ARR_USD']

#Convert to dateTime
df_deals['close_date'] = pd.to_datetime(df_deals['close_date'], errors='coerce')
df_deals['renewal_date'] = pd.to_datetime(df_deals['renewal_date'], errors='coerce')
#convert to date
df_deals['close_date'] = df_deals['close_date'].dt.date
df_deals['renewal_date'] = df_deals['renewal_date'].dt.date


#Upload to bigquery
schema = [ ]
pandas_append_to_bq(df_deals, PROJECT_ID, DATASET_ID, TABLE_ID, "credentials.json",'replace',schema)
