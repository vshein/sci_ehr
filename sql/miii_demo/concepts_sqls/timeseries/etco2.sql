DROP TABLE IF EXISTS miii_demo_coh_concepts.etco2;
CREATE TABLE miii_demo_coh_concepts.etco2 AS
SELECT
    cw.subject_id,
    cw.hadm_id,
    cw.icustay_id,

    adm.admittime,

    src.charttime,

    EXTRACT(EPOCH FROM (src.charttime - adm.admittime))/60 AS offset_min,

    CAST(src.valuenum AS NUMERIC) AS value,

    'mmHg' AS unit,

    src.valuenum AS value_raw,
    src.valueuom AS unit_raw,

    src.itemid AS source_itemid,

    dict.label AS source_label,

    'chartevents' AS source_table,
    'miii_demo_coh' AS source_dataset

FROM miii_demo_coh.visit_windows cw

JOIN miii_demo_coh.chartevents src
  ON cw.hadm_id = src.hadm_id

JOIN miii_demo_coh.admissions adm
  ON cw.hadm_id = adm.hadm_id

LEFT JOIN miii_demo_coh.d_items dict
  ON src.itemid = dict.itemid

WHERE src.itemid IN (1817|228640)
AND src.valuenum IS NOT NULL
AND src.charttime BETWEEN cw.hospital_start AND cw.hospital_end;
