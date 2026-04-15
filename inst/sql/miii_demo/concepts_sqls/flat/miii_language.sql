-- This is our mapping. We can change it to sci cat instead
-- mmr this can be modified based on what i did but for now I kept it simple

DROP TABLE IF EXISTS miii_demo_coh_concepts.language;

CREATE TABLE  miii_demo_coh_concepts.language AS

SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.icustay_id,

    adm.language AS language_raw,

      CASE
        WHEN adm.language IS NULL THEN 'unknown'

        -- English
        WHEN adm.language IN (
            'English'
        ) THEN 'English'

        -- Spanish
        WHEN adm.language IN (
            'Spanish'
        ) THEN 'Spanish'

       -- other 
        WHEN adm.language IN (
          'French', 'Italian', 'Russian',  'American Sign Language', 'Amharic', 'Arabic', 'Armenian' , 'Bengali', 'Chinese', 'Haitian', 'Hindi',
          'Japanese', 'Kabuverdianu', 'Khmer', 'Korean', 'Modern Greek (1453-)', 'Persian', 'Polish', 'Portuguese', 'Somali', 'Thai', 'Vietnamese'
        ) THEN 'other'

        -- other
        WHEN adm.language IN (
            'Other', 'OTHER'
        ) THEN 'other'


        ELSE 'other'
    END AS "language",

'admissions' AS source_table,
'miii_demo_coh' AS source_dataset

FROM miii_demo_coh.visit_windows vw
LEFT JOIN miii_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id;
