/****************************************************************************************
* Program: 02_create_sepsis_cohort.sas
* Purpose: Create the analytic sepsis cohort from the source cohort logic provided elsewhere
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

%macro create_sepsis_cohort(in_data=, out_data=);
    %if %superq(in_data)= %then %do;
        %put ERROR: IN_DATA is required.;
        %return;
    %end;

    %if %superq(out_data)= %then %do;
        %put ERROR: OUT_DATA is required.;
        %return;
    %end;

    /* Placeholder structure for the cohort build. Replace with actual logic from the colleague's cohort code. */
    data &out_data;
        set &in_data;

        /* Example cohort variables */
        sepsis_flag = 1;
        cohort_status = 'Eligible';

        /* Add real inclusion/exclusion filters here */
        /* if ... then delete; */
    run;

    %put NOTE: Created sepsis cohort dataset: &out_data;

%mend create_sepsis_cohort;

/****************************************************************************************
* Example usage:
* %create_sepsis_cohort(in_data=raw.sepsis_source, out_data=derived.sepsis_cohort);
****************************************************************************************/
