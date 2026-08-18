/*==============================================================================
Macro: %append_last8
Purpose: Append the most recent 8 quarter datasets (including rptqtr)
       from a library, where dataset names follow: &prefix.&sep.YYYYQn
Author: Kadel, Rajendra P. (for demonstration by M365 Copilot)
==============================================================================*/
%macro append_last8(
            lib=work           /* Library where quarterly datasets live              */
            , prefix=            /* Common dataset prefix (e.g., sales, claims)        */
            , rptqtr=            /* Reporting quarter in form YYYYQn (e.g., 2026Q1)    */
            , out=               /* Output dataset name (default auto-built below)     */
            , sep=_              /* Separator between prefix and quarter ('' or '_')   */
            , debug=0            /* 1 to print verbose info, else 0                    */
            );
    %local _rpt year qtr baseline rpt_date i qdate qi_year qi_qtr qi memname dslist nfound;

    %if %superq(prefix)= %then
        %do;
            %put ERROR: Parameter PREFIX is required (e.g., sales, claims).;
            %return;
        %end;

    %if %superq(rptqtr)= %then
        %do;
            %put ERROR: Parameter RPTQTR is required (e.g., 2026Q1).;
            %return;
        %end;

    %if %sysfunc(libref(&lib)) ne 0 %then
        %do;
            %put ERROR: Libref &lib is not assigned. Use LIBNAME to assign first.;
            %return;
        %end;

    %let _rpt=%sysfunc(upcase(%superq(rptqtr)));

    %if %sysfunc(prxmatch(/^\d{4}Q[1-4]$/, &_rpt))=0 %then
        %do;
            %put ERROR: RPTQTR must be in form YYYYQn (e.g., 2026Q1 or 2025Q4).;
            %return;
        %end;

    %if %superq(out)= %then
        %do;
            %let out=&lib..%sysfunc(cats(&prefix,&sep,last8_,&_rpt));
        %end;

    %let year=%substr(&_rpt,1,4);
    %let qtr=%substr(&_rpt,6,1);

    %let baseline=%sysfunc(mdy(1,1,&year));
    %let rpt_date=%sysfunc(intnx(qtr,&baseline,%eval(&qtr-1),B));
    %let dslist=;
    %let nfound=0;

    %do i=0 %to 7;
        %let qdate = %sysfunc(intnx(qtr,&rpt_date,-&i,B));
        %let qi_year = %sysfunc(year(&qdate));
        %let qi_qtr = %sysfunc(qtr(&qdate));
        %let qi = %sysfunc(cats(&qi_year,Q,&qi_qtr));
        %let memname = %sysfunc(cats(&prefix,&sep,&qi));

        %if &debug %then
            %put DEBUG: Checking &lib..&memname;

        %if %sysfunc(exist(&lib..&memname)) %then
            %do;
                %let dslist = &dslist &lib..&memname;
                %let nfound = %eval(&nfound+1);

                %if &debug %then
                    %put DEBUG: Found &lib..&memname;
            %end;
        %else
            %do;
                %put NOTE: Dataset &lib..&memname not found;
            %end;
        %end;
    %end;

    %if &nfound=0 %then
        %do;
            %put ERROR: None of the last 8 quarter datasets were found. Nothing to append.;
            %return;
        %end;

    %if &debug %then
        %put DEBUG: Appending &nfound dataset(s): &dslist;

    data &out;
        set &dslist;
    run;

    %put NOTE: Created &out with &nfound dataset(s) appended: &dslist;
%mend append_last8;

/******************************************************************************************;
* Step 2: Create Rolling variables rolling 24, rolling 12, rolling6 months and current quarter data
******************************************************************************************;

** The following Macro will create Summary Data **
** that will be used for powerbi report **********;
%macro create_sepsis_patientlevel(outyr,quar);
    %let Reporting_Period = %sysfunc(catx(%str(Q), &outyr, &quar));
    %put &Reporting_Period;

    %append_last8(lib=sep_data, prefix=sepsissmrreportfile, rptqtr=&Reporting_Period, out=work.sepsisreportfile_rolling8);

    proc freq data=work.sepsisreportfile_rolling8;
        table discharge_yr*discharge_qtr;
    run;

    data _null_;
        call symputx('yyyy4', &outyr);
        call symputx('yyyy3', &outyr-1);
        call symputx('yyyy2', &outyr-2);
        call symputx('yyyy1', &outyr-3);
        call symputx('yy4', substr("&outyr",3,2));
        call symputx('yy3', substr("%eval(&outyr-1)",3,2));
        call symputx('yy2', substr("%eval(&outyr-2)",3,2));
        call symputx('yy1', substr("%eval(&outyr-3)",3,2));
        call symputx('byr', substr("%eval(&outyr-1)",3,2));
        call symputx('byrs', "%eval(&outyr-3)" || '-' || substr("%eval(&outyr-1)",3,2));
        call symputx('gyear', &outyr);
        call symputx('byear', &outyr-1);
        call symputx('gyr', substr("&outyr",3,2));
        call symputx('yrpath', &outyr || '_Q' || strip(&quar));
    run;

    %let rptdsn = work.sepsisreportfile_rolling8;

    data sepsissmr_for_powerbi;
        set &rptdsn (rename=(discharge_yr=y discharge_qtr=q));
        length time_roll6 time_roll12 time_roll24 time_quar $6;

        if &quar = 1 then do;
            if (y = &yyyy3 and q in (4)) or (y = &yyyy4 and q in (1)) then
                time_roll6 = '_6';

            if (y = &yyyy3 and q in (2,3,4)) or (y = &yyyy4 and q in (1)) then
                time_roll12 = '_12';

            if (y = &yyyy2 and q in (2,3,4)) or y = &yyyy3 or (y = &yyyy4 and q in (1)) then
                time_roll24 = '_24';
        end;

        if &quar = 2 then do;
            if (y = &yyyy4 and q in (1,2)) then
                time_roll6 = '_6';

            if (y = &yyyy3 and q in (3,4)) or (y = &yyyy4 and q in (1,2)) then
                time_roll12 = '_12';

            if (y = &yyyy2 and q in (3,4)) or y = &yyyy3 or (y = &yyyy4 and q in (1,2)) then
                time_roll24 = '_24';
        end;

        if &quar = 3 then do;
            if (y = &yyyy4 and q in (2,3)) then
                time_roll6 = '_6';

            if (y = &yyyy3 and q in (4)) or (y = &yyyy4 and q in (1,2,3)) then
                time_roll12 = '_12';

            if (y = &yyyy2 and q in (4)) or y = &yyyy3 or (y = &yyyy4 and q in (1,2,3)) then
                time_roll24 = '_24';
        end;

        if &quar = 4 then do;
            if (y = &yyyy4 and q in (3,4)) then
                time_roll6 = '_6';

            if y = &yyyy4 and q in (1,2,3,4) then
                time_roll12 = '_12';

            if (y = &yyyy3 and q in (1,2,3,4)) or (y = &yyyy4 and q in (1,2,3,4)) then
                time_roll24 = '_24';
        end;

        if y = &outyr and q = &quar then
            time_quar = "&outyr.Q&quar";

        rename y=discharge_yr q=discharge_qtr;
    run;

    data work.sepsissmr_for_powerbi_update;
        retain id ReportingPeriod;
        set sepsissmr_for_powerbi;

        if time_roll6 = '_6' then
            rolling6 = 1;
        else rolling6 = 0;

        if time_roll12 = '_12' then
            rolling12 = 1;
        else rolling12 = 0;

        if time_roll24 = '_24' then
            rolling24 = 1;
        else rolling24 = 0;

        if time_quar ne '' then
            quarter = 1;
        else quarter = 0;

        drop time_quar time_roll12 time_roll6 time_roll24;

        ReportingPeriod = "&Reporting_Period";
    run;

    proc sql;
        create table sep_data.fact_sepsis_smr_patient_&Reporting_Period as
            select
                ReportingPeriod,
                a.id2,
                b.id,
                c.ssn format=$10.,
                c.patientname,
                a.discharge_yr,
                a.discharge_qtr,
                a.visn,
                a.site,
                put(a.site, $site_fmt.) as facility,
                a.UNITSPEC_RPT,
                a.admdate as Hospital_Admission,
                a.uedatein as Unit_Admission,
                a.uddatein as UnitDischarge,
                a.disdate as Hospital_Discharge,
                a.disdate,
                a.deathdate as DeathDate,
                put(b.dxgrpst, $dx.) as DiagnosticGroup,
                b.DXEXCL as DiagnosticICD,
                put(b.dxcat, $dxcat.) as DiagnosticName,
                put(b.dxcat, $dxcat.) as dxcat_label,
                a.vasopressor_flag,
                a.mvent_flag,
                a.lactic_acid_flag,
                a.cr_flag,
                a.bili_flag,
                a.platelets_flag,
                a.n_hosp90d_sepsisadm,
                a.n_obs90d_sepsisadm,
                a.p0_group,
                a.deaddis,
                a.p0,
                a.losingspec,
                a.lward,
                a.complexity_level as complexity_level_val,
                put(a.complexity_level, $compl.) as complexity_level,
                put(a.p0_group, sev.) as severity,
                a.deaddis,
                a.p0,
                c.type as Unittype,
                case
                    when (a.vasopressor_flag + a.mvent_flag + a.platelets_flag + a.lactic_acid_flag + a.cr_flag + a.bili_flag) = 1 then 'One'
                    when (a.vasopressor_flag + a.mvent_flag + a.platelets_flag + a.lactic_acid_flag + a.cr_flag + a.bili_flag) = 2 then 'Two'
                    when (a.vasopressor_flag + a.mvent_flag + a.platelets_flag + a.lactic_acid_flag + a.cr_flag + a.bili_flag) = 3 then 'Three'
                    when (a.vasopressor_flag + a.mvent_flag + a.platelets_flag + a.lactic_acid_flag + a.cr_flag + a.bili_flag) = 4 then 'Four'
                    when (a.vasopressor_flag + a.mvent_flag + a.platelets_flag + a.lactic_acid_flag + a.cr_flag + a.bili_flag) = 5 then 'Five'
                    when (a.vasopressor_flag + a.mvent_flag + a.platelets_flag + a.lactic_acid_flag + a.cr_flag + a.bili_flag) = 6 then 'Six'
                    else 'Zero'
                end as num_acuteorg_dysf,
                case
                    when a.age_cat = '[LOW,45)' then ' <45'
                    when a.age_cat = '[45,59]' then '45-59'
                    when a.age_cat = '(59,64]' then '60-64'
                    when a.age_cat = '(64,69]' then '65-69'
                    when a.age_cat = '(69,74]' then '70-74'
                    when a.age_cat = '(74,84]' then '75-84'
                    when a.age_cat = '(84,HIGH]' then '84+'
                    else a.age_cat
                end as age_grp,
                a.age_cat,
                a.married,
                a.covid,
                a.n_hosp90d_sepsisadm,
                a.n_obs90d_sepsisadm,
                a.rolling6,
                a.rolling12,
                a.rolling24,
                a.quarter
            from work.sepsissmr_for_powerbi_update as a
            inner join in.model(keep = ID2 id dxgrpst dxcat DXEXCL) as b
                on a.id = b.id
            inner join in.ip(read=br549 keep=id SSN PatientName type) as c
                on a.id = c.id;
    quit;

%mend create_sepsis_patientlevel;

/****************************************************************************************
* Example usage:
* %create_sepsis_patientlevel(outyr=2025, quar=3);
****************************************************************************************/
