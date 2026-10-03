-- ============================================================
-- GOTV VOTER CONTACT ANALYTICS
-- 04 - Production Data Load
-- ============================================================
-- NOTE:
-- This script is intended to document the production load
-- process used for this project. It should not be rerun against
-- an already-populated production database without first
-- handling existing records.
--
-- Purpose:
-- Load validated and transformed staging data into the
-- production GOTV tables.
--
-- Production tables:
--   gotv.voters
--   gotv.contact_history
--
-- Data flow:
--
-- staging.voters_raw
--        ↓
-- SQL deduplication
--        ↓
-- gotv.voters
--
-- staging.contact_history_raw
--        ↓
-- SQL validation
--        ↓
-- gotv.contact_history
--
-- Important relational rules:
--   gotv.voters.voter_id = PRIMARY KEY
--   gotv.contact_history.contact_id = PRIMARY KEY
--   gotv.contact_history.voter_id =
--       FOREIGN KEY → gotv.voters.voter_id
--
-- Results from this project:
--   Production voters:    4,338
--   Production contacts:  6,000
-- ============================================================


-- ============================================================
-- 1. LOAD DEDUPLICATED VOTER DATA
-- ============================================================
--
-- The ROW_NUMBER() logic ensures that only one row per
-- VoterID is loaded into the production voter table.
--
-- The staging table itself is NOT modified.
-- ============================================================

WITH ranked_voters AS (

    SELECT
        r.*,

        ROW_NUMBER() OVER (
            PARTITION BY "VoterID"
            ORDER BY
                -- Prefer the non-flagged source record
                "Potential Fraud" ASC,

                -- Deterministic tie-breakers for remaining
                -- records within the same VoterID
                "FirstName",
                "LastName",
                "DriverLicCard",
                "ResStreetAddress"
        ) AS rn

    FROM staging.voters_raw r
)

INSERT INTO gotv.voters (
    voter_id,
    birth_year,
    last4_ssn,
    driver_lic_card,
    first_name,
    last_name,
    gender,
    res_street_address,
    res_city_desc,
    res_state,
    res_zip5,
    res_county_desc,
    party_desc,
    potential_fraud
)

SELECT
    "VoterID",
    "BirthYear",
    "LAST4SSN",
    "DriverLicCard",
    "FirstName",
    "LastName",
    "Gender",
    "ResStreetAddress",
    "ResCityDesc",
    "ResState",
    "ResZip5",
    "ResCountyDesc",
    "PartyDesc",
    "Potential Fraud"

FROM ranked_voters

WHERE rn = 1;


-- ============================================================
-- 2. VERIFY VOTER PRODUCTION ROW COUNT
-- ============================================================
--
-- Expected result:
--   4,338
-- ============================================================

SELECT COUNT(*) AS production_voter_rows
FROM gotv.voters;


-- ============================================================
-- 3. VERIFY VOTER PRIMARY-KEY INTEGRITY
-- ============================================================
--
-- There should be no VoterID appearing more than once.
--
-- Expected result:
--   0 rows
-- ============================================================

SELECT
    voter_id,
    COUNT(*) AS occurrences

FROM gotv.voters

GROUP BY voter_id

HAVING COUNT(*) > 1;


-- ============================================================
-- 4. LOAD CONTACT HISTORY
-- ============================================================
--
-- Contact records are loaded only after the voter production
-- table has been populated.
--
-- contact_id is intentionally omitted from the INSERT.
-- PostgreSQL generates it automatically because the production
-- table defines contact_id as BIGSERIAL.
-- ============================================================

INSERT INTO gotv.contact_history (
    voter_id,
    contact_date,
    contact_method,
    contact_result,
    volunteer_id
)

SELECT
    "VoterID",
    "ContactDate",
    "ContactMethod",
    "ContactResult",
    "VolunteerID"

FROM staging.contact_history_raw;


-- ============================================================
-- 5. VERIFY CONTACT-HISTORY PRODUCTION ROW COUNT
-- ============================================================
--
-- Expected result for this project:
--   6,000
-- ============================================================

SELECT COUNT(*) AS production_contact_rows
FROM gotv.contact_history;


-- ============================================================
-- 6. VERIFY FOREIGN-KEY / ORPHAN CONTACT INTEGRITY
-- ============================================================
--
-- Every contact record should reference an existing production
-- voter.
--
-- Expected result:
--   0
-- ============================================================

SELECT COUNT(*) AS orphan_contact_rows

FROM gotv.contact_history ch

LEFT JOIN gotv.voters v
    ON ch.voter_id = v.voter_id

WHERE v.voter_id IS NULL;


-- ============================================================
-- 7. FINAL PRODUCTION LOAD RECONCILIATION
-- ============================================================
--
-- Compare staging and production row counts.
-- ============================================================

SELECT
    (SELECT COUNT(*)
     FROM staging.voters_raw) AS staging_voter_rows,

    (SELECT COUNT(*)
     FROM gotv.voters) AS production_voter_rows,

    (SELECT COUNT(*)
     FROM staging.contact_history_raw) AS staging_contact_rows,

    (SELECT COUNT(*)
     FROM gotv.contact_history) AS production_contact_rows;
