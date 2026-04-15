
DROP TABLE IF EXISTS miiv_demo_coh_concepts.age_hos_admit;

CREATE TABLE  miiv_demo_coh_concepts.age_hos_admit AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.stay_id,

    -- raw
    pat.anchor_age AS age_hos_admit_raw,


    CASE
        WHEN adm.admittime IS NULL THEN NULL
        ELSE LEAST(
            ROUND(
                pat.anchor_age
                + EXTRACT(EPOCH FROM adm.admittime - MAKE_TIMESTAMP(pat.anchor_year,1,1,0,0,0))
                  / 31556908.8
            ,1),
            90
        )
    END AS age_hos_admit,

'patients'  AS source_table,
'miiv_demo_coh' AS source_dataset

FROM miiv_demo_coh.visit_windows vw
LEFT JOIN miiv_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id
LEFT JOIN miiv_demo_coh.patients pat
  ON vw.subject_id = pat.subject_id;