DROP TABLE IF EXISTS eicu_demo_coh_concepts.hosp_los;

CREATE TABLE eicu_demo_coh_concepts.hosp_los AS

SELECT
    vw.uniquepid,
    vw.patienthealthsystemstayid,
    vw.patientunitstayid,

    -- raw LOS in minutes (as provided by eICU)
    NULL AS hosp_los_raw,

    (pt.hospitaldischargeoffset - pt.hospitaladmitoffset)::integer AS hosp_los,

    'patient' AS source_table,
    'eicu_demo' AS source_dataset

FROM eicu_demo_coh.visit_windows vw
LEFT JOIN eicu_demo_coh.patient pt
    ON vw.patientunitstayid = pt.patientunitstayid;