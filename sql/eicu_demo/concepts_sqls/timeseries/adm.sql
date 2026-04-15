DROP TABLE IF EXISTS eicu_demo_coh_concepts.adm;
CREATE TABLE eicu_demo_coh_concepts.adm AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.drugoffset,

     (src.drugoffset - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.admitdxpath AS NUMERIC) AS value,

    'NA' AS unit,

    src.admitdxpath AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'admissiondx' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.admissiondx src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.admitdxpath IS NOT NULL;
