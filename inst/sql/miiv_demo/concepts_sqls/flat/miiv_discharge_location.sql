DROP TABLE IF EXISTS miiv_demo_coh_concepts.discharge_location;

CREATE TABLE miiv_demo_coh_concepts.discharge_location AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.stay_id,

    adm.discharge_location AS discharge_location_raw,

    CASE
        WHEN adm.discharge_location IS NULL THEN 'Unknown'

        -- HOSPITAL
        WHEN adm.discharge_location IN (
            'ACUTE HOSPITAL',
            'Acute Care/Floor',
            'CHRONIC/LONG TERM ACUTE CARE',
            'SHORT TERM HOSPITAL',
            'LONG TERM CARE HOSPITAL',
            'Floor',
            'HEALTHCARE FACILITY',
            'Other Hospital',
            'Step-Down Unit (SDU)',
            'Telemetry',
            'Other Internal'
        ) THEN 'Hospital'

        -- HOME
        WHEN adm.discharge_location IN (
            'HOME',
            'Home',
            'HOME HEALTH CARE',
            'HOME WITH HOME IV PROVIDR'
        ) THEN 'Home'

        -- DEATH
        WHEN adm.discharge_location IN (
            'DIED',
            'death',
            'Death',
            'Overleden',
            'HOSPICE',
            'DEAD/EXPIRED',
            'HOSPICE-HOME',
            'HOSPICE-MEDICAL FACILITY'
        ) THEN 'Death'

        -- OTHER ICU
        WHEN adm.discharge_location IN (
            'ICU',
            'Operating Room',
            'Other ICU',
            'Other ICU (CABG)'
        ) THEN 'Other ICU'

        -- REHABILITATION
        WHEN adm.discharge_location IN (
            'REHAB',
            'Rehabilitation',
            'REHAB/DISTINCT PART HOSP'
        ) THEN 'Rehabilitation'

        -- NURSING FACILITY
        WHEN adm.discharge_location IN (
            'ASSISTED LIVING',
            'SKILLED NURSING FACILITY',
            'SNF',
            'Skilled Nursing Facility',
            'Nursing Home'
        ) THEN 'Nursing Facility'

        -- OTHER
        WHEN adm.discharge_location IN (
            'AGAINST ADVICE',
            'Other',
            'Other External',
            'OTHER FACILITY',
            'PSYCH FACILITY',
            'DISC-TRAN CANCER/CHLDRN H',
            'DISCH-TRAN TO PSYCH HOSP',
            'DISC-TRAN TO FEDERAL HC',
            'SNF-MEDICAID ONLY CERTIF',
            'LEFT AGAINST MEDICAL ADVI',
            'ICF'
        ) THEN 'Other'

        -- UNKNOWN
        WHEN adm.discharge_location IN (
            'unknown','1','2','3','4','5','8','9','10','12','13','14','15','16','17','18','19',
            '20','21','22','23','25','26','27','29','31','32','33','35','36','37','38','40',
            '41','42','44','45','46','47','48','49','50','51'
        ) THEN 'Unknown'

        ELSE 'Other'
    END AS discharge_location,

'admissions'  AS source_table,
'miiv_demo_coh' AS source_dataset

FROM miiv_demo_coh.visit_windows vw
LEFT JOIN miiv_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id;