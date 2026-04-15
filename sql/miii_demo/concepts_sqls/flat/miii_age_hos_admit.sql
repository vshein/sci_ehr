-- THIS SCRIPT IS AUTOMATICALLY GENERATED. DO NOT EDIT IT DIRECTLY.
-- MMR: This is directly copied form mimic git


DROP TABLE IF EXISTS miii_demo_coh_concepts.age_hos_admit;

CREATE TABLE  miii_demo_coh_concepts.age_hos_admit AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.icustay_id,


    CASE
        WHEN adm.admittime IS NULL OR pat.dob IS NULL THEN NULL
        ELSE LEAST(
                 ROUND(
                EXTRACT(EPOCH FROM (adm.admittime - pat.dob)) / 31556908.8
            , 1),
            90
        )
    END AS age_hos_admit,

'patients'  AS source_table,
'miii_demo' AS source_dataset

FROM miii_demo_coh.visit_windows vw
LEFT JOIN miii_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id
LEFT JOIN miii_demo_coh.patients pat
  ON vw.subject_id = pat.subject_id;