-- ============================================================
-- GOTV VOTER CONTACT ANALYTICS
-- 05 - Reporting Views
-- ============================================================
--
-- Purpose:
-- Transform production tables into reusable SQL reporting
-- datasets for Google Sheets and Data Studio.
--
-- Reporting views created:
--
--   1. gotv.voter_contact_status
--   2. gotv.county_contact_summary
--   3. gotv.contact_outcome_summary
--   4. gotv.volunteer_activity
--   5. gotv.dashboard_kpis
--   6. gotv.data_quality_summary
--
-- Data flow:
--
-- gotv.voters
--       +
-- gotv.contact_history
--       ↓
-- SQL reporting views
--       ↓
-- Google Sheets
--       ↓
-- Data Studio dashboard
-- ============================================================


-- ============================================================
-- 1. VOTER CONTACT STATUS
-- ============================================================
--
-- Provides one reporting row per voter.
--
-- Used to identify:
--   - Contacted voters
--   - Uncontacted voters
--   - Number of contact attempts
--   - First contact date
--   - Most recent contact date
--
-- IMPORTANT:
-- LEFT JOIN preserves voters who have no contact records.
-- ============================================================

CREATE OR REPLACE VIEW gotv.voter_contact_status AS

SELECT
    v.voter_id,
    v.first_name,
    v.last_name,

    -- Simplify the production column name for reporting
    v.res_county_desc AS county,

    -- Create a calculated contacted/uncontacted status
    CASE
        WHEN COUNT(ch.contact_id) = 0
            THEN 'Uncontacted'
        ELSE 'Contacted'
    END AS contact_status,

    -- Number of contact attempts associated with the voter
    COUNT(ch.contact_id) AS contact_attempts,

    -- Earliest recorded contact
    MIN(ch.contact_date) AS first_contact_date,

    -- Most recent recorded contact
    MAX(ch.contact_date) AS last_contact_date

FROM gotv.voters v

LEFT JOIN gotv.contact_history ch
    ON v.voter_id = ch.voter_id

GROUP BY
    v.voter_id,
    v.first_name,
    v.last_name,
    v.res_county_desc;


-- ============================================================
-- 2. COUNTY CONTACT SUMMARY
-- ============================================================
--
-- Summarizes voter contact coverage by county.
--
-- Used for:
--   - County reporting
--   - Contact-rate comparisons
--   - Data Studio county charts
-- ============================================================

CREATE OR REPLACE VIEW gotv.county_contact_summary AS

SELECT
    county,

    -- Total voters in the county
    COUNT(*) AS total_voters,

    -- Voters with one or more contacts
    COUNT(*) FILTER (
        WHERE contact_status = 'Contacted'
    ) AS contacted_voters,

    -- Voters with zero contacts
    COUNT(*) FILTER (
        WHERE contact_status = 'Uncontacted'
    ) AS uncontacted_voters,

    -- Percentage of voters who have been contacted
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE contact_status = 'Contacted'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS contact_rate_percent

FROM gotv.voter_contact_status

GROUP BY county

ORDER BY county;


-- ============================================================
-- 3. CONTACT OUTCOME SUMMARY
-- ============================================================
--
-- Summarizes the outcomes recorded in contact history.
--
-- Used for:
--   - Outcome charts
--   - Contact activity reporting
-- ============================================================

CREATE OR REPLACE VIEW gotv.contact_outcome_summary AS

SELECT
    contact_result,

    -- Number of contact records with each outcome
    COUNT(*) AS contact_count

FROM gotv.contact_history

GROUP BY contact_result

ORDER BY contact_count DESC;


-- ============================================================
-- 4. VOLUNTEER ACTIVITY
-- ============================================================
--
-- Summarizes the number of contact records associated with
-- each volunteer.
--
-- Used for:
--   - Volunteer activity reporting
--   - Data Studio volunteer charts
-- ============================================================

CREATE OR REPLACE VIEW gotv.volunteer_activity AS

SELECT
    volunteer_id,

    -- Total contact records completed by the volunteer
    COUNT(*) AS total_contacts

FROM gotv.contact_history

GROUP BY volunteer_id

ORDER BY total_contacts DESC;


-- ============================================================
-- 5. DASHBOARD KPIs
-- ============================================================
--
-- Produces one row containing the primary dashboard metrics.
--
-- Used for:
--   - Data Studio KPI scorecards
-- ============================================================

CREATE OR REPLACE VIEW gotv.dashboard_kpis AS

SELECT

    -- Total voters
    COUNT(*) AS total_voters,

    -- Voters with at least one contact
    COUNT(*) FILTER (
        WHERE contact_status = 'Contacted'
    ) AS contacted_voters,

    -- Voters with no contact records
    COUNT(*) FILTER (
        WHERE contact_status = 'Uncontacted'
    ) AS uncontacted_voters,

    -- Total contact attempts
    SUM(contact_attempts) AS total_contact_attempts,

    -- Overall contact rate
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE contact_status = 'Contacted'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS contact_rate_percent

FROM gotv.voter_contact_status;


-- ============================================================
-- 6. DATA QUALITY / QA SUMMARY
-- ============================================================
--
-- Provides a single-row summary of the SQL QA results.
--
-- Used for:
--   - Data quality reporting
--   - Dashboard QA page
--   - Project documentation
-- ============================================================

CREATE OR REPLACE VIEW gotv.data_quality_summary AS

SELECT

    -- -----------------------------
    -- STAGING VOTER QA
    -- -----------------------------

    (
        SELECT COUNT(*)
        FROM staging.voters_raw
    ) AS staging_voter_rows,

    (
        SELECT COUNT(DISTINCT "VoterID")
        FROM staging.voters_raw
    ) AS unique_voter_ids,

    (
        SELECT COUNT(*)
        FROM staging.voters_raw
    )
    -
    (
        SELECT COUNT(DISTINCT "VoterID")
        FROM staging.voters_raw
    ) AS duplicate_excess_rows,

    (
        SELECT COUNT(*)
        FROM (
            SELECT "VoterID"
            FROM staging.voters_raw
            GROUP BY "VoterID"
            HAVING COUNT(*) > 1
        ) AS duplicate_groups
    ) AS duplicate_voter_ids,

    (
        SELECT COUNT(*)
        FROM staging.voters_raw
        WHERE "VoterID" IS NULL
           OR TRIM("VoterID") = ''
    ) AS missing_staging_voter_ids,


    -- -----------------------------
    -- PRODUCTION VOTER QA
    -- -----------------------------

    (
        SELECT COUNT(*)
        FROM gotv.voters
    ) AS production_voter_rows,

    (
        SELECT COUNT(*)
        FROM (
            SELECT voter_id
            FROM gotv.voters
            GROUP BY voter_id
            HAVING COUNT(*) > 1
        ) AS production_duplicates
    ) AS production_duplicate_ids,


    -- -----------------------------
    -- CONTACT HISTORY QA
    -- -----------------------------

    (
        SELECT COUNT(*)
        FROM staging.contact_history_raw
    ) AS staging_contact_rows,

    (
        SELECT COUNT(*)
        FROM gotv.contact_history
    ) AS production_contact_rows,

    (
        SELECT COUNT(*)
        FROM gotv.contact_history ch
        LEFT JOIN gotv.voters v
            ON ch.voter_id = v.voter_id
        WHERE v.voter_id IS NULL
    ) AS orphan_contact_rows,


    -- -----------------------------
    -- DUPLICATE EXCEPTIONS
    -- -----------------------------

    (
        SELECT COUNT(*)
        FROM (
            SELECT "VoterID"
            FROM staging.voters_raw
            GROUP BY "VoterID"
            HAVING COUNT(*) > 1
               AND COUNT(*) FILTER (
                   WHERE "Potential Fraud" = 0
               ) > 1
        ) AS exception_groups
    ) AS duplicate_groups_requiring_tiebreak;
