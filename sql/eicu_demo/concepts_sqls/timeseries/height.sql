DROP TABLE IF EXISTS eicu_demo_coh_concepts.height;
CREATE TABLE eicu_demo_coh_concepts.height AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.NA,

     (src.NA - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.NA AS NUMERIC) AS value,

    'cm' AS unit,

    src.NA AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'patient' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.patient src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.NA IS NOT NULL;
