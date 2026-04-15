-- This query makes the cohort visit window and their ids to be used later on in all

DROP TABLE IF EXISTS miiv_demo_coh.visit_windows;

CREATE TABLE miiv_demo_coh.visit_windows AS

SELECT
    adm.subject_id,
    adm.hadm_id,

    adm.admittime,
    adm.dischtime,
    adm.edregtime,

    icu.stay_id,
    icu.intime AS icu_intime,
    icu.outtime AS icu_outtime,

    /* hospital start */
    CONCAT_WS('_', 'miiv_demo', adm.subject_id, adm.hadm_id, icu.stay_id) AS sci_ehr_id,

    /* hospital start */
    CASE
        WHEN adm.edregtime IS NOT NULL
             AND adm.edregtime < adm.admittime
        THEN adm.edregtime
        ELSE adm.admittime
    END AS hospital_start,


    /* hospital end */
    CASE
        WHEN icu.outtime IS NOT NULL
             AND icu.outtime > adm.dischtime
        THEN icu.outtime
        ELSE adm.dischtime
    END AS hospital_end,

    /* flag: hospital_end modified by ICU */
    CASE
        WHEN icu.outtime IS NOT NULL
             AND icu.outtime > adm.dischtime
        THEN TRUE
        ELSE FALSE
    END AS hospital_end_modified,

    /* flag: hospital_start later than admission */
    CASE
        WHEN COALESCE(adm.edregtime, adm.admittime) > adm.admittime
        THEN TRUE
        ELSE FALSE
    END AS hospital_start_after_admit

FROM miiv_demo_coh.admissions adm

LEFT JOIN miiv_demo_coh.icustays icu
ON adm.subject_id = icu.subject_id
AND adm.hadm_id = icu.hadm_id;

