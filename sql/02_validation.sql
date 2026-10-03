-- ============================================================
-- GOTV VOTER CONTACT ANALYTICS
-- 02 - Data Validation / SQL QA
-- ============================================================
--
-- Purpose:
-- Validate staging and production data before reporting and
-- dashboard development.
--
-- Validation areas:
--   1. Row counts
--   2. Missing VoterIDs
--   3. Duplicate VoterIDs
--   4. Duplicate-record investigation
--   5. Gender values
--   6. Party values
--   7. Potential Fraud values
--   8. Contact-history validation
--   9. Production primary-key validation
--  10. Production foreign-key validation
--
-- Key findings from this project:
--   Staging voter rows:       4,765
--   Unique VoterIDs:          4,338
--   Excess duplicate rows:      427
--   Duplicated VoterID groups:  170
--   Production voter rows:    4,338
--   Production duplicate IDs:     0
--   Staging contact rows:     6,000
--   Production contact rows:  6,000
--   Orphan contact rows:          0
-- ============================================================


-- ============================================================
-- 1. STAGING VOTER ROW COUNT
-- ============================================================
--
-- Establish the number of voter records imported from the CSV.
-- ============================================================

SELECT COUNT(*) AS staging_voter_rows
FROM staging.voters_raw;


-- ============================================================
-- 2. UNIQUE VOTERID COUNT
-- ============================================================
--
-- Determine how many unique voters exist in staging.
-- This is compared with the total row count to identify
-- duplicate VoterIDs.
-- ============================================================

SELECT COUNT(DISTINCT "VoterID") AS unique_voter_ids
FROM staging.voters_raw;


-- ============================================================
-- 3. DUPLICATE EXCESS-ROW COUNT
-- ============================================================
--
-- Calculates how many extra rows exist because of duplicate
-- VoterIDs.
--
-- Example from this project:
--   4,765 total rows - 4,338 unique VoterIDs = 427 duplicates
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "VoterID") AS unique_voters,
    COUNT(*) - COUNT(DISTINCT "VoterID") AS duplicate_excess_rows
FROM staging.voters_raw;


-- ============================================================
-- 4. MISSING VOTERIDS
-- ============================================================
--
-- VoterID is the business key for the voter table and later
-- becomes the production PRIMARY KEY.
-- ============================================================

SELECT COUNT(*) AS missing_voter_ids
FROM staging.voters_raw
WHERE "VoterID" IS NULL
   OR TRIM("VoterID") = '';


-- ============================================================
-- 5. IDENTIFY DUPLICATED VOTERIDS
-- ============================================================
--
-- Shows which VoterIDs occur more than once and how many
-- records exist for each.
-- ============================================================

SELECT
    "VoterID",
    COUNT(*) AS occurrences
FROM staging.voters_raw
GROUP BY "VoterID"
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;


-- ============================================================
-- 6. COUNT THE NUMBER OF DUPLICATED VOTERID GROUPS
-- ============================================================
--
-- Determines how many distinct VoterIDs are affected by
-- duplication.
-- ============================================================

SELECT COUNT(*) AS duplicate_voter_id_groups
FROM (
    SELECT "VoterID"
    FROM staging.voters_raw
    GROUP BY "VoterID"
    HAVING COUNT(*) > 1
) AS duplicate_groups;


-- ============================================================
-- 7. INVESTIGATE DUPLICATE RECORD STRUCTURE
-- ============================================================
--
-- Determines whether duplicate records are:
--   - exact duplicates
--   - different only in Potential Fraud
--   - different in other voter information
--
-- This helped establish the deduplication strategy used later.
-- ============================================================

SELECT
    "VoterID",
    COUNT(*) AS occurrences,

    COUNT(DISTINCT to_jsonb(r))
        AS distinct_full_records,

    COUNT(
        DISTINCT (to_jsonb(r) - 'Potential Fraud')
    ) AS distinct_records_without_fraud_flag

FROM staging.voters_raw r

GROUP BY "VoterID"

HAVING COUNT(*) > 1

ORDER BY occurrences DESC, "VoterID";


-- ============================================================
-- 8. DUPLICATE ANALYSIS BY POTENTIAL FRAUD FLAG
-- ============================================================
--
-- Shows how many duplicate rows are flagged versus unflagged.
-- ============================================================

SELECT
    "VoterID",
    COUNT(*) AS occurrences,

    COUNT(*) FILTER (
        WHERE "Potential Fraud" = 0
    ) AS non_fraud_rows,

    COUNT(*) FILTER (
        WHERE "Potential Fraud" = 1
    ) AS fraud_rows

FROM staging.voters_raw

GROUP BY "VoterID"

HAVING COUNT(*) > 1

ORDER BY occurrences DESC, "VoterID";


-- ============================================================
-- 9. CHECK EXPECTED GENDER VALUES
-- ============================================================
--
-- Profile the values actually present in the source data
-- before applying database constraints.
-- ============================================================

SELECT
    "Gender",
    COUNT(*) AS row_count
FROM staging.voters_raw
GROUP BY "Gender"
ORDER BY "Gender";


-- ============================================================
-- 10. CHECK EXPECTED PARTY VALUES
-- ============================================================
--
-- Profile the values actually present in PartyDesc.
-- ============================================================

SELECT
    "PartyDesc",
    COUNT(*) AS row_count
FROM staging.voters_raw
GROUP BY "PartyDesc"
ORDER BY "PartyDesc";


-- ============================================================
-- 11. CHECK POTENTIAL FRAUD VALUES
-- ============================================================
--
-- Profile the values present in the Potential Fraud field.
-- ============================================================

SELECT
    "Potential Fraud",
    COUNT(*) AS row_count
FROM staging.voters_raw
GROUP BY "Potential Fraud"
ORDER BY "Potential Fraud";


-- ============================================================
-- 12. CONTACT-HISTORY ROW COUNT
-- ============================================================
--
-- Establish the number of contact records imported from the
-- contact-history CSV.
-- ============================================================

SELECT COUNT(*) AS staging_contact_rows
FROM staging.contact_history_raw;


-- ============================================================
-- 13. MISSING CONTACT VOTERIDS
-- ============================================================
--
-- Contact records cannot be linked to a voter if VoterID
-- is missing.
-- ============================================================

SELECT COUNT(*) AS missing_contact_voter_ids
FROM staging.contact_history_raw
WHERE "VoterID" IS NULL
   OR TRIM("VoterID") = '';


-- ============================================================
-- 14. CHECK CONTACT VOTERIDS AGAINST PRODUCTION VOTERS
-- ============================================================
--
-- Identifies contact records whose VoterID does not exist
-- in gotv.voters.
--
-- Expected result after production loading:
--   0 unmatched VoterIDs
-- ============================================================

SELECT DISTINCT
    ch."VoterID"
FROM staging.contact_history_raw ch

LEFT JOIN gotv.voters v
    ON v.voter_id = ch."VoterID"

WHERE v.voter_id IS NULL

ORDER BY ch."VoterID";


-- ============================================================
-- 15. PRODUCTION VOTER COUNT
-- ============================================================
--
-- Verify the final number of voter records loaded into
-- gotv.voters.
-- ============================================================

SELECT COUNT(*) AS production_voter_rows
FROM gotv.voters;


-- ============================================================
-- 16. PRODUCTION PRIMARY-KEY VALIDATION
-- ============================================================
--
-- Confirm that no VoterID occurs more than once in production.
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
-- 17. CONTACT-HISTORY PRODUCTION COUNT
-- ============================================================
--
-- Verify the number of contact records loaded into production.
-- ============================================================

SELECT COUNT(*) AS production_contact_rows
FROM gotv.contact_history;


-- ============================================================
-- 18. FOREIGN-KEY / ORPHAN CONTACT VALIDATION
-- ============================================================
--
-- Verify that every production contact record points to an
-- existing production voter.
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
-- END OF VALIDATION / QA
-- ============================================================
