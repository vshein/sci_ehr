-- This is our mapping. We can change it to sci cat instead
DROP TABLE IF EXISTS miiv_demo_coh_concepts.marital_status;

CREATE TABLE  miiv_demo_coh_concepts.marital_status AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.stay_id,

    adm.marital_status AS marital_status_raw,

     CASE
        WHEN adm.marital_status IS NULL THEN 'unknown'

        -- married-partner
        WHEN adm.marital_status IN (
            'MARRIED', 'LIFE PARTNER'
        ) THEN 'married-partner'

        -- without spouse or partner
        WHEN adm.marital_status IN (
            'SINGLE', 'SEPARATED', 'WIDOWED', 'DIVORCED'
        ) THEN 'without spouse or partner'

       -- unknown
        WHEN adm.marital_status IN (
            'UNKNOWN (DEFAULT)'
        ) THEN 'unknown'

        -- other
        WHEN adm.marital_status IN (
            'Other'
        ) THEN 'other'


        ELSE 'other'
    END AS marital_status,

'admissions' AS source_table,
'miiv_demo_coh' AS source_dataset   

FROM miiv_demo_coh.visit_windows vw
LEFT JOIN miiv_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id;
