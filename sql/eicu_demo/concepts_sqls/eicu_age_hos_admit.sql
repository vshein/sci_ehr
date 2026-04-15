DROP TABLE IF EXISTS eicu_demo_coh_concepts.age_hos_admit;

CREATE TABLE eicu_demo_coh_concepts.age_hos_admit AS

SELECT

    vw.uniquepid,
    vw.patienthealthsystemstayid,
    vw.patientunitstayid,

    -- raw: there is no raw 

    -- cleaned
    CASE
    WHEN pt.age = '> 89' THEN
        90 + vw.hospitaladmitoffset / (365.25 * 24 * 60)

    ELSE
        CAST(pt.age AS NUMERIC)
        + vw.hospitaladmitoffset / (365.25 * 24 * 60)
END AS age_hos_admit

'patient' AS source_table,
'eicu_demo' AS source_dataset

FROM eicu_demo_coh.visit_windows vw
LEFT JOIN eicu_demo_coh.patient pat
  ON vw.patientunitstayid = pat.patientunitstayid;



