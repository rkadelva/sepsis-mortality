/****************************************************************************************
* Program: 09_quality_checks.sas
* Purpose: Validate patient-level and summary datasets before export and reporting
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

%macro quality_checks(patient_fact=, summary_data=);
    %if %superq(patient_fact)= %then %do;
        %put ERROR: PATIENT_FACT is required.;
        %return;
    %end;

    %if %superq(summary_data)= %then %do;
        %put ERROR: SUMMARY_DATA is required.;
        %return;
    %end;

    proc freq data=&patient_fact;
        tables ReportingPeriod deaddis / missing;
    run;

    proc means data=&patient_fact n nmiss min max;
        var predicted_mortality;
    run;

    proc print data=&summary_data(obs=10);
    run;

    %put NOTE: Quality checks complete for &patient_fact and &summary_data;

%mend quality_checks;

/****************************************************************************************
* Example usage:
* %quality_checks(patient_fact=results.patient_fact.sepsis_patient_fact_2026Q1,
*                 summary_data=results.summary_metrics.sepsis_summary_metrics_2026Q1);
****************************************************************************************/
