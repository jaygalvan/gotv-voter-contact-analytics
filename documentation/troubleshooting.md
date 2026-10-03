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
