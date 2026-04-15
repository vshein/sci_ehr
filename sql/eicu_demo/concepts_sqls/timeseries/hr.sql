DROP TABLE IF EXISTS eicu_demo_coh_concepts.hr;
CREATE TABLE eicu_demo_coh_concepts.hr AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.observationoffset,

     (src.observationoffset - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.heartrate AS NUMERIC) AS value,

    'bpm' AS unit,

    src.heartrate AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'vitalperiodic' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.vitalperiodic src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.heartrate IS NOT NULL;
