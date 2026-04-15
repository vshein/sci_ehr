DROP TABLE IF EXISTS eicu_demo_coh_concepts.age_icu_intime;

CREATE TABLE eicu_demo_coh_concepts.age_icu_intime AS

SELECT

    vw.uniquepid,
    vw.patienthealthsystemstayid,
    vw.patientunitstayid,

    -- raw
    pt.age AS age_icu_intime_raw,

    -- cleaned
    CASE
        WHEN pt.age IS NULL THEN NULL

        -- handle censored value
        WHEN pt.age = '> 89' THEN 90

        -- numeric case
        ELSE CAST(pt.age AS NUMERIC)
    END AS age_icu_intime

'patient' AS source_table,
'eicu_demo' AS source_dataset

FROM eicu_demo_coh.visit_windows vw
LEFT JOIN eicu_demo_coh.patient pat
  ON vw.patientunitstayid = pat.patientunitstayid;
