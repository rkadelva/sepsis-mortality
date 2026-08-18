/****************************************************************************************
* Program: 08a_create_inverse_gamma_lookup.sas
* Purpose: Create the inverse-gamma lookup table used to calculate confidence intervals
*          for the SMR summary workflow.
****************************************************************************************/

%macro create_sepsis_inverse_gamma_lookup(in_data=, out_data=sep_data.SepsisDimInvereGammaLookup, max_additional=5000);
    %if %superq(in_data)= %then %do;
        %put ERROR: IN_DATA is required for the inverse-gamma lookup table.;
        %return;
    %end;

    proc sql noprint;
        select sum(deaddis) into :maxdeath trimmed
        from &in_data;
    quit;

    %if %superq(maxdeath)= %then %do;
        %let maxdeath = 0;
    %end;

    data &out_data;
        do obs = 0 to %eval(&maxdeath + &max_additional);
            if obs ne 0 then do;
                gaminvLL = gaminv(0.025, obs);
                gaminvUL = gaminv(0.975, obs + 1);
            end;
            else do;
                gaminvLL = 0;
                gaminvUL = -log(1 - 0.95);
            end;
            output;
        end;
    run;

    %put NOTE: Inverse-gamma lookup table created: &out_data with max deaths=&maxdeath.;

%mend create_sepsis_inverse_gamma_lookup;

/****************************************************************************************
* Example usage:
* %create_sepsis_inverse_gamma_lookup(
*     in_data=sep_data.SepsisSMR_Drilldown_STG_2026Q1,
*     out_data=sep_data.SepsisDimInvereGammaLookup
* );
****************************************************************************************/
