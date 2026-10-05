import pandas as pd

"""
GOTV Voter Contact Analytics
04 - Clean and Validate Voter Data

Purpose:
Perform initial voter-data cleaning and validation before loading
the dataset into PostgreSQL.

Python removes exact duplicate records and validates key fields.
Duplicate VoterIDs that contain conflicting records are investigated
and resolved later during the SQL deduplication stage.

The original voter-level source data is not included in the
public GitHub repository.
"""

# Load the original voter dataset
df = pd.read_csv("anonymized_data_with_fraud_instance.csv")

print("--- ORIGINAL DATA ---")
print("Rows:", len(df))
print("Unique VoterIDs:", df["VoterID"].nunique())


# --------------------------------------------------
# 1. Remove exact duplicate records
# --------------------------------------------------

exact_duplicates = df.duplicated().sum()

print("\nExact duplicate rows found:", exact_duplicates)

df_clean = df.drop_duplicates().copy()


# --------------------------------------------------
# 2. Check for duplicate VoterIDs
# --------------------------------------------------
#
# These are NOT automatically removed here.
# Remaining duplicate VoterIDs are investigated and
# resolved later with SQL.

duplicate_voter_ids = df_clean["VoterID"].duplicated().sum()

print("Duplicate VoterID records remaining:", duplicate_voter_ids)


# --------------------------------------------------
# 3. Validate categorical fields
# --------------------------------------------------

valid_gender = [
    "Gender-1",
    "Gender-2",
    "Gender-3",
    "Gender-4"
]

valid_party = [
    "Party-1",
    "Party-2",
    "Party-3",
    "Party-4",
    "Party-5"
]

invalid_gender = ~df_clean["Gender"].isin(valid_gender)
invalid_party = ~df_clean["PartyDesc"].isin(valid_party)

print("\nInvalid Gender values:", invalid_gender.sum())
print("Invalid Party values:", invalid_party.sum())


# --------------------------------------------------
# 4. Validate synthetic identifier formats
# --------------------------------------------------

birthyear_valid = df_clean["BirthYear"].str.match(
    r"^B-Year-\d+$",
    na=False
)

zip_valid = df_clean["ResZip5"].str.match(
    r"^Zip-\d+$",
    na=False
)

print("\nInvalid BirthYear formats:", (~birthyear_valid).sum())
print("Invalid ZIP formats:", (~zip_valid).sum())


# --------------------------------------------------
# 5. Validate Potential Fraud values
# --------------------------------------------------

valid_fraud = df_clean["Potential Fraud"].isin([0, 1])

print("Invalid Potential Fraud values:", (~valid_fraud).sum())


# --------------------------------------------------
# 6. Save cleaned dataset
# --------------------------------------------------

df_clean.to_csv("voters_clean.csv", index=False)

print("\n--- CLEANING COMPLETE ---")
print("Rows after cleaning:", len(df_clean))
print("Unique VoterIDs:", df_clean["VoterID"].nunique())
print("Saved as: voters_clean.csv")
