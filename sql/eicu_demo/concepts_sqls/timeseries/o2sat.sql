DROP TABLE IF EXISTS eicu_demo_coh_concepts.o2sat;
CREATE TABLE eicu_demo_coh_concepts.o2sat AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.observationoffset,

     (src.observationoffset - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.sao2 AS NUMERIC) AS value,

    '%' AS unit,

    src.sao2 AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'vitalperiodic' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.vitalperiodic src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.sao2 IS NOT NULL
UNION ALL
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.labresultoffset,

    (src.labresultoffset - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.labresult AS NUMERIC) AS value,

    '%' AS unit,

    src.labresult AS value_raw,
  

    src.labname AS source_itemid,

    NULL AS source_label,

    'lab' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.lab src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.labname) ~ 'O2 Sat (%)'
AND src.labresult IS NOT NULL;
