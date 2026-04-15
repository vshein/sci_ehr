DROP TABLE IF EXISTS eicu_demo_coh_concepts.egcs;
CREATE TABLE eicu_demo_coh_concepts.egcs AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.nursingchartoffset,

    (src.nursingchartoffset - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.nursingchartvalue AS NUMERIC) AS value,

    'NA' AS unit,

    src.nursingchartvalue AS value_raw,
  

    src.nursingchartcelltypevalname AS source_itemid,

    NULL AS source_label,

    'nursecharting' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.nursecharting src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.nursingchartcelltypevalname) ~ 'Eyes'
AND src.nursingchartvalue IS NOT NULL;
