--  We can change the categories based on SCI standard if needed

DROP TABLE IF EXISTS miii_demo_coh_concepts.race;

CREATE TABLE  miii_demo_coh_concepts.race AS


SELECT
    vw.subject_id,
    vw.hadm_id,
    vw.icustay_id,

    adm.ethnicity AS race_raw,

    -- standardized value
    CASE
        WHEN adm.ethnicity IS NULL THEN 'unknown'

        -- WHITE
        WHEN adm.ethnicity IN (
            'WHITE',
            'WHITE - RUSSIAN',
            'WHITE - OTHER EUROPEAN',
            'WHITE - BRAZILIAN',
            'WHITE - EASTERN EUROPEAN'
        ) THEN 'white'

        -- BLACK
        WHEN adm.ethnicity IN (
            'BLACK/AFRICAN AMERICAN',
            'BLACK/CAPE VERDEAN',
            'BLACK/AFRICAN',
            'CARIBBEAN ISLAND',
            'BLACK/CARIBBEAN ISLAND'
        ) THEN 'black'

        -- HISPANIC
        WHEN adm.ethnicity IN (
            'HISPANIC OR LATINO',
            'HISPANIC/LATINO - PUERTO RICAN',
            'HISPANIC/LATINO - DOMINICAN',
            'HISPANIC/LATINO - GUATEMALAN',
            'HISPANIC/LATINO - CUBAN',
            'HISPANIC/LATINO - SALVADORAN',
            'HISPANIC/LATINO - MEXICAN',
            'HISPANIC/LATINO - HONDURAN',
            'HISPANIC/LATINO - CENTRAL AMERICAN',
            'HISPANIC/LATINO - COLUMBIAN'
        ) THEN 'hispanic'

        -- ASIAN
        WHEN adm.ethnicity IN (
            'ASIAN',
            'ASIAN - CHINESE',
            'ASIAN - ASIAN INDIAN',
            'ASIAN - KOREAN',
            'ASIAN - SOUTH EAST ASIAN'
        ) THEN 'asian'

        -- NATIVE
        WHEN adm.ethnicity IN (
            'AMERICAN INDIAN/ALASKA NATIVE',
            'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER'
        ) THEN 'native'

        -- UNKNOWN
        WHEN adm.ethnicity IN (
            'UNABLE TO OBTAIN',
            'PATIENT DECLINED TO ANSWER',
            'UNKNOWN'
        ) THEN 'unknown'

        -- OTHER
        WHEN adm.ethnicity IN (
            'OTHER',
            'PORTUGUESE',
            'MULTIPLE RACE/ETHNICITY',
            'SOUTH AMERICAN'
        ) THEN 'other'

        ELSE 'other'
    END AS race,

'admissions' AS source_table,
'miii_demo_coh' AS source_dataset

FROM miii_demo_coh.visit_windows vw
LEFT JOIN miii_demo_coh.admissions adm
  ON vw.hadm_id = adm.hadm_id;
