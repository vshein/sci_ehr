DROP TABLE IF EXISTS eicu_demo_coh_concepts.vent_start;
CREATE TABLE eicu_demo_coh_concepts.vent_start AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.NA,

     (src.NA - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.NA AS NUMERIC) AS value,

    'NA' AS unit,

    src.NA AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'respiratorycare' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.respiratorycare src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.NA IS NOT NULL
UNION ALL
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.NA,

     (src.NA - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.NA AS NUMERIC) AS value,

    'NA' AS unit,

    src.NA AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'respiratorycare' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.respiratorycare src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.NA IS NOT NULL
UNION ALL
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.NA,

    (src.NA - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.NA AS NUMERIC) AS value,

    'NA' AS unit,

    src.NA AS value_raw,
  

    src.respcharttypecat AS source_itemid,

    NULL AS source_label,

    'respiratorycharting' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.respiratorycharting src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.respcharttypecat) ~ 'Start|Continued|respFlowPtVentData'
AND src.NA IS NOT NULL;
