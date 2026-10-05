import pandas as pd

"""
GOTV Voter Contact Analytics
02 - Data Profiling

Purpose:
Profile important categorical and identifying fields to identify
patterns, distributions, and potential data-quality issues before
cleaning and loading the data into PostgreSQL.
"""

df = pd.read_csv("anonymized_data_with_fraud_instance.csv")

# Examine unique values in important categorical fields

print("\n--- GENDER VALUES ---")
print(df["Gender"].value_counts(dropna=False))

print("\n--- PARTY VALUES ---")
print(df["PartyDesc"].value_counts(dropna=False))

print("\n--- STATE VALUES ---")
print(df["ResState"].value_counts(dropna=False))

print("\n--- COUNTY VALUES ---")
print(df["ResCountyDesc"].value_counts(dropna=False))

print("\n--- POTENTIAL FRAUD ---")
print(df["Potential Fraud"].value_counts(dropna=False))

print("\n--- BIRTH YEAR VALUES ---")
print(df["BirthYear"].value_counts().head(20))

print("\n--- ZIP VALUES ---")
print(df["ResZip5"].value_counts().head(20))

print("\n--- UNIQUE VOTER IDS ---")
print(df["VoterID"].nunique())

print("\n--- TOTAL ROWS ---")
print(len(df))
