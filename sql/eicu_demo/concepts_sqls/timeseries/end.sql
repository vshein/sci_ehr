DROP TABLE IF EXISTS eicu_demo_coh_concepts.end;
CREATE TABLE eicu_demo_coh_concepts.end AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.NA,

     (src.NA - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.ventendoffset AS NUMERIC) AS value,

    'NA' AS unit,

    src.ventendoffset AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'respiratorycare' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.respiratorycare src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.ventendoffset IS NOT NULL
UNION ALL
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.NA,

     (src.NA - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.priorventendoffset AS NUMERIC) AS value,

    'NA' AS unit,

    src.priorventendoffset AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'respiratorycare' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.respiratorycare src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.priorventendoffset IS NOT NULL
UNION ALL
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.NA,

    (src.NA - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.respchartvaluelabel AS NUMERIC) AS value,

    'NA' AS unit,

    src.respchartvaluelabel AS value_raw,
  

    src.respchartvalue AS source_itemid,

    NULL AS source_label,

    'respiratorycharting' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.respiratorycharting src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.respchartvalue) ~ 'off|Off|Suspended'
AND src.respchartvaluelabel IS NOT NULL;
