DROP TABLE IF EXISTS eicu_demo_coh.admissiondrug_mod;

CREATE TABLE eicu_demo_coh.admissiondrug_mod AS
WITH base AS (
    SELECT
        ad.patientunitstayid,
        ad.drugoffset,

        -- cleaned (initial pass-through)
        ad.drugname,
        ad.drugdosage,
        ad.drugunit,

        -- originals
        ad.drugname AS original_drugname,
        ad.drugdosage::text AS original_drugdosage,
        ad.drugunit AS original_drugunit

    FROM eicu_demo_coh.admissiondrug ad
)

SELECT
    patientunitstayid,
    drugoffset,

    -- cleaned values
    drugname,
    drugdosage,

    CASE 
        WHEN trim(drugunit) = '' THEN NULL
        ELSE trim(drugunit)
    END AS drugunit,

    -- originals
    original_drugname,
    original_drugdosage,
    original_drugunit,

    'admissiondrug' AS source_tab

FROM base;