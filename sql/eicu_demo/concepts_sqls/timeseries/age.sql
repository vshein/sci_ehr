DROP TABLE IF EXISTS eicu_demo_coh_concepts.age;
CREATE TABLE eicu_demo_coh_concepts.age AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.NA,

     (src.NA - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.age AS NUMERIC) AS value,

    'years' AS unit,

    src.age AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'patient' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.patient src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.age IS NOT NULL;
