DROP TABLE IF EXISTS miiv_demo_coh_concepts.admission_location;

CREATE TABLE miiv_demo_coh_concepts.admission_location AS


SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.stay_id,

    adm.admission_location AS admission_location_raw,

    CASE
        WHEN adm.admission_location IS NULL THEN 'Unknown'

        -- OTHER ICU
        WHEN adm.admission_location IN (
            'ICU',
            'Other ICU',
            'CCU/IC of the same hospital',
            'CCU/IC from other hospital'
        ) THEN 'Other ICU'

        -- EMERGENCY
        WHEN adm.admission_location IN (
            'EMERGENCY ROOM',
            'Emergency Department',
            'emergency department of the same hospital',
            'emergency department from other hospital',
            'EMERGENCY ROOM ADMIT'
        ) THEN 'Emergency'

        -- DIRECT ADMIT
        WHEN adm.admission_location IN (
            'WALK-IN/SELF REFERRAL',
            'Direct Admit',
            'Home'
        ) THEN 'Direct Admit'

        -- OPERATING ROOM
        WHEN adm.admission_location IN (
            'PROCEDURE SITE',
            'AMBULATORY SURGERY TRANSFER',
            'Operating Room',
            'operating room from nuring ward of the same hospital',
            'operating room from emergency department of the same hospital',
            'PACU'
        ) THEN 'Operating Room'

        -- UNKNOWN
        WHEN adm.admission_location IN (
            'INFORMATION NOT AVAILABLE',
            '** INFO NOT AVAILABLE **',
            'Unknown',
            'unknown'
        ) THEN 'Unknown'

        -- OTHER
        WHEN adm.admission_location IN (
            'PHYSICIAN REFERRAL',
            'TRANSFER FROM HOSPITAL',
            'TRANSFER FROM HOSP/EXTRAM',
            'TRANSFER FROM SKILLED NUR',
            'TRANSFER FROM OTHER HEALT',
            'CLINIC REFERRAL',
            'HMO REFERRAL/SICK',
            'TRSF WITHIN THIS FACILITY',
            'CLINIC REFERRAL/PREMATURE',
            'PHYS REFERRAL/NORMAL DELI',
            'TRANSFER FROM SKILLED NURSING FACILITY',
            'INTERNAL TRANSFER TO OR FROM PSYCH',
            'Floor',
            'Recovery Room',
            'Step-Down Unit (SDU)',
            'Other Hospital',
            'Acute Care/Floor',
            'Chest Pain Center',
            'ICU to SDU',
            'Observation',
            'nursing department of the same hospital',
            'special/medium care from the same hospital',
            'recovery from the same hospital (only in case of unplanned IC admission)',
            'nursing department from other hospital',
            'special/medium care from other hospital',
            'recovery from other hospital',
            'Other',
            'different location of the same hospital, transport by ambulance'
        ) THEN 'Other'

        ELSE 'Other'
    END AS admission_location,

'admissions'  AS source_table,
'miiv_demo_coh' AS source_dataset

FROM miiv_demo_coh.visit_windows vw
LEFT JOIN miiv_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id;
