\echo ''
\echo '==='
\echo 'Beginning to create materialized views for MIMIC database.'
\echo 'Any notices of the form  "NOTICE: materialized view "XXXXXX" does not exist" can be ignored.'
\echo 'The scripts drop views before creating them, and these notices indicate nothing existed prior to creating the view.'
\echo '==='
\echo ''

-- Set the search_path, i.e. the location at which we generate tables.
-- postgres looks at schemas sequentially, so this will generate tables on the mimiciv_derived schema

-- NOTE: many scripts *require* you to use mimiciv_derived as the schema for outputting concepts
-- change the search path at your peril!

SET search_path TO  miiv_scid_derived, miiv_scid, public;
\! pwd
-- make scid_cohort_visit_windows 
-- \ir preproc/miiv_scid_cohort_visit_windows.sql
-- \ir preproc/fill_hadm_labevents_test.sql 
-- \ir preproc/fill_hadm_lab_test.sql
\ir preproc/eicu_scid_cohort_visit_windows.sql