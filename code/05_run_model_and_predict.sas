/****************************************************************************************
* Program: 05_run_model_and_predict.sas
* Purpose: Model development, prediction generation, and creation of the report dataset
*          corresponding to the real SAS workflow shared by the user.
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

%macro create_sepsis_smr(outyr, quar);
    %let outyr = &outyr;
    %let quar = &quar;

    ods listing close;

    ods rtf file="/data/ops/5/OQS_IPEC/Programs/sepsismodelwork/modeling/ModelOutput/SepsisHospMortalityModel_&outyr.Q&quar._&&sysdate..doc" style=minimal;

    %sepsismortalitymodel_fixed(sep_data.model_sepsis, sep_data, deaddis, , and discharge_status ne 'TRANSFER', and Transfers, );

    ods rtf close;
    ods listing;

    data sep_data.SEPSISSMRREPORTFILE_&outyr.Q&quar.;
        set sep_data.SEPSISSMRREPORTFILE_&outyr;
        if discharge_yr = &outyr and discharge_qtr = &quar;
    run;

%mend create_sepsis_smr;

/****************************************************************************************
* Example usage:
* %create_sepsis_smr(outyr=2025, quar=3);
****************************************************************************************/
