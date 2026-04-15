DROP TABLE IF EXISTS eicu_demo_coh_concepts.race;

CREATE TABLE eicu_demo_coh_concepts.race AS

SELECT

    vw.uniquepid,
    vw.patienthealthsystemstayid,
    vw.patientunitstayid,


    -- raw value
    pt.ethnicity AS race_raw,

    -- cleaned value
    CASE
        -- NA handling
        WHEN pt.ethnicity IS NULL THEN 'unknown'

        -- white
        WHEN pt.ethnicity = 'Caucasian' THEN 'white'

        -- black
        WHEN pt.ethnicity = 'African American' THEN 'black'

        -- hispanic
        WHEN pt.ethnicity = 'Hispanic' THEN 'hispanic'

        -- asian
        WHEN pt.ethnicity = 'Asian' THEN 'asian'

        -- native
        WHEN pt.ethnicity = 'Native American' THEN 'native'

        -- other
        WHEN pt.ethnicity IN ('Other', 'Other/Unknown') THEN 'other'

        -- fallback
        ELSE 'other'
    END AS race

'patient' AS source_table,
'eicu_demo' AS source_dataset

FROM eicu_demo_coh.visit_windows vw
LEFT JOIN eicu_demo_coh.patient pat
  ON vw.patientunitstayid = pat.patientunitstayid;
