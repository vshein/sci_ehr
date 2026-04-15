
-- Note that the in hospital mortality aledry exists for mimic-iv but we made
-- a new one that would be a source of double checking

DROP TABLE IF EXISTS miiv_demo_coh_concepts.death_in_hospital;
CREATE TABLE miiv_demo_coh_concepts.death_in_hospital AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.stay_id,

    adm.admittime,
    adm.dischtime,
    p.dod,

    -- raw
    adm.hospital_expire_flag AS death_in_hospital_raw,

    -- reconstructed
    CASE
        WHEN p.dod IS NOT NULL
         AND p.dod <= adm.dischtime 
         AND p.dod >= adm.admittime
        THEN 1
        ELSE 0
    END AS death_in_hospital,

    'admissions' AS source_table,
    'miiv_demo_coh' AS source_dataset

FROM miiv_demo_coh.visit_windows vw

LEFT JOIN miiv_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id

LEFT JOIN miiv_demo_coh.patients p
  ON vw.subject_id = p.subject_id;