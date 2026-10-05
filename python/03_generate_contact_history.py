import pandas as pd
import numpy as np

"""
GOTV Voter Contact Analytics
03 - Generate Contact History

Purpose:
Generate a reproducible synthetic contact-history dataset for
demonstrating SQL joins, contact-status analysis, reporting,
and dashboard development.

The contact records, contact dates, outcomes, methods, and
volunteer IDs are generated synthetically for this project.
They do not represent verified real-world contact events.

A random seed is used so the generated results are reproducible.
"""

# Set a seed so the results are reproducible
np.random.seed(42)

# Load the voter dataset
voters = pd.read_csv("anonymized_data_with_fraud_instance.csv")

# Get unique voter IDs
voter_ids = voters["VoterID"].drop_duplicates()

# Number of contact records we want to generate
num_contacts = 6000

# Randomly select voters for contact attempts
contact_voter_ids = np.random.choice(
    voter_ids,
    size=num_contacts,
    replace=True
)

# Generate contact dates
contact_dates = pd.to_datetime(
    np.random.choice(
        pd.date_range("2026-08-01", "2026-09-05"),
        size=num_contacts
    )
)

# Generate contact methods
contact_methods = np.random.choice(
    ["Phone", "Canvass", "Text"],
    size=num_contacts,
    p=[0.40, 0.40, 0.20]
)

# Generate synthetic contact outcomes
contact_results = np.random.choice(
    [
        "Contacted",
        "No Answer",
        "Wrong Number",
        "Refused",
        "Moved",
        "No Response"
    ],
    size=num_contacts,
    p=[0.30, 0.25, 0.08, 0.07, 0.05, 0.25]
)

# Generate synthetic volunteer IDs
volunteer_ids = np.random.choice(
    ["VOL-001", "VOL-002", "VOL-003", "VOL-004", "VOL-005",
     "VOL-006", "VOL-007", "VOL-008", "VOL-009", "VOL-010"],
    size=num_contacts
)

# Create the contact history dataframe
contact_history = pd.DataFrame({
    "VoterID": contact_voter_ids,
    "ContactDate": contact_dates,
    "ContactMethod": contact_methods,
    "ContactResult": contact_results,
    "VolunteerID": volunteer_ids
})

# Sort by date
contact_history = contact_history.sort_values("ContactDate")

# Save the synthetic contact history
contact_history.to_csv("contact_history.csv", index=False)

# Display a summary
print("\n--- CONTACT HISTORY CREATED ---")
print("Number of contact records:", len(contact_history))
print("Unique voters contacted:", contact_history["VoterID"].nunique())

print("\n--- CONTACT METHODS ---")
print(contact_history["ContactMethod"].value_counts())

print("\n--- CONTACT RESULTS ---")
print(contact_history["ContactResult"].value_counts())

print("\n--- FIRST 10 RECORDS ---")
print(contact_history.head(10))

print("\nSaved as: contact_history.csv")
