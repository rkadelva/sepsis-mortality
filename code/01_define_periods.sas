/****************************************************************************************
* Program: 01_define_periods.sas
* Purpose: Define reporting period variables and global macro parameters used across the project
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

%macro define_reporting_periods(outyr=, quar=);
    %if %superq(outyr)= %then %do;
        %put ERROR: OUTYR is required.;
        %return;
    %end;

    %if %superq(quar)= %then %do;
        %put ERROR: QUAR is required.;
        %return;
    %end;

    %let reporting_period = %sysfunc(cats(&outyr, Q, &quar));
    %let current_qtr_start = %sysfunc(intnx(qtr, %sysfunc(mdy(1,1,&outyr)), %eval(&quar-1), B));
    %let current_qtr_end   = %sysfunc(intnx(qtr, %sysfunc(mdy(1,1,&outyr)), %eval(&quar-1), E));

    %put NOTE: Reporting period = &reporting_period;
    %put NOTE: Current quarter start = &current_qtr_start;
    %put NOTE: Current quarter end = &current_qtr_end;

%mend define_reporting_periods;

/****************************************************************************************
* Example usage:
* %define_reporting_periods(outyr=2026, quar=1);
****************************************************************************************/
