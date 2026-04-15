DROP TABLE IF EXISTS eicu_demo_coh_concepts.phn;
CREATE TABLE eicu_demo_coh_concepts.phn AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.drugstartoffset,

    (src.drugstartoffset - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.drugdosage AS NUMERIC) AS value,

    'mcg/kg/min' AS unit,

    src.drugdosage AS value_raw,


    src.drugname AS source_itemid,

    NULL AS source_label,

    'infusiondrug_mod' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.infusiondrug_mod src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.drugname) ~*'^phenylephrine.*\(.+\)$'
AND src.drugdosage IS NOT NULL;
