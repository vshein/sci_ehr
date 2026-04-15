DROP TABLE IF EXISTS eicu_demo_coh_concepts.samp;
CREATE TABLE eicu_demo_coh_concepts.samp AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,


    src.culturetakenoffset,

     (src.culturetakenoffset - cw.icu_intime) AS time_since_hadm_min, 

    CAST(src.organism AS NUMERIC) AS value,

    'NA' AS unit,

    src.organism AS value_raw,
    

    NULL AS source_itemid,

    NULL AS source_label,

    'microlab' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw


JOIN eicu_demo_coh.microlab src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE src.organism IS NOT NULL;
