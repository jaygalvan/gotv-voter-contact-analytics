-- ============================================================
-- GOTV VOTER CONTACT ANALYTICS
-- 01 - Database Schema
-- ============================================================
--
-- Purpose:
-- Defines the PostgreSQL schemas and production/staging
-- tables used for the GOTV voter contact analytics project.
--
-- Data flow:
--
-- CSV files
--     ↓
-- staging tables
--     ↓
-- SQL validation / transformation
--     ↓
-- production tables
--     ↓
-- SQL reporting views
--
-- Important business rule:
-- One VoterID = one voter record.
--
-- Contact history follows a one-to-many relationship:
-- One voter can have zero, one, or many contact records.
-- ============================================================


-- ============================================================
-- 1. CREATE SCHEMAS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS gotv;
CREATE SCHEMA IF NOT EXISTS staging;


-- ============================================================
-- 2. PRODUCTION TABLE: GOTV.VOTERS
-- ============================================================
--
-- One row per VoterID.
-- voter_id is the PRIMARY KEY, enforcing uniqueness.
-- ============================================================

CREATE TABLE IF NOT EXISTS gotv.voters (
    voter_id VARCHAR(50) PRIMARY KEY,
    birth_year VARCHAR(20),
    last4_ssn VARCHAR(20),
    driver_lic_card VARCHAR(20),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    gender VARCHAR(20),
    res_street_address VARCHAR(150),
    res_city_desc VARCHAR(100),
    res_state VARCHAR(50),
    res_zip5 VARCHAR(20),
    res_county_desc VARCHAR(100),
    party_desc VARCHAR(50),
    potential_fraud INTEGER
);


-- ============================================================
-- 3. PRODUCTION TABLE: GOTV.CONTACT_HISTORY
-- ============================================================
--
-- One voter can have many contact records.
--
-- contact_id:
--   Unique identifier for each contact event.
--
-- voter_id:
--   FOREIGN KEY connecting the contact record to gotv.voters.
-- ============================================================

CREATE TABLE IF NOT EXISTS gotv.contact_history (
    contact_id BIGSERIAL PRIMARY KEY,
    voter_id VARCHAR(50) NOT NULL,
    contact_date DATE NOT NULL,
    contact_method VARCHAR(30) NOT NULL,
    contact_result VARCHAR(50) NOT NULL,
    volunteer_id VARCHAR(30) NOT NULL,

    CONSTRAINT fk_contact_voter
        FOREIGN KEY (voter_id)
        REFERENCES gotv.voters(voter_id)
);


-- ============================================================
-- 4. STAGING TABLE: STAGING.VOTERS_RAW
-- ============================================================
--
-- This table mirrors the structure of voters_clean.csv.
--
-- Staging is intentionally less restrictive because incoming
-- data should be loaded and inspected before production rules
-- are enforced.
-- ============================================================

CREATE TABLE IF NOT EXISTS staging.voters_raw (
    "VoterID" VARCHAR(50),
    "BirthYear" VARCHAR(20),
    "LAST4SSN" VARCHAR(20),
    "DriverLicCard" VARCHAR(20),
    "FirstName" VARCHAR(100),
    "LastName" VARCHAR(100),
    "Gender" VARCHAR(20),
    "ResStreetAddress" VARCHAR(150),
    "ResCityDesc" VARCHAR(100),
    "ResState" VARCHAR(50),
    "ResZip5" VARCHAR(20),
    "ResCountyDesc" VARCHAR(100),
    "PartyDesc" VARCHAR(50),
    "Potential Fraud" INTEGER
);


-- ============================================================
-- 5. STAGING TABLE: STAGING.CONTACT_HISTORY_RAW
-- ============================================================
--
-- Mirrors the structure of the contact-history CSV.
--
-- contact_id is intentionally NOT included here.
-- PostgreSQL generates contact_id automatically in the
-- production table using BIGSERIAL.
-- ============================================================

CREATE TABLE IF NOT EXISTS staging.contact_history_raw (
    "VoterID" VARCHAR(50),
    "ContactDate" DATE,
    "ContactMethod" VARCHAR(30),
    "ContactResult" VARCHAR(50),
    "VolunteerID" VARCHAR(30)
);


-- ============================================================
-- END OF SCHEMA DEFINITION
-- ============================================================
