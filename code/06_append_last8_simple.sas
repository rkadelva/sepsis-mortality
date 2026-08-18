/*==============================================================================
Macro: %append_last8_simple
Purpose: Append the most recent 8 quarter datasets (including rptqtr)
       from a library, where dataset names follow: &prefix.&sep.YYYYQn
Author: Kadel, Rajendra P. (simplified version for readability)
==============================================================================*/
%macro append_last8_simple(
    lib=work,
    prefix=,
    rptqtr=,
    out=,
    sep=_,
    debug=0
);
    %local year qtr i qdate qi_year qi_qtr dsn dslist nfound;

    %if %superq(prefix)= %then %do;
        %put ERROR: PREFIX is required.;
        %return;
    %end;

    %if %superq(rptqtr)= %then %do;
        %put ERROR: RPTQTR is required in YYYYQn format.;
        %return;
    %end;

    %if %sysfunc(libref(&lib)) ne 0 %then %do;
        %put ERROR: Libref &lib is not assigned.;
        %return;
    %end;

    %let rptqtr=%upcase(%superq(rptqtr));
    %if %sysfunc(prxmatch(/^\d{4}Q[1-4]$/, &rptqtr))=0 %then %do;
        %put ERROR: RPTQTR must be in YYYYQn format, e.g. 2026Q1.;
        %return;
    %end;

    %if %superq(out)= %then %do;
        %let out=&lib..&prefix&sep.last8_&rptqtr;
    %end;

    %let year=%substr(&rptqtr,1,4);
    %let qtr=%substr(&rptqtr,6,1);

    %let dslist=;
    %let nfound=0;

    %do i=0 %to 7;
        %let qdate=%sysfunc(intnx(qtr,%sysfunc(mdy(1,1,&year)),%eval(&qtr-1-&i),B));
        %let qi_year=%sysfunc(year(&qdate));
        %let qi_qtr=%sysfunc(qtr(&qdate));
        %let dsn=&lib..&prefix&sep.&qi_year.Q&qi_qtr;

        %if %sysfunc(exist(&dsn)) %then %do;
            %let dslist=&dslist &dsn;
            %let nfound=%eval(&nfound + 1);

            %if &debug %then %put DEBUG: Found &dsn;
        %end;
    %end;

    %if &nfound=0 %then %do;
        %put ERROR: No matching quarterly datasets found for &prefix.;
        %return;
    %end;

    data &out;
        set &dslist;
    run;

    %put NOTE: Appended &nfound dataset(s) into &out.;
%mend append_last8_simple;

/****************************************************************************************
* Example usage:
* %append_last8_simple(lib=sep_data, prefix=sepsissmrreportfile, rptqtr=2026Q1, out=work.sepsisreportfile_rolling8);
****************************************************************************************/
