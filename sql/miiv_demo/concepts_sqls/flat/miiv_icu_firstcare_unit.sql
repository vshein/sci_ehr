-- This is our mapping. We can change it to sci cat instead
DROP TABLE IF EXISTS miiv_demo_coh_concepts.icu_first_careunit;
CREATE TABLE miiv_demo_coh_concepts.icu_first_careunit AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.stay_id,
    ie.first_careunit AS icu_first_careunit_raw,

    CASE
        WHEN ie.first_careunit IS NULL THEN 'Unknown-Not applicable'

        -- MEDICAL
        WHEN ie.first_careunit IN (
            'Medical Intensive Care Unit (MICU)',
            'MICU',
            'Medicine',
            'Intensive Care Volwassenen',
            'Medicine/Cardiology Intermediate'
        ) THEN 'Medical'

        -- CARDIAC
        WHEN ie.first_careunit IN (
            'Cardiac Vascular Intensive Care Unit (CVICU)',
            'Cardiac ICU',
            'Cardiologie',
            'Coronary Care Unit (CCU)',
            'CCU-CTICU',
            'CCU'
        ) THEN 'Cardiac'

        -- MEDICAL-SURGICAL
        WHEN ie.first_careunit IN (
            'Med-Surg ICU',
            'Medical/Surgical Intensive Care Unit (MICU/SICU)',
            'Med/Surg'
        ) THEN 'Medical-Surgical'

        -- SURGICAL
        WHEN ie.first_careunit IN (
            'Surgical Intensive Care Unit (SICU)',
            'SICU',
            'Vaatchirurgie',
            'Cardiochirurgie',
            'CSICU',
            'CTICU',
            'CSRU',
            'Surgery/Trauma',
            'Surgery/Vascular/Intermediate'
        ) THEN 'Surgical'

        -- TRAUMA
        WHEN ie.first_careunit IN (
            'Trauma SICU (TSICU)',
            'Traumatologie',
            'TSICU'
        ) THEN 'Trauma'

        -- GASTRO
        WHEN ie.first_careunit IN (
            'Maag-,Darm-,Leverziekten',
            'Heelkunde Gastro-enterologie'
        ) THEN 'Gastrosurgery'

        -- NEURO
        WHEN ie.first_careunit IN (
            'Neurology',
            'Neuro ICU',
            'Neurologie',
            'Neurochirurgie',
            'Neuro Surgical Intensive Care Unit (Neuro SICU)',
            'Neuro Intermediate',
            'Neuro Stepdown',
            'NICU'
        ) THEN 'Neurological'

        -- OTHER
        WHEN ie.first_careunit IN (
            'Inwendig',
            'Heelkunde Oncologie',
            'Heelkunde Longen/Oncologie',
            'Oncologie Inwendig',
            'Longziekte',
            'Keel, Neus & Oorarts',
            'Orthopedie',
            'Hematologie',
            'Urologie',
            'Nefrologie',
            'Gynaecologie',
            'Plastische chirurgie',
            'ders',
            'PACU',
            'Mondheelkunde',
            'Verloskunde',
            'Obstetrie',
            'Oogheelkunde',
            'Reumatologie',
            'Intensive Care Unit (ICU)'
        ) THEN 'Other'

        ELSE 'Other'
    END AS icu_first_careunit,

'icustays' AS source_table,
'miiv_demo_coh' AS source_dataset

FROM miiv_demo_coh.visit_windows vw

LEFT JOIN miiv_demo_coh.icustays ie
  ON vw.stay_id = ie.stay_id;