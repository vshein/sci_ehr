-------------------------------------------
-- Create the tables and miiv_demo_coh schema --
-------------------------------------------

----------------------
-- Creating schemas --
----------------------

DROP SCHEMA IF EXISTS miiv_demo_coh CASCADE;
CREATE SCHEMA miiv_demo_coh;
DROP SCHEMA IF EXISTS miiv_demo_coh CASCADE;
CREATE SCHEMA miiv_demo_coh;
DROP SCHEMA IF EXISTS miiv_demo_coh_concepts CASCADE;
CREATE SCHEMA miiv_demo_coh_concepts;

---------------------
-- Creating tables --
---------------------

-- hosp schema

DROP TABLE IF EXISTS miiv_demo_coh.admissions;
CREATE TABLE miiv_demo_coh.admissions
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  admittime TIMESTAMP NOT NULL,
  dischtime TIMESTAMP,
  deathtime TIMESTAMP,
  admission_type VARCHAR(40) NOT NULL,
  admit_provider_id VARCHAR(10),
  admission_location VARCHAR(60),
  discharge_location VARCHAR(60),
  insurance VARCHAR(255),
  language VARCHAR(25),
  marital_status VARCHAR(30),
  race VARCHAR(80),
  edregtime TIMESTAMP,
  edouttime TIMESTAMP,
  hospital_expire_flag SMALLINT
);

DROP TABLE IF EXISTS miiv_demo_coh.d_hcpcs;
CREATE TABLE miiv_demo_coh.d_hcpcs
(
  code CHAR(5) NOT NULL,
  category SMALLINT,
  long_description TEXT,
  short_description VARCHAR(180)
);

DROP TABLE IF EXISTS miiv_demo_coh.diagnoses_icd;
CREATE TABLE miiv_demo_coh.diagnoses_icd
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  seq_num INTEGER NOT NULL,
  icd_code CHAR(7),
  icd_version SMALLINT
);

DROP TABLE IF EXISTS miiv_demo_coh.d_icd_diagnoses;
CREATE TABLE miiv_demo_coh.d_icd_diagnoses
(
  icd_code CHAR(7) NOT NULL,
  icd_version SMALLINT NOT NULL,
  long_title VARCHAR(255)
);

DROP TABLE IF EXISTS miiv_demo_coh.d_icd_procedures;
CREATE TABLE miiv_demo_coh.d_icd_procedures
(
  icd_code CHAR(7) NOT NULL,
  icd_version SMALLINT NOT NULL,
  long_title VARCHAR(222)
);

DROP TABLE IF EXISTS miiv_demo_coh.d_labitems;
CREATE TABLE miiv_demo_coh.d_labitems
(
  itemid INTEGER NOT NULL,
  label VARCHAR(50),
  fluid VARCHAR(50),
  category VARCHAR(50)
);

DROP TABLE IF EXISTS miiv_demo_coh.drgcodes;
CREATE TABLE miiv_demo_coh.drgcodes
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  drg_type VARCHAR(4),
  drg_code VARCHAR(10) NOT NULL,
  description VARCHAR(195),
  drg_severity SMALLINT,
  drg_mortality SMALLINT
);

DROP TABLE IF EXISTS miiv_demo_coh.emar_detail;
CREATE TABLE miiv_demo_coh.emar_detail
(
  subject_id INTEGER NOT NULL,
  emar_id VARCHAR(25) NOT NULL,
  emar_seq INTEGER NOT NULL,
  parent_field_ordinal VARCHAR(10),
  administration_type VARCHAR(50),
  pharmacy_id INTEGER,
  barcode_type VARCHAR(4),
  reason_for_no_barcode TEXT,
  complete_dose_not_given VARCHAR(5),
  dose_due VARCHAR(100),
  dose_due_unit VARCHAR(50),
  dose_given VARCHAR(255),
  dose_given_unit VARCHAR(50),
  will_remainder_of_dose_be_given VARCHAR(5),
  product_amount_given VARCHAR(30),
  product_unit VARCHAR(30),
  product_code VARCHAR(30),
  product_description VARCHAR(255),
  product_description_other VARCHAR(255),
  prior_infusion_rate VARCHAR(40),
  infusion_rate VARCHAR(40),
  infusion_rate_adjustment VARCHAR(50),
  infusion_rate_adjustment_amount VARCHAR(30),
  infusion_rate_unit VARCHAR(30),
  route VARCHAR(10),
  infusion_complete VARCHAR(1),
  completion_interval VARCHAR(50),
  new_iv_bag_hung VARCHAR(1),
  continued_infusion_in_other_location VARCHAR(1),
  restart_interval VARCHAR(2305),
  side VARCHAR(10),
  site VARCHAR(255),
  non_formulary_visual_verification VARCHAR(1)
);

DROP TABLE IF EXISTS miiv_demo_coh.emar;
CREATE TABLE miiv_demo_coh.emar
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER,
  emar_id VARCHAR(25) NOT NULL,
  emar_seq INTEGER NOT NULL,
  poe_id VARCHAR(25) NOT NULL,
  pharmacy_id INTEGER,
  enter_provider_id VARCHAR(10),
  charttime TIMESTAMP NOT NULL,
  medication TEXT,
  event_txt VARCHAR(100),
  scheduletime TIMESTAMP,
  storetime TIMESTAMP NOT NULL
);

DROP TABLE IF EXISTS miiv_demo_coh.hcpcsevents;
CREATE TABLE miiv_demo_coh.hcpcsevents
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  chartdate DATE,
  hcpcs_cd CHAR(5) NOT NULL,
  seq_num INTEGER NOT NULL,
  short_description VARCHAR(180)
);

DROP TABLE IF EXISTS miiv_demo_coh.labevents;
CREATE TABLE miiv_demo_coh.labevents
(
  labevent_id INTEGER NOT NULL,
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER,
  specimen_id INTEGER NOT NULL,
  itemid INTEGER NOT NULL,
  order_provider_id VARCHAR(10),
  charttime TIMESTAMP(0),
  storetime TIMESTAMP(0),
  value VARCHAR(200),
  valuenum DOUBLE PRECISION,
  valueuom VARCHAR(20),
  ref_range_lower DOUBLE PRECISION,
  ref_range_upper DOUBLE PRECISION,
  flag VARCHAR(10),
  priority VARCHAR(7),
  comments TEXT
);

DROP TABLE IF EXISTS miiv_demo_coh.microbiologyevents;
CREATE TABLE miiv_demo_coh.microbiologyevents
(
  microevent_id INTEGER NOT NULL,
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER,
  micro_specimen_id INTEGER NOT NULL,
  order_provider_id VARCHAR(10),
  chartdate TIMESTAMP(0) NOT NULL,
  charttime TIMESTAMP(0),
  spec_itemid INTEGER NOT NULL,
  spec_type_desc VARCHAR(100) NOT NULL,
  test_seq INTEGER NOT NULL,
  storedate TIMESTAMP(0),
  storetime TIMESTAMP(0),
  test_itemid INTEGER,
  test_name VARCHAR(100),
  org_itemid INTEGER,
  org_name VARCHAR(100),
  isolate_num SMALLINT,
  quantity VARCHAR(50),
  ab_itemid INTEGER,
  ab_name VARCHAR(30),
  dilution_text VARCHAR(10),
  dilution_comparison VARCHAR(20),
  dilution_value DOUBLE PRECISION,
  interpretation VARCHAR(5),
  comments TEXT
);

DROP TABLE IF EXISTS miiv_demo_coh.omr;
CREATE TABLE miiv_demo_coh.omr
(
  subject_id INTEGER NOT NULL,
  chartdate DATE NOT NULL,
  seq_num INTEGER NOT NULL,
  result_name VARCHAR(100) NOT NULL,
  result_value TEXT NOT NULL
);

DROP TABLE IF EXISTS miiv_demo_coh.patients;
CREATE TABLE miiv_demo_coh.patients
(
  subject_id INTEGER NOT NULL,
  gender CHAR(1) NOT NULL,
  anchor_age SMALLINT,
  anchor_year SMALLINT NOT NULL,
  anchor_year_group VARCHAR(20) NOT NULL,
  dod DATE
);

DROP TABLE IF EXISTS miiv_demo_coh.pharmacy;
CREATE TABLE miiv_demo_coh.pharmacy
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  pharmacy_id INTEGER NOT NULL,
  poe_id VARCHAR(25),
  starttime TIMESTAMP(3),
  stoptime TIMESTAMP(3),
  medication TEXT,
  proc_type VARCHAR(50) NOT NULL,
  status VARCHAR(50),
  entertime TIMESTAMP(3) NOT NULL,
  verifiedtime TIMESTAMP(3),
  route VARCHAR(50),
  frequency VARCHAR(50),
  disp_sched VARCHAR(255),
  infusion_type VARCHAR(15),
  sliding_scale VARCHAR(1),
  lockout_interval VARCHAR(50),
  basal_rate REAL,
  one_hr_max VARCHAR(10),
  doses_per_24_hrs REAL,
  duration REAL,
  duration_interval VARCHAR(50),
  expiration_value INTEGER,
  expiration_unit VARCHAR(50),
  expirationdate TIMESTAMP(3),
  dispensation VARCHAR(50),
  fill_quantity VARCHAR(50)
);

DROP TABLE IF EXISTS miiv_demo_coh.poe_detail;
CREATE TABLE miiv_demo_coh.poe_detail
(
  poe_id VARCHAR(25) NOT NULL,
  poe_seq INTEGER NOT NULL,
  subject_id INTEGER NOT NULL,
  field_name VARCHAR(255) NOT NULL,
  field_value TEXT
);

DROP TABLE IF EXISTS miiv_demo_coh.poe;
CREATE TABLE miiv_demo_coh.poe
(
  poe_id VARCHAR(25) NOT NULL,
  poe_seq INTEGER NOT NULL,
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER,
  ordertime TIMESTAMP(0) NOT NULL,
  order_type VARCHAR(25) NOT NULL,
  order_subtype VARCHAR(50),
  transaction_type VARCHAR(15),
  discontinue_of_poe_id VARCHAR(25),
  discontinued_by_poe_id VARCHAR(25),
  order_provider_id VARCHAR(10),
  order_status VARCHAR(15)
);

DROP TABLE IF EXISTS miiv_demo_coh.prescriptions;
CREATE TABLE miiv_demo_coh.prescriptions
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  pharmacy_id INTEGER NOT NULL,
  poe_id VARCHAR(25),
  poe_seq INTEGER,
  order_provider_id VARCHAR(10),
  starttime TIMESTAMP(3),
  stoptime TIMESTAMP(3),
  drug_type VARCHAR(20) NOT NULL,
  drug VARCHAR(255) NOT NULL,
  formulary_drug_cd VARCHAR(50),
  gsn VARCHAR(255),
  ndc VARCHAR(25),
  prod_strength VARCHAR(255),
  form_rx VARCHAR(25),
  dose_val_rx VARCHAR(100),
  dose_unit_rx VARCHAR(50),
  form_val_disp VARCHAR(50),
  form_unit_disp VARCHAR(50),
  doses_per_24_hrs REAL,
  route VARCHAR(50)
);

DROP TABLE IF EXISTS miiv_demo_coh.procedures_icd;
CREATE TABLE miiv_demo_coh.procedures_icd
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  seq_num INTEGER NOT NULL,
  chartdate DATE NOT NULL,
  icd_code VARCHAR(7),
  icd_version SMALLINT
);

DROP TABLE IF EXISTS miiv_demo_coh.provider;
CREATE TABLE miiv_demo_coh.provider
(
  provider_id VARCHAR(10) NOT NULL
);

DROP TABLE IF EXISTS miiv_demo_coh.services;
CREATE TABLE miiv_demo_coh.services
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  transfertime TIMESTAMP NOT NULL,
  prev_service VARCHAR(10),
  curr_service VARCHAR(10)
);

DROP TABLE IF EXISTS miiv_demo_coh.transfers;
CREATE TABLE miiv_demo_coh.transfers
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER,
  transfer_id INTEGER NOT NULL,
  eventtype VARCHAR(10),
  careunit VARCHAR(255),
  intime TIMESTAMP,
  outtime TIMESTAMP
);

-- icu schema

DROP TABLE IF EXISTS miiv_demo_coh.caregiver;
CREATE TABLE miiv_demo_coh.caregiver
(
  caregiver_id INTEGER NOT NULL
);

DROP TABLE IF EXISTS miiv_demo_coh.chartevents;
CREATE TABLE miiv_demo_coh.chartevents
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  stay_id INTEGER NOT NULL,
  caregiver_id INTEGER,
  charttime TIMESTAMP NOT NULL,
  storetime TIMESTAMP,
  itemid INTEGER NOT NULL,
  value VARCHAR(200),
  valuenum FLOAT,
  valueuom VARCHAR(20),
  warning SMALLINT
);

DROP TABLE IF EXISTS miiv_demo_coh.datetimeevents;
CREATE TABLE miiv_demo_coh.datetimeevents
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  stay_id INTEGER NOT NULL,
  caregiver_id INTEGER,
  charttime TIMESTAMP NOT NULL,
  storetime TIMESTAMP,
  itemid INTEGER NOT NULL,
  value TIMESTAMP NOT NULL,
  valueuom VARCHAR(20),
  warning SMALLINT
);

DROP TABLE IF EXISTS miiv_demo_coh.d_items;
CREATE TABLE miiv_demo_coh.d_items
(
  itemid INTEGER NOT NULL,
  label VARCHAR(100) NOT NULL,
  abbreviation VARCHAR(50) NOT NULL,
  linksto VARCHAR(30) NOT NULL,
  category VARCHAR(50) NOT NULL,
  unitname VARCHAR(50),
  param_type VARCHAR(20) NOT NULL,
  lownormalvalue FLOAT,
  highnormalvalue FLOAT
);

DROP TABLE IF EXISTS miiv_demo_coh.icustays;
CREATE TABLE miiv_demo_coh.icustays
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  stay_id INTEGER NOT NULL,
  first_careunit VARCHAR(255),
  last_careunit VARCHAR(255),
  intime TIMESTAMP,
  outtime TIMESTAMP,
  los FLOAT
);

DROP TABLE IF EXISTS miiv_demo_coh.ingredientevents;
CREATE TABLE miiv_demo_coh.ingredientevents
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  stay_id INTEGER,
  caregiver_id INTEGER,
  starttime TIMESTAMP NOT NULL,
  endtime TIMESTAMP NOT NULL,
  storetime TIMESTAMP,
  itemid INTEGER NOT NULL,
  amount FLOAT,
  amountuom VARCHAR(20),
  rate FLOAT,
  rateuom VARCHAR(20),
  orderid INTEGER NOT NULL,
  linkorderid INTEGER,
  statusdescription VARCHAR(20),
  originalamount FLOAT,
  originalrate FLOAT
);

DROP TABLE IF EXISTS miiv_demo_coh.inputevents;
CREATE TABLE miiv_demo_coh.inputevents
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  stay_id INTEGER,
  caregiver_id INTEGER,
  starttime TIMESTAMP NOT NULL,
  endtime TIMESTAMP NOT NULL,
  storetime TIMESTAMP,
  itemid INTEGER NOT NULL,
  amount FLOAT,
  amountuom VARCHAR(20),
  rate FLOAT,
  rateuom VARCHAR(20),
  orderid INTEGER NOT NULL,
  linkorderid INTEGER,
  ordercategoryname VARCHAR(50),
  secondaryordercategoryname VARCHAR(50),
  ordercomponenttypedescription VARCHAR(100),
  ordercategorydescription VARCHAR(30),
  patientweight FLOAT,
  totalamount FLOAT,
  totalamountuom VARCHAR(50),
  isopenbag SMALLINT,
  continueinnextdept SMALLINT,
  statusdescription VARCHAR(20),
  originalamount FLOAT,
  originalrate FLOAT
);

DROP TABLE IF EXISTS miiv_demo_coh.outputevents;
CREATE TABLE miiv_demo_coh.outputevents
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  stay_id INTEGER NOT NULL,
  caregiver_id INTEGER,
  charttime TIMESTAMP(3) NOT NULL,
  storetime TIMESTAMP(3) NOT NULL,
  itemid INTEGER NOT NULL,
  value FLOAT NOT NULL,
  valueuom VARCHAR(20)
);

DROP TABLE IF EXISTS miiv_demo_coh.procedureevents;
CREATE TABLE miiv_demo_coh.procedureevents
(
  subject_id INTEGER NOT NULL,
  hadm_id INTEGER NOT NULL,
  stay_id INTEGER NOT NULL,
  caregiver_id INTEGER,
  starttime TIMESTAMP NOT NULL,
  endtime TIMESTAMP NOT NULL,
  storetime TIMESTAMP NOT NULL,
  itemid INTEGER NOT NULL,
  value FLOAT,
  valueuom VARCHAR(20),
  location VARCHAR(100),
  locationcategory VARCHAR(50),
  orderid INTEGER,
  linkorderid INTEGER,
  ordercategoryname VARCHAR(50),
  ordercategorydescription VARCHAR(30),
  patientweight FLOAT,
  isopenbag SMALLINT,
  continueinnextdept SMALLINT,
  statusdescription VARCHAR(20),
  originalamount FLOAT,
  originalrate FLOAT
);