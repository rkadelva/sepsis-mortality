/****************************************************************************************
* Program: 03_merge_model_data.sas
* Purpose: Merge sepsis cohort with model variables and predictors required for logistic modeling
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

%macro merge_model_data(cohort_data=, model_data=, out_data=);
    %if %superq(cohort_data)= %then %do;
        %put ERROR: COHORT_DATA is required.;
        %return;
    %end;

    %if %superq(model_data)= %then %do;
        %put ERROR: MODEL_DATA is required.;
        %return;
    %end;

    %if %superq(out_data)= %then %do;
        %put ERROR: OUT_DATA is required.;
        %return;
    %end;

    proc sql;
        create table &out_data as
            select a.*,
                   b.*
            from &cohort_data as a
            left join &model_data as b
                on a.encounter_id = b.encounter_id;
    quit;

    %put NOTE: Merged model inputs into &out_data;

%mend merge_model_data;

/****************************************************************************************
* Example usage:
* %merge_model_data(cohort_data=derived.sepsis_cohort, model_data=clean.model_inputs, out_data=derived.model_ready_data);
****************************************************************************************/
