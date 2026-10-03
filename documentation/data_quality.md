# GOTV Data Quality & SQL QA

## Purpose

This document summarizes the data-quality checks performed during
the transition from staging data to the PostgreSQL production tables.

The goal was to validate the data before using it for SQL analysis,
reporting, and dashboard development.

---

## Data Validation Workflow

```text
Source CSV
    ↓
Python / Pandas
    ↓
PostgreSQL Staging
    ↓
SQL Validation
    ↓
SQL Deduplication / Transformation
    ↓
PostgreSQL Production
    ↓
SQL Reporting Views
    ↓
Google Sheets
    ↓
Data Studio Dashboard
