-- This is our mapping. We can change it to sci cat instead

DROP TABLE IF EXISTS miii_demo_coh_concepts.insurance;

CREATE TABLE  miii_demo_coh_concepts.insurance AS


SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.icustay_id,

    adm.insurance AS insurance_raw,

     CASE
        WHEN adm.insurance IS NULL THEN 'unknown'

        -- medicare
        WHEN adm.insurance IN (
            'Medicare'
        ) THEN 'medicare'

        -- medicaid
        WHEN adm.insurance IN (
            'Medicaid'
        ) THEN 'medicaid'

       -- self_pay
        WHEN adm.insurance IN (
            'Self Pay'
        ) THEN 'self_pay'

       -- goverment
        WHEN adm.insurance IN (
            'Government'
        ) THEN 'government'

        -- private
        WHEN adm.insurance IN (
            'Private Health Insurance', 'Private'
        ) THEN 'private'

        -- other
        WHEN adm.insurance IN (
            'Other'
        ) THEN 'other'


        ELSE 'other'
    END AS insurance,

'admissions' AS source_table,
'miii_demo_coh' AS source_dataset

FROM miii_demo_coh.visit_windows vw
LEFT JOIN miii_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id;
