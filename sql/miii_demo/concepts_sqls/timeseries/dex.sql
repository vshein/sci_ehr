DROP TABLE IF EXISTS miii_demo_coh_concepts.dex;
CREATE TABLE miii_demo_coh_concepts.dex AS
SELECT
    cw.subject_id,
    cw.hadm_id,
    cw.icustay_id,

    adm.admittime,

    src.charttime,

    EXTRACT(EPOCH FROM (src.charttime - adm.admittime))/60 AS offset_min,

    CAST(src.amount AS NUMERIC) AS value,

    'ml/hr' AS unit,

    src.amount AS value_raw,
    src.amountuom AS unit_raw,

    src.itemid AS source_itemid,

    dict.label AS source_label,

    'inputevents_cv' AS source_table,
    'miii_demo_coh' AS source_dataset

FROM miii_demo_coh.visit_windows cw

JOIN miii_demo_coh.inputevents_cv src
  ON cw.hadm_id = src.hadm_id

JOIN miii_demo_coh.admissions adm
  ON cw.hadm_id = adm.hadm_id

LEFT JOIN miii_demo_coh.d_items dict
  ON src.itemid = dict.itemid

WHERE src.itemid IN (30016|30017)
AND src.amount IS NOT NULL
AND src.charttime BETWEEN cw.hospital_start AND cw.hospital_end
UNION ALL
SELECT
    cw.subject_id,
    cw.hadm_id,
    cw.icustay_id,

    adm.admittime,

    src.starttime,

    EXTRACT(EPOCH FROM (src.starttime - adm.admittime))/60 AS offset_min,

    CAST(src.amount AS NUMERIC) AS value,

    'ml/hr' AS unit,

    src.amount AS value_raw,
    src.amountuom AS unit_raw,

    src.itemid AS source_itemid,

    dict.label AS source_label,

    'inputevents_mv' AS source_table,
    'miii_demo_coh' AS source_dataset

FROM miii_demo_coh.visit_windows cw

JOIN miii_demo_coh.inputevents_mv src
  ON cw.hadm_id = src.hadm_id

JOIN miii_demo_coh.admissions adm
  ON cw.hadm_id = adm.hadm_id

LEFT JOIN miii_demo_coh.d_items dict
  ON src.itemid = dict.itemid

WHERE src.itemid IN (220950|228140|220952)
AND src.amount IS NOT NULL
AND src.starttime BETWEEN cw.hospital_start AND cw.hospital_end;
