DROP TABLE IF EXISTS miiv_demo_coh_concepts.age_icu_intime;

CREATE TABLE  miiv_demo_coh_concepts.age_icu_intime AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.stay_id,

    CASE
        WHEN vw.stay_id IS NULL OR ie.intime IS NULL THEN NULL
        ELSE LEAST(
            ROUND(
                pat.anchor_age
                + EXTRACT(EPOCH FROM ie.intime - MAKE_TIMESTAMP(pat.anchor_year,1,1,0,0,0))
                  / 31556908.8
            ,1),
            90
        )
    END AS age_icu_intime

FROM miiv_demo_coh.visit_windows vw

LEFT JOIN miiv_demo_coh.icustays ie
  ON vw.stay_id = ie.stay_id
LEFT JOIN miiv_demo_coh.patients pat
  ON vw.subject_id = pat.subject_id;
