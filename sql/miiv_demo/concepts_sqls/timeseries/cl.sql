DROP TABLE IF EXISTS miiv_demo_coh_concepts.cl;
CREATE TABLE miiv_demo_coh_concepts.cl AS
SELECT
    cw.subject_id,
    cw.hadm_id,
    cw.stay_id,

    adm.admittime,

    src.charttime,

    EXTRACT(EPOCH FROM (src.charttime - adm.admittime))/60 AS offset_min,

    CAST(src.valuenum AS NUMERIC) AS value,

    'mEq/L' AS unit,

    src.valuenum AS value_raw,
    src.valueuom AS unit_raw,

    src.itemid AS source_itemid,

    dict.label AS source_label,

    'labevents' AS source_table,
    'miiv_demo_coh' AS source_dataset

FROM miiv_demo_coh.visit_windows cw

JOIN miiv_demo_coh.labevents src
  ON cw.hadm_id = src.hadm_id

JOIN miiv_demo_coh.admissions adm
  ON cw.hadm_id = adm.hadm_id

LEFT JOIN miiv_demo_coh.d_labitems dict
  ON src.itemid = dict.itemid

WHERE src.itemid IN (50902|52535)
AND src.valuenum IS NOT NULL
AND src.charttime BETWEEN cw.hospital_start AND cw.hospital_end;
