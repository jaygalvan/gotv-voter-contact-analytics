import pandas as pd

"""
GOTV Voter Contact Analytics
01 - Initial Data Inspection

Purpose:
Perform an initial inspection of the source dataset before
data profiling and cleaning.
"""

# Load the dataset
df = pd.read_csv("anonymized_data_with_fraud_instance.csv")

# Basic dataset information
print("\n--- DATASET SHAPE ---")
print(df.shape)

print("\n--- COLUMN NAMES ---")
print(df.columns.tolist())

print("\n--- DATA TYPES ---")
print(df.dtypes)

print("\n--- MISSING VALUES ---")
print(df.isnull().sum())

print("\n--- DUPLICATE ROWS ---")
print(df.duplicated().sum())

print("\n--- FIRST 5 ROWS ---")
print(df.head())
