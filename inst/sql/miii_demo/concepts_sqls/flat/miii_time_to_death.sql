DROP TABLE IF EXISTS miii_demo_coh_concepts.time_to_death;

CREATE TABLE miii_demo_coh_concepts.time_to_death AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.icustay_id,

    adm.admittime,
    adm.dischtime,
    p.dod,

    -- raw indicator (optional)
    adm.hospital_expire_flag AS death_in_hospital,

    -- time to death in days
    CASE
        WHEN p.dod IS NOT NULL
        THEN EXTRACT(EPOCH FROM (p.dod - adm.admittime)) / 86400.0
        ELSE NULL
    END AS time_to_death,

    'admissions-patients' AS source_table,
    'miii_demo_coh' AS source_dataset

FROM miii_demo_coh.visit_windows vw

LEFT JOIN miii_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id

LEFT JOIN miii_demo_coh.patients p
  ON vw.subject_id = p.subject_id;