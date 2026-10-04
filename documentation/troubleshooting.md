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
