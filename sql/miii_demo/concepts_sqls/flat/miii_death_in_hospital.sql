
-- Note that the in hospital mortality aledry exists for mimic-iv but we made
-- a new one that would be a source of double checking

DROP TABLE IF EXISTS miii_demo_coh_concepts.death_in_hospital;
CREATE TABLE miii_demo_coh_concepts.death_in_hospital AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.icustay_id,

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

    'admissions-patients' AS source_table,
    'miii_demo_coh' AS source_dataset

FROM miii_demo_coh.visit_windows vw

LEFT JOIN miii_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id

LEFT JOIN miii_demo_coh.patients p
  ON vw.subject_id = p.subject_id;