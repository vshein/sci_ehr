DROP TABLE IF EXISTS eicu_demo_coh_medication_mod;

CREATE TABLE eicu_demo_coh.medication_mod AS
WITH base AS (
    SELECT
        m.patientunitstayid,
        m.drugstartoffset,
        m.drugstopoffset,

        -- raw fields
        m.drugname,
        m.dosage,
        m.routeadmin,

        -- preserve originals
        m.drugname AS original_drugname,
        m.dosage   AS original_drugdosage,
        m.routeadmin AS original_route

    FROM eicu_demo_coh.medication m
),

parsed AS (
    SELECT
        *,

        -- split dosage into two parts (value + unit)
        split_part(original_drugdosage, ' ', 1) AS dose_part,
        split_part(original_drugdosage, ' ', 2) AS unit_part

    FROM base
)

SELECT
    patientunitstayid,
    drugstartoffset,
    drugstopoffset,

    -- cleaned drug name (no change yet)
    drugname,

    -- numeric dosage (safe cast)
    CASE
        WHEN dose_part ~ '^[0-9.,]+$'
        THEN replace(dose_part, ',', '')::double precision
        ELSE NULL
    END AS drugdosage,

    -- unit cleaning
    CASE
        WHEN trim(unit_part) = '' THEN NULL
        WHEN unit_part ~ '^[0-9]+$' THEN NULL  -- catches "125 12" case
        ELSE trim(unit_part)
    END AS drugunit,

    -- originals
    original_drugname,
    original_drugdosage,
    unit_part AS original_drugunit,
    original_route,

    -- provenance
    'medication' AS source_tab

FROM parsed;