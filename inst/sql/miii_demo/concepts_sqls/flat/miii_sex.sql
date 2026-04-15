
DROP TABLE IF EXISTS miii_demo_coh_concepts.sex;

CREATE TABLE miii_demo_coh_concepts.sex AS

SELECT
    cw.subject_id,
    cw.hadm_id,
    cw.icustay_id,
    
    pat.gender AS sex_raw,
    CASE
        WHEN pat.gender = 'Male' THEN 1
        WHEN pat.gender = 'Female' THEN 0
        ELSE NULL
    END AS sex,

  'patients' AS source_table,
  'miii_coh' AS source_dataset

FROM miii_demo_coh.visit_windows cw
LEFT JOIN miii_demo_coh.patients pat
  ON cw.subject_id = pat.subject_id;
