-- ============================================================
-- GOTV VOTER CONTACT ANALYTICS
-- 03 - Voter Deduplication
-- ============================================================
--
-- Purpose:
-- Create a production-ready voter dataset containing exactly
-- one record per VoterID.
--
-- Source:
--   staging.voters_raw
--
-- Business rule:
--   One VoterID = one voter record in gotv.voters.
--
-- QA findings:
--   Staging rows:              4,765
--   Unique VoterIDs:           4,338
--   Duplicate excess rows:       427
--   Duplicated VoterID groups:   170
--
-- Deduplication approach:
--   1. Partition records by VoterID.
--   2. Prefer Potential Fraud = 0 over Potential Fraud = 1.
--   3. Use voter attributes as deterministic tie-breakers.
--   4. Keep only ROW_NUMBER() = 1.
--
-- Important:
--   The staging table is NOT modified or deleted from.
--   The transformation is applied only to the result that
--   will be loaded into production.
-- ============================================================


-- ============================================================
-- 1. RANK RECORDS WITHIN EACH VOTERID
-- ============================================================
--
-- ROW_NUMBER() assigns a sequence to each record belonging
-- to the same VoterID.
--
-- rn = 1  → selected production record
-- rn > 1  → duplicate record
-- ============================================================

WITH ranked_voters AS (

    SELECT
        r.*,

        ROW_NUMBER() OVER (
            PARTITION BY "VoterID"

            ORDER BY
                -- Prefer the non-flagged record
                "Potential Fraud" ASC,

                -- Deterministic tie-breakers for remaining
                -- conflicting records
                "FirstName",
                "LastName",
                "DriverLicCard",
                "ResStreetAddress"
        ) AS rn

    FROM staging.voters_raw r
)


-- ============================================================
-- 2. PREVIEW THE DEDUPLICATED RESULT
-- ============================================================
--
-- This does NOT modify any data.
-- It returns one selected record for each VoterID.
-- ============================================================

SELECT *
FROM ranked_voters
WHERE rn = 1
ORDER BY "VoterID";


-- ============================================================
-- 3. VERIFY THE EXPECTED ROW COUNT
-- ============================================================
--
-- Expected result:
--
--   4,338
--
-- because there are 4,338 unique VoterIDs in staging.
-- ============================================================

WITH ranked_voters AS (

    SELECT
        r.*,

        ROW_NUMBER() OVER (
            PARTITION BY "VoterID"
            ORDER BY
                "Potential Fraud" ASC,
                "FirstName",
                "LastName",
                "DriverLicCard",
                "ResStreetAddress"
        ) AS rn

    FROM staging.voters_raw r
)

SELECT COUNT(*) AS production_ready_rows
FROM ranked_voters
WHERE rn = 1;


-- ============================================================
-- 4. VERIFY THERE ARE NO DUPLICATE VOTERIDS IN THE RESULT
-- ============================================================
--
-- Expected result:
--
--   0 rows
--
-- This confirms the transformation produces one record
-- per VoterID.
-- ============================================================

WITH ranked_voters AS (

    SELECT
        r.*,

        ROW_NUMBER() OVER (
            PARTITION BY "VoterID"
            ORDER BY
                "Potential Fraud" ASC,
                "FirstName",
                "LastName",
                "DriverLicCard",
                "ResStreetAddress"
        ) AS rn

    FROM staging.voters_raw r
)

SELECT
    "VoterID",
    COUNT(*) AS occurrences
FROM ranked_voters
WHERE rn = 1
GROUP BY "VoterID"
HAVING COUNT(*) > 1;


-- ============================================================
-- 5. REVIEW THE THREE TIE-BREAK EXCEPTIONS
-- ============================================================
--
-- These VoterIDs contained more than one Potential Fraud = 0
-- record and therefore required the deterministic tie-break
-- logic above.
--
-- Exception groups:
--   Voter-ID-350
--   Voter-ID-3771
--   Voter-ID-971
-- ============================================================

WITH ranked_voters AS (

    SELECT
        r.*,

        ROW_NUMBER() OVER (
            PARTITION BY "VoterID"
            ORDER BY
                "Potential Fraud" ASC,
                "FirstName",
                "LastName",
                "DriverLicCard",
                "ResStreetAddress"
        ) AS rn

    FROM staging.voters_raw r
)

SELECT *
FROM ranked_voters
WHERE "VoterID" IN (
    'Voter-ID-350',
    'Voter-ID-3771',
    'Voter-ID-971'
)
ORDER BY "VoterID", rn;


-- ============================================================
-- END OF DEDUPLICATION
-- ============================================================
