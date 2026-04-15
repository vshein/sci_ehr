DROP TABLE IF EXISTS eicu_demo_coh_concepts.temp;
CREATE TABLE eicu_demo_coh_concepts.temp AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.observationoffset,

     (src.observationoffset - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.temperature AS NUMERIC) AS value,

    'C' AS unit,

    src.temperature AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'vitalperiodic' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.vitalperiodic src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.temperature IS NOT NULL;
