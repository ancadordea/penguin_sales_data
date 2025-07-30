"""Reads in a .xlsx file and converts each sheet to an individual .csv"""
import pandas as pd
import os

# Globals
this_file = os.path.abspath(__file__)
script_dir = os.path.dirname(this_file)
parent_dir = os.path.dirname(script_dir)

input_excel = os.path.join(script_dir, 'raw_sales_data.xlsx')
output_folder = "2.processed_csv_data"
full_output_dir = os.path.join(parent_dir, output_folder)

os.makedirs(full_output_dir, exist_ok=True)

xls = pd.ExcelFile(input_excel)

for sheet_name in xls.sheet_names:
  df = pd.read_excel(xls, sheet_name = sheet_name)

  safe_name ="".join([c if c.isalnum() or c in ('','-','') else "" for c in sheet_name])
  csv_path = os.path.join(full_output_dir, f"{safe_name}.csv")


  df.to_csv(csv_path, index = False)
  print(f"Saved:{csv_path}")