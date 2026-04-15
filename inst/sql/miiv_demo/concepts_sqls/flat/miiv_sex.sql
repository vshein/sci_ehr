
DROP TABLE IF EXISTS miiv_demo_coh_concepts.sex;

CREATE TABLE miiv_demo_coh_concepts.sex AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.stay_id,
    
    pat.gender AS sex_raw,
    CASE
        WHEN pat.gender = 'M' THEN 1
        WHEN pat.gender = 'F' THEN 0
        ELSE NULL
    END AS sex,

  'patients' AS source_table,
  'miiv_demo_coh' AS source_dataset

FROM miiv_demo_coh.visit_windows vw
LEFT JOIN miiv_demo_coh.patients pat
  ON vw.subject_id = pat.subject_id;
