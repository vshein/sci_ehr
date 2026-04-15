DROP TABLE IF EXISTS eicu_demo_coh_concepts.urine;
CREATE TABLE eicu_demo_coh_concepts.urine AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.intakeoutputoffset,

    (src.intakeoutputoffset - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.cellvaluenumeric AS NUMERIC) AS value,

    'mL' AS unit,

    src.cellvaluenumeric AS value_raw,
  

    src.celllabel AS source_itemid,

    NULL AS source_label,

    'intakeoutput' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.intakeoutput src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.celllabel) ~ 'Urine|URINE CATHETER'
AND src.cellvaluenumeric IS NOT NULL
UNION ALL
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.intakeoutputoffset,

    (src.intakeoutputoffset - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.cellvaluenumeric AS NUMERIC) AS value,

    'mL' AS unit,

    src.cellvaluenumeric AS value_raw,


    src.celllabel AS source_itemid,

    NULL AS source_label,

    'intakeoutput' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.intakeoutput src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.celllabel) ~*'catheter.+output|output.+catheter'
AND src.cellvaluenumeric IS NOT NULL;
