DROP TABLE IF EXISTS eicu_demo_coh.sex;

CREATE TABLE eicu_demo_coh.sex AS

SELECT

    vw.uniquepid,
    vw.patienthealthsystemstayid,
    vw.patientunitstayid,


    -- raw value
    pt.gender AS sex_raw,

    -- cleaned value
    CASE
      CASE
        WHEN pt.gender = 'M' THEN 1
        WHEN pt.gender = 'F' THEN 0
        ELSE NULL
    END AS sex


'patient' AS source_table,
'eicu_demo' AS source_dataset

FROM eicu_demo_coh.visit_windows vw
LEFT JOIN eicu_demo_coh.patient pt
  ON vw.patientunitstayid = pt.patientunitstayid;
