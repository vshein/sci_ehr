DROP TABLE IF EXISTS eicu_demo_coh_concepts.weight;

CREATE TABLE eicu_demo_coh_concepts.weight AS

SELECT
    vw.uniquepid,
    vw.patienthealthsystemstayid,
    vw.patientunitstayid,

    pt.admissionweight AS weight_raw,

    pt.admissionweight AS weight,

    'patient' AS source_table,
    'eicu_demo' AS source_dataset

FROM eicu_demo_coh.visit_windows vw
LEFT JOIN eicu_demo_coh.patient pt
    ON vw.patientunitstayid = pt.patientunitstayid;