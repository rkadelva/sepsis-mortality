/****************************************************************************************
* Program: 00_run_all.sas
* Purpose: Master runner for the sepsis mortality workflow
*          Calls each SAS step in sequence
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

%let project_root = /workspaces/sepsis-mortality;
%let code_root    = &project_root/code;

%let outyr = 2026;
%let quar = 1;

%include '/data/ops/5/OQS_IPEC/SASINCLUDES/rpt_macrovarsandlibraries.sas';
%include '/data/ops/5/OQS_IPEC/FORMATS/formats.sas';
%include '/data/ops/OQS_IPEC/Programs/sepsismodelwork/modeling/create_sepsis_model_data.sas';
%include "&code_root/01_define_periods.sas";
%define_reporting_periods(outyr=&outyr, quar=&quar);

%include "&code_root/02_create_model_data.sas";
%create_model_data(outyr=&outyr, quar=&quar);

%include "&code_root/04_build_logistic_model.sas";
%include "&code_root/05_run_model_and_predict.sas";

%include "&code_root/02_create_sepsis_cohort.sas";
%include "&code_root/03_merge_model_data.sas";
%include "&code_root/05_predict_current_quarter.sas";
%include "&code_root/06_create_patient_fact.sas";

%create_sepsis_patientlevel(outyr=&outyr,quar=&quar);

proc sort data=sep_data.fact_sepsis_smr_patient_&outyr.Q&quar;
    by id;
run;

data sep_data.SepsisSMR_Drilldown_STG_&outyr.Q&quar;
    set sep_data.fact_sepsis_smr_patient_&outyr.Q&quar;
    by id;

    if first.id;
run;

%include "&code_root/07_create_summary_tables.sas";
%include "&code_root/08a_create_inverse_gamma_lookup.sas";
%include "&code_root/08_export_sql_server.sas";
%include "&code_root/09_quality_checks.sas";

/****************************************************************************************
* Place the real project-specific calls here after the templates are filled in.
* Example:
* %create_sepsis_cohort(in_data=raw.sepsis_source_data, out_data=derived.sepsis_cohort);
* %merge_model_data(cohort_data=derived.sepsis_cohort, model_data=clean.model_inputs, out_data=derived.model_ready_data);
* %build_logistic_model(train_data=derived.model_training_data, outcome=deaddis, predictor_list=..., model_out=derived.sepsis_logit_model, score_data=derived.current_quarter_model_ready);
* %predict_current_quarter(model_score_data=derived.current_quarter_model_ready, model_parms=derived.sepsis_logit_model, out_data=derived.predicted_current_quarter);
* %create_patient_fact(predicted_data=derived.predicted_current_quarter, lookup_data=clean.patient_lookup, out_data=results.patient_fact.sepsis_patient_fact_2026Q1, reporting_period=2026Q1);
* %create_summary_tables(patient_fact=results.patient_fact.sepsis_patient_fact_2026Q1, out_data=results.summary_metrics.sepsis_summary_metrics_2026Q1);
* %quality_checks(patient_fact=results.patient_fact.sepsis_patient_fact_2026Q1, summary_data=results.summary_metrics.sepsis_summary_metrics_2026Q1);
****************************************************************************************/
