# GOTV Voter Contact Analytics

## Project Overview

This project demonstrates a data analytics workflow using
Python/Pandas, PostgreSQL, SQL, Google Sheets, and Data Studio.

The objective was to transform a source voter dataset into
a validated relational database and develop SQL reporting
for voter contact coverage and outreach activity.

## Technology

- Python / Pandas
- PostgreSQL
- SQL
- pgAdmin
- Google Sheets
- Google Data Studio

## Workflow

ERICA Dataset
→ Python/Pandas
→ PostgreSQL Staging
→ SQL QA & Deduplication
→ Production Tables
→ SQL Reporting Views
→ Google Sheets
→ Data Studio Dashboard

## Key Results

- 4,765 staging voter records
- 4,338 unique VoterIDs
- 427 duplicate excess rows
- 170 duplicated VoterIDs investigated
- 4,338 production voter records
- 6,000 contact records
- 0 orphan contact records
- 0 duplicate production VoterIDs

## SQL Analysis

- Contacted vs. uncontacted voters
- Contact rate by county
- Contact outcomes
- Contact attempts
- Volunteer activity

## Dashboard

[Dashboard link](https://datastudio.google.com/s/n1S02ZWxGjM)

![Dashboard Preview]([dashboard](gotv-voter-contact-analytics/dashboard_overview.png)
