DROP TABLE IF EXISTS eicu_demo_coh_concepts.norepi_rate;
CREATE TABLE eicu_demo_coh_concepts.norepi_rate AS
SELECT
    cw.uniquepid,
    cw.patienthealthsystemstayid,
    cw.patientunitstayid,


    cw.icu_intime,

    src.infusionoffset,

    (src.infusionoffset - cw.icu_intime) AS time_since_hadm_min,

    CAST(src.drugamount AS NUMERIC) AS value,

    'mcg/kg/min' AS unit,

    src.drugamount AS value_raw,


    src.drugname AS source_itemid,

    NULL AS source_label,

    'infusiondrug' AS source_table,
    'eicu_demo_coh' AS source_dataset

FROM eicu_demo_coh.visit_windows cw

JOIN eicu_demo_coh.infusiondrug src
    ON cw.patientunitstayid = src.patientunitstayid



WHERE LOWER(src.drugname) ~*'^norepi.*\(.+\)$'
AND src.drugamount IS NOT NULL;
