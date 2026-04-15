DROP TABLE IF EXISTS eicu_demo_coh_concepts.abx;
CREATE TABLE eicu_demo_coh_concepts.abx AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.drugstartoffset,

    (src.drugstartoffset - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.drugdosage AS NUMERIC) AS value,

    'NA' AS unit,

    src.drugdosage AS value_raw,


    src.drugname AS source_itemid,

    NULL AS source_label,

    'infusiondrug_mod' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.infusiondrug_mod src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.drugname) ~*'bactrim|cipro|flagyl|metronidazole|zithromax|zosyn|(((amika|cleo|ofloxa)|(azithro|clinda|tobra|vanco)my)c|(ampi|oxa|peni|pipera)cill|cefazol|levaqu|rifamp)in'
AND src.drugdosage IS NOT NULL
UNION ALL
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.drugstartoffset,

    (src.drugstartoffset - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.drugdosage AS NUMERIC) AS value,

    'NA' AS unit,

    src.drugdosage AS value_raw,


    src.drugname AS source_itemid,

    NULL AS source_label,

    'medication_mod' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.medication_mod src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.drugname) ~*'cipro|flagyl|maxipime|metronidazole|tazobactam|zosyn|cef(azolin|epime)|(((azithro|clinda|vanco)my|ofloxa|vanco)c|levaqu|piperacill|roceph)in'
AND src.drugdosage IS NOT NULL;
