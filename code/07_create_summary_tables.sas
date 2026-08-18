/****************************************************************************************
* Program: 07_create_summary_tables.sas
* Purpose: Create summary statistics for current quarter and rolling periods
*          including N, ND, unadjusted mortality, expected deaths, SMR, and CI
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

/******************************************************************************************;
* Step 5: Summary Data
******************************************************************************************/
%macro create_sepsis_summary_tables;

    data sepsis_pred_for_powerbi;
        set /* sep_data.fact_sepsis_smr_patient_2024Q2
            sep_data.fact_sepsis_smr_patient_2024Q3
            sep_data.fact_sepsis_smr_patient_2024Q4
            sep_data.fact_sepsis_smr_patient_2025Q1
            sep_data.fact_sepsis_smr_patient_2025Q2
            sep_data.fact_sepsis_smr_patient_2025Q3 */
            sep_data.SepsisSMR_Drilldown_STG_&outyr.Q&quar;

        if rolling6 = 1 then
            time_roll6 = "Rolling 6 Months";

        if rolling12 = 1 then
            time_roll12 = "Rolling 12 Months";

        if rolling24 = 1 then
            time_roll24 = "Rolling 24 Months";

        if quarter = 1 then
            time_quar = ReportingPeriod;

        drop rolling6 rolling12 rolling24 quarter;
    run;

    /* Create summary level data */
    proc sort data=sepsis_pred_for_powerbi;
        by ReportingPeriod id discharge_yr discharge_qtr visn site facility complexity_level_val
           complexity_level losingspec lward dxcat_label
           vasopressor_flag mvent_flag platelets_flag
           lactic_acid_flag cr_flag bili_flag disdate covid n_hosp90d_sepsisadm
           n_obs90d_sepsisadm age_cat married deaddis severity num_acuteorg_dysf unittype p0;
    run;

    /*** wide to long time variable ***/
    proc transpose data=sepsis_pred_for_powerbi out=long_data(rename=(col1=time) drop=_name_);
        by ReportingPeriod id discharge_yr discharge_qtr visn site facility complexity_level_val
           complexity_level losingspec lward dxcat_label
           vasopressor_flag mvent_flag platelets_flag
           lactic_acid_flag cr_flag bili_flag disdate covid n_hosp90d_sepsisadm
           n_obs90d_sepsisadm age_cat married deaddis severity num_acuteorg_dysf unittype p0;

        var time_roll6 time_roll12 time_roll24 time_quar;
    run;

    proc sort data=long_data;
        by ReportingPeriod time id discharge_yr discharge_qtr visn site facility
           complexity_level_val complexity_level deaddis p0;
    run;

    /* Put all categorical variables in long format */
    proc transpose data=long_data out=long_data_p0(
        rename=(col1=groupvar_value _name_=groupvar)
        drop=_label_ col2 col3 col4
    );
        by ReportingPeriod time id discharge_yr discharge_qtr visn site facility
           complexity_level_val complexity_level deaddis p0;

        var losingspec lward dxcat_label age_cat severity Unittype;
    run;

    proc sql;
        select time, ReportingPeriod, groupvar, count(*) as N
        from long_data_p0
        group by time, ReportingPeriod, groupvar;
    quit;

    /* Removing rows with missing values and summarizing */
    proc sql;
        create table work.fact_sepsis_smr_summary as
            select time,
                   case
                       when time = "Rolling 24 Months" then 4
                       when time = "Rolling 12 Months" then 3
                       when time = "Rolling 6 Months" then 2
                       else 1
                   end as time_order,
                   ReportingPeriod,
                   visn,
                   site,
                   facility,
                   complexity_level,
                   groupvar,
                   groupvar_value,
                   count(*) as N,
                   sum(deaddis) as ND,
                   sum(p0) as EXP
            from long_data_p0(where=(time ne ''))
            group by time, ReportingPeriod, visn, site, facility, complexity_level, groupvar, groupvar_value
            order by time, ReportingPeriod, visn, site, facility, complexity_level, groupvar, groupvar_value;
    quit;

    proc sql;
        select time, ReportingPeriod, groupvar, sum(N) as N
        from work.fact_sepsis_smr_summary
        group by time, ReportingPeriod, groupvar;
    quit;

    /*******************************************************;
     ** Step 6: Create Organ Dysfunction summary file **;
     *******************************************************/
    proc sort data=long_data;
        by time ReportingPeriod id discharge_yr discharge_qtr visn site facility
           complexity_level_val complexity_level;
    run;

    /* Put all categorical variables in long format */
    proc transpose data=long_data out=long_data_orgdysf(
        rename=(col1=groupvar_value _name_=groupvar)
        drop=_label_ col2 col3
    );
        by time ReportingPeriod id discharge_yr discharge_qtr visn site facility
           complexity_level_val complexity_level deaddis p0;
        var vasopressor_flag mvent_flag platelets_flag lactic_acid_flag cr_flag bili_flag num_acuteorg_dysf;
    run;

    proc freq data=long_data_orgdysf;
        table time;
    run;

    data long_data_orgdysf_recode;
        length value $25;
        set long_data_orgdysf;

        if time not in ('') and groupvar_value = 1;
        drop groupvar_value;

        if groupvar = 'bili_flag' then
            value = 'Bilirubin';
        else if groupvar = 'cr_flag' then
            value = 'Creatinine';
        else if groupvar = 'lactic_acid_flag' then
            value = 'Lactic Acid';
        else if groupvar = 'platelets_flag' then
            value = 'Platelets';
        else if groupvar = 'mvent_flag' then
            value = 'Mechanical Ventilator';
        else if groupvar = 'vasopressor_flag' then
            value = 'Vasopressor';

        if groupvar ne "num_acuteorg_dysf" then
            groupvar = "Organ_Dysfunc";

        if time = "Rolling 24 Months" then
            time_order = 4;
        else if time = "Rolling 12 Months" then
            time_order = 3;
        else if time = "Rolling 6 Months" then
            time_order = 2;
        else time_order = 1;

        rename value = groupvar_value;
    run;

    proc sql;
        create table work.fact_AcuteOrgan_Dysf_summary as
            select time,
                   time_order,
                   ReportingPeriod,
                   visn,
                   site,
                   facility,
                   complexity_level,
                   groupvar,
                   groupvar_value,
                   count(*) as N,
                   sum(deaddis) as ND,
                   sum(p0) as EXP
            from long_data_orgdysf_recode
            group by time, time_order, ReportingPeriod, visn, site, facility, complexity_level, groupvar, groupvar_value
            order by time, time_order, ReportingPeriod, visn, site, facility, complexity_level, groupvar, groupvar_value;
    quit;

    /* Append organ dysfunction data to other sepsis data */
    data work.fact_sepsis_smr_summary_all;
        set work.fact_sepsis_smr_summary
            work.fact_AcuteOrgan_Dysf_summary;
    run;

%mend create_sepsis_summary_tables;

/****************************************************************************************
* Example usage:
* %create_sepsis_summary_tables;
****************************************************************************************/
