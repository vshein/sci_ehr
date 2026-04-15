DROP TABLE IF EXISTS miiv_demo_coh_concepts.admission_service;

CREATE TABLE miiv_demo_coh_concepts.admission_service AS

WITH categorized AS (
    SELECT
        vw.subject_id,
        vw.hadm_id,
        vw.stay_id,

        s.curr_service,
        s.transfertime,

        CASE
            WHEN s.curr_service IN ('MED','CMED','NMED','OMED') THEN 'med'
            WHEN s.curr_service IN (
                'SURG','CSURG','VSURG','NSURG',
                'ORTHO','TRAUM','TSURG',
                'PSURG','ENT','DENT'
            ) THEN 'surg'
            WHEN s.curr_service IN ('NB','NBB','GU','GYN','OBS','PSYCH','EYE')
                THEN 'other'
            ELSE NULL
        END AS admission_type

    FROM miiv_demo_coh.visit_windows vw

    LEFT JOIN miiv_demo_coh.services s
      ON vw.subject_id = s.subject_id
     AND vw.hadm_id   = s.hadm_id
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY subject_id, hadm_id
            ORDER BY transfertime
        ) AS rn
    FROM categorized
)

SELECT
    subject_id,
   hadm_id,
    stay_id,

    curr_service AS admission_type_raw,
    admission_type,

    'services'   AS source_table,
    'miiv_demo_coh'  AS source_dataset
    

FROM ranked
WHERE rn = 1;