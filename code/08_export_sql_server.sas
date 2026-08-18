/****************************************************************************************
* Program: 08_export_sql_server.sas
* Purpose: Export the patient-level, summary, and lookup datasets to SQL Server staging tables
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

%macro export_sql_server(patient_fact=, summary_data=, sql_lib=, lookup_data=);
    %if %superq(patient_fact)= %then %do;
        %put ERROR: PATIENT_FACT is required.;
        %return;
    %end;

    %if %superq(summary_data)= %then %do;
        %put ERROR: SUMMARY_DATA is required.;
        %return;
    %end;

    %if %superq(sql_lib)= %then %do;
        %put ERROR: SQL_LIB is required.;
        %return;
    %end;

    %put NOTE: Exporting patient fact dataset: &patient_fact;
    %put NOTE: Exporting summary dataset: &summary_data;
    %put NOTE: SQL libref: &sql_lib;

    %if %superq(lookup_data) ne %then %do;
        %put NOTE: Exporting lookup table: &lookup_data;

        proc sql;
            connect to sqlsvr as tunnel (datasrc=IPEC_ReportData &SQL_OPTIMAL.);
            execute(truncate table DBO.SepsisDimInvereGammaLookup_STG) by tunnel;
            disconnect from tunnel;
        quit;

        proc append base=&sql_lib..SepsisDimInvereGammaLookup_STG data=&lookup_data force;
        run;
    %end;

    proc append base=&sql_lib..SepsisSMR_PatientFact_STG data=&patient_fact force;
    run;

    proc append base=&sql_lib..SepsisSMR_Summary_STG data=&summary_data force;
    run;

    %put NOTE: SQL Server export completed for patient fact, summary data, and lookup table.;

%mend export_sql_server;

/****************************************************************************************
* Example usage:
* %export_sql_server(patient_fact=sep_data.fact_sepsis_smr_patient_2026Q1,
*                   summary_data=work.fact_sepsis_smr_summary_all,
*                   sql_lib=IRD_DBO,
*                   lookup_data=sep_data.SepsisDimInvereGammaLookup);
****************************************************************************************/
