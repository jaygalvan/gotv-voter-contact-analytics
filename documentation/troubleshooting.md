# GOTV SQL & Reporting Troubleshooting

## Purpose

This document records significant technical issues encountered during
the project and the steps used to diagnose and resolve them.

The goal is to demonstrate SQL troubleshooting, data-quality analysis,
and problem resolution.

---

# 1. Duplicate Primary-Key Error

## Problem

An attempt to load staging voter records into `gotv.voters` produced:

```text
ERROR: duplicate key value violates unique constraint "voters_pkey"
Key (voter_id)=(Voter-ID-3226) already exists.
SQL state: 23505
```
## Investigation

The production table was designed with voter_id as the PRIMARY KEY,
enforcing the business rule:

One VoterID = one production voter record.

A SQL analysis of the staging table found:

```text
Total staging rows:        4,765
Unique VoterIDs:           4,338
Excess duplicate rows:       427
Duplicated VoterID groups:   170
```
Further investigation showed that the duplicate records were not
always exact copies.

For example, Voter-ID-3226 appeared four times and contained
differences in:

```text
DriverLicCard
FirstName
LastName
ResStreetAddress
Potential Fraud
```
## Root Cause

The staging table contained multiple records with the same VoterID,
while the production table required voter_id to be unique.

Loading all staging rows directly into the production table therefore
violated the PRIMARY KEY constraint.

## Solution
The original staging data was preserved.

A SQL ROW_NUMBER() transformation was used to rank records within
each VoterID.

The process:

Partitioned records by VoterID.
Prioritized records with Potential Fraud = 0.
Used deterministic voter attributes as tie-breakers.
Selected only records where ROW_NUMBER() = 1.

## Validation

The production table was checked for duplicate primary keys.

Result:

```text
Production voter rows:       4,338
Production duplicate IDs:        0
```

# 2. Duplicate VoterID Investigation

## Problem

The staging dataset contained many repeated VoterIDs.

A simple DISTINCT operation was not sufficient because duplicate
records were not always identical.

For example, Voter-ID-3226 appeared four times and contained
differences in voter attributes including:

```text
DriverLicCard
FirstName
LastName
ResStreetAddress
Potential Fraud
```

## Investigation
SQL aggregation was used to identify duplicated VoterIDs and compare
the records within each duplicate group.

The analysis showed that most duplicate groups contained:

One record with Potential Fraud = 0
One or more records with Potential Fraud = 1

Three duplicate groups contained more than one
Potential Fraud = 0 record:

```text
Voter-ID-350
Voter-ID-3771
Voter-ID-971
```

These records were treated as exceptions because the source did not
provide a reliable record-version field identifying which conflicting
record was objectively correct.

## Solution

SQL ROW_NUMBER() logic was used to create a deterministic,
one-row-per-VoterID production result.

The transformation prioritized the non-flagged record and then used
deterministic voter attributes as tie-breakers when multiple candidate
records remained.

The original staging table was preserved for audit purposes.

## Validation
The deduplicated result produced:

```text
Staging rows:               4,765
Unique VoterIDs:            4,338
Production voter rows:      4,338
Production duplicate IDs:       0
```
