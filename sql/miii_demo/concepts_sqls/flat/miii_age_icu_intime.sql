-- THIS SCRIPT IS AUTOMATICALLY GENERATED. DO NOT EDIT IT DIRECTLY.


DROP TABLE IF EXISTS miii_demo_coh_concepts.age_icu_intime;

CREATE TABLE  miii_demo_coh_concepts.age_icu_intime AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.icustay_id,


    CASE
        WHEN vw.icustay_id IS NULL OR ie.intime IS NULL THEN NULL
        ELSE LEAST(
             ROUND(
                EXTRACT(EPOCH FROM (vw.icu_intime - pat.dob)) / 31556908.8
            , 1),
            90
        )
    END AS age_icu_intime,

    'admissions-icustays' AS source_table,
    'miii_demo_coh' AS source_dataset

 
FROM miii_demo_coh.visit_windows vw

LEFT JOIN miii_demo_coh.icustays ie
  ON vw.icustay_id = ie.icustay_id
LEFT JOIN miii_demo_coh.patients pat
  ON vw.subject_id = pat.subject_id;

   
