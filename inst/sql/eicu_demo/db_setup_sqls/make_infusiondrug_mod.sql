DROP TABLE IF EXISTS eicu_demo_coh.infusiondrug_mod;

CREATE TABLE eicu_demo_coh.infusiondrug_mod AS
WITH base AS (
    SELECT
        i.patientunitstayid,
        i.infusionoffset,
        i.drugamount,
        i.drugname,

        -- originals
        i.drugname AS original_drugname,
        i.drugamount::text AS original_drugdosage

    FROM eicu_demo_coh.infusiondrug i
),

extracted AS (
    SELECT
        *,

        -- extract LAST parentheses, e.g. "(mcg/kg/min)"
        substring(original_drugname from '\([^()]*\)$') AS unit_part

    FROM base
),

cleaned AS (
    SELECT
        *,

        -- strip parentheses → unit candidate
        trim(both ' ' from replace(replace(unit_part, '(', ''), ')', '')) AS unit_candidate,

        -- remove trailing "(...)" from drugname
        trim(
            regexp_replace(original_drugname, '\s*\([^()]*\)$', '')
        ) AS drugname_clean

    FROM extracted
)

SELECT
    patientunitstayid,

    -- represent as point event (document this!)
    infusionoffset AS drugstartoffset,
    infusionoffset AS drugstopoffset,

    -- cleaned
    drugname_clean AS drugname,
    drugamount::double precision AS drugdosage,

    CASE
        WHEN unit_candidate IN (
            'ml/hr', 'mcg/kg/min', 'units/hr', 'mg/hr',
            'mcg/min', 'mcg/hr', 'mcg/kg/hr', 'mg/min',
            'units/min', 'ml', 'units/kg/hr',
            'mg/kg/min', 'mg/kg/hr', 'nanograms/kg/min'
        )
        THEN unit_candidate
        ELSE NULL
    END AS drugunit,

    -- originals
    original_drugname,
    unit_part AS original_drugunit,
    original_drugdosage,

    -- provenance
    'infusiondrug' AS source_tab

FROM cleaned;