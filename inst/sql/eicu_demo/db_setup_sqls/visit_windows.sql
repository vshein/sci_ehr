-- This query makes the cohort visit window and their ids to be used later on in all

DROP TABLE IF EXISTS eicu_demo_coh.visit_windows;

CREATE TABLE eicu_demo_coh.visit_windows AS

SELECT
    pat.uniquepid,
    pat.patientunitstayid,
    pat.patienthealthsystemstayid,

    pat.hospitaladmitoffset,
    pat.hospitaldischargeoffset,

    pat.unitdischargeoffset,

    /* hospital start */
    NULL AS hospital_start,
    NULL AS hospital_end,
    0::numeric AS admittime,

    /* hospital end */
    (pat.hospitaldischargeoffset - pat.hospitaladmitoffset) AS dischtime,
    -pat.hospitaladmitoffset AS icu_intime,
    (pat.unitdischargeoffset - pat.hospitaladmitoffset) AS icu_outtime

FROM eicu_demo_coh.patient pat;

