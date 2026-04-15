DROP TABLE IF EXISTS miii_demo_coh_concepts.urine;
CREATE TABLE miii_demo_coh_concepts.urine AS
SELECT
    cw.subject_id,
    cw.hadm_id,
    cw.icustay_id,

    adm.admittime,

    src.charttime,

    EXTRACT(EPOCH FROM (src.charttime - adm.admittime))/60 AS offset_min,

    CAST(src.value AS NUMERIC) AS value,

    'mL' AS unit,

    src.value AS value_raw,
    src.valueuom AS unit_raw,

    src.itemid AS source_itemid,

    dict.label AS source_label,

    'outputevents' AS source_table,
    'miii_demo_coh' AS source_dataset

FROM miii_demo_coh.visit_windows cw

JOIN miii_demo_coh.outputevents src
  ON cw.hadm_id = src.hadm_id

JOIN miii_demo_coh.admissions adm
  ON cw.hadm_id = adm.hadm_id

LEFT JOIN miii_demo_coh.d_items dict
  ON src.itemid = dict.itemid

WHERE src.itemid IN (40055|40056|40057|40065|40069|40085|40086|40094|40096|40405|40428|40473|40715|43175|226557|226558|226559|226560|226561|226563|226564|226565|226566|226567|226584|227510)
AND src.value IS NOT NULL
AND src.charttime BETWEEN cw.hospital_start AND cw.hospital_end;
