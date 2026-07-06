#!/usr/bin/env python3
import pandas as pd
import os

files = [
    '/Users/parnian/Desktop/university/Term 6/DB2/SQL Project/Transportation-Data-Warehouse/DataSources/HR/2020-Employees.xls',
    '/Users/parnian/Desktop/university/Term 6/DB2/SQL Project/Transportation-Data-Warehouse/DataSources/HR/2024 Transit Agency Employees_250806.xlsx',
    '/Users/parnian/Desktop/university/Term 6/DB2/SQL Project/Transportation-Data-Warehouse/DataSources/HR/WA_Fn-UseC_-HR-Employee-Attrition.xls',
    '/Users/parnian/Desktop/university/Term 6/DB2/SQL Project/Transportation-Data-Warehouse/DataSources/HR/synthetic_ntd_job_openings_2014_2024.xlsx'
]

for file_path in files:
    if not os.path.exists(file_path):
        print(f"\nFile not found: {os.path.basename(file_path)}")
        continue

    print(f"\n{'='*80}")
    print(f"FILE: {os.path.basename(file_path)}")
    print(f"{'='*80}")

    try:
        xls = pd.ExcelFile(file_path)
        sheet_names = xls.sheet_names

        print(f"\nSheet Names ({len(sheet_names)}):")
        for i, sheet in enumerate(sheet_names, 1):
            print(f"   {i}. {sheet}")

        first_sheet = sheet_names[0]
        df = pd.read_excel(file_path, sheet_name=first_sheet)

        print(f"\nMain Sheet: '{first_sheet}'")
        print(f"   Rows: {len(df)}, Columns: {len(df.columns)}")

        print(f"\nColumn Headers & Data Types:")
        for i, col in enumerate(df.columns, 1):
            dtype = str(df[col].dtype)
            non_null = df[col].notna().sum()
            print(f"   {i:2d}. {col:<40} | Type: {dtype:<15} | Non-null: {non_null}")

        print(f"\nSample Data (first 2 rows):")
        pd.set_option('display.max_columns', None)
        pd.set_option('display.width', None)
        print(df.head(2).to_string())

    except Exception as e:
        print(f"Error: {type(e).__name__}: {e}")
