DROP TABLE IF EXISTS eicu_demo_coh_concepts.mortality;

CREATE TABLE eicu_demo_coh_concepts.mortality AS

SELECT
    vw.uniquepid,
    vw.patienthealthsystemstayid,
    vw.patientunitstayid,

    pt.hospitaldischargestatus AS is_hos_mor_raw,

    CASE
        WHEN pt.hospitaldischargestatus = 'Expired' THEN 1
        WHEN pt.hospitaldischargestatus IS NULL THEN NULL
        ELSE 0
    END AS is_hos_mor


'patient' AS source_table,
'eicu_demo' AS source_dataset

FROM eicu_demo_coh.visit_windows vw
LEFT JOIN eicu_demo_coh.patient pt
    ON vw.patientunitstayid = pt.patientunitstayid;