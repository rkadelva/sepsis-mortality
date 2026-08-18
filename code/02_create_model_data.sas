/****************************************************************************************
* Program: 02_create_model_data.sas
* Purpose: Create the model-ready sepsis dataset from the colleague's sepsis cohort,
*          hospitalization history, and model input data.
*          This file is the model-data build step used before fitting the logistic
*          regression model and generating current-quarter predictions.
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

%macro create_model_data(outyr=, quar=);
    %if %superq(outyr)= %then %do;
        %put ERROR: OUTYR is required for model-data creation.;
        %return;
    %end;

    %if %superq(quar)= %then %do;
        %put ERROR: QUAR is required for model-data creation.;
        %return;
    %end;

    /***************************************************************************
    * Source datasets created by colleagues:
    *   1. sepsis.sepsis      - Julie's sepsis cohort
    *   2. sepsis.n_hosp_sepsisadm - Jiejin hospitalization count
    *   3. sepsis.sepsis_hosp_obs - Jiejin created observation history
    **************************************************************************/

    libname sepsis "/data/ops/5/OQS_IPEC/Programs/sepsismodelwork/Data";
    libname sep_data "/data/ops/5/OQS_IPEC/Programs/sepsismodelwork/modeling/data";

    proc format;
        value numdisf
            0 = 'Zero'
            1 = 'One'
            2 = 'Two'
            3-6 = 'Three or More';
        value sepsis
            1 = 'Yes - Sepsis Criteria Met'
            0 = 'No - Did not Meet Criteria';
    run;

    %let drop_vars = INPATIENTSID PATIENTSID SSN PseudoSSN PATIENTNAME PatientICN PatientIEN REPORTINGPERIOD EncounterSID EncounterID PersonSID
        CaseDefinition CaseDateTime CDX1-CDX25 UNITDX DXEXCL ADM_DT DIS_DT UE_DT UD_DT DEATH_DT DISDATE--DEATHTIME CaseDateTime PTFIEN LOSINGSPEC;

    %let labs = ALBVAL BILI CHOLESTEROL CPK GFR CR BUN NA WBC PLATELETS HCT PROTHROMBIN_TIME PAO2 PCO2 PH;

    proc sql;
        create table work.model_sepsis_ASEdef_raw as
            select a.*,
                   case when c.infection=1 then 1 else 0 end as infection_flag,
                   c.vasopressor as vasopressor_flag,
                   c.mvent as mvent_flag,
                   c.platelets as platelets_flag,
                   c.lactic_acid as lactic_acid_flag,
                   c.cr as cr_flag,
                   c.bili as bili_flag,
                   case when a.id=c.id then 1 else 0 end as sepsis_ASE label='Sepsis CDS AES Criteria',
                   1 as overall,
                   d.*, 
                   e.n_hosp90d_sepsisadm,
                   e.n_obs90d_sepsisadm
            from in.model
                 (where=(discharge_yr>=2019 and discharge_qtr>=1)
                  drop=cdx1-cdx25 dxexcl unitdx ALBVAL BILI GFR BUN NA WBC HCT PAO2 PCO2 PH) as a
            left join sepsis.sepsis as c
                on a.id=c.id
            inner join in.ip(read=br549 keep=id &labs race_recode rename=(race_recode=race)) as d
                on a.id=d.id
            left join sepsis.n_hosp_sepsisadm as e
                on a.id=e.id;
    quit;

    data work.model_AES_sepsis_all;
        set work.model_sepsis_ASEdef_raw;
        num_acuteorgdysf = sum(of vasopressor_flag, mvent_flag, platelets_flag, lactic_acid_flag, cr_flag, bili_flag);
        format num_acuteorgdysf numdisf.;
        label num_acuteorgdysf = 'Number of Acute Organ Dysfunction'
              Married = 'Marital Status'
              INFECTION_FLAG = 'Infection'
              VASOPRESSOR_FLAG = 'Vasopressor'
              MVENT_FLAG = 'Mvent'
              PLATELETS_FLAG = 'Platelets Count'
              LACTIC_ACID_FLAG = 'Lactic Acid'
              CR_FLAG = 'Creatinine'
              AGE_CAT = 'Age Category'
              deaddis = 'Dead at Discharge'
              sepsis_ASE = 'AES Sepsis Criteria Met';
        format sepsis_ASE sepsis. dxgrpst $dx.;
    run;

    %let vital_signs_cat = pulse_cat pulseox_cat resp_cat temp_cat bp_cat;
    %let labs_from_ip = GLUCOSE GLUCOSE_SC GLUCOSEDAY MEAN_GLUCOSE N_MEAN_GLUCOSE MIN_GLUCOSE MED_GLUCOSE MAX_GLUCOSE CONSEC_HYPER
        DAY_HYPER EVER_HYPER N_HYPER CONSEC_HYPO45 HYPO45 HYPO60 N_HYPO45 ALBVAL ALBVAL_SC BILI BILI_SC SGOT_AST SGOT_AST_SC
        CHOLESTEROL CHOLESTEROL_SC CPK CPK_SC GFR CR CR_SC BUN BUN_SC PH NA NA_SC WBC WBC_SC PLATELETS PLATELETS_SC HCT HCT_SC
        PROTHROMBIN_TIME PROTHROMBIN_SC PAO2 PAO2_SC PCO2 PCO2_MISS PCO2_SC;
    %let missing_indicators = GLUCOSE_MISS ALBVAL_MISS BILI_MISS SGOTAST_MISS CHOLESTEROL_MISS CPK_MISS CR_MISS BUN_MISS NA_MISS
        WBC_MISS PLATELETS_MISS HCT_MISS PROTHROMBINTIME_MISS PAO2_MISS PH_MISS;
    %let demographics_cat = age_cat GENDER married los_prior_cat medsurg immuno lward;
    %let demographics_cont = age LOS_PRIOR;
    %let labs_cat = albval_cat bili_cat bun_cat cr_cat glucose_cat hct_cat na_cat wbc_cat pao2_cat lac_cat;
    %let box_vars = box0sp1 box0sp2 box0sp3 box0sp4 box0sp5 box0sp6 box0sp7 box0sp8 box0sp9 box0sp10 box0sp11;
    %let labs_cont = ALBVAL BILI BUN GLUCOSE HCT NA WBC PAO2 PCO2 PH GFR;
    %let original_labs = GLUCOSE_SC ALBVAL_SC BILI_SC SGOT_AST_SC CHOLESTEROL_SC CPK_SC CR_SC BUN_SC NA_SC PAO2_SC PLATELETS_SC WBC_SC HCT_SC PROTHROMBIN_SC PCO2_SC;

    data sep_data.model_sepsis;
        retain &all_icuvars DEADINPADM30 anyicustay24;
        length platelets_cat $10. num_acuteorgdysf_cat $5. numhosp90_cat $5. numobs90_cat $5.
               cholesterol_cat $10. cpk_cat $7. ulos_cat $10.;
        set work.model_AES_sepsis_all;

        if sepsis_ASE=1;
        ulos = uloshr/24;

        if ulos < 1 then ulos_cat = '0 day';
        else if ulos < 3 then ulos_cat = '1-2 days';
        else if ulos < 5 then ulos_cat = '3-4 days';
        else if ulos < 10 then ulos_cat = '5-9 days';
        else if ulos < 25 then ulos_cat = '10-24 days';
        else if ulos >= 25 then ulos_cat = '25>= days';

        if model_dx in ('CV3','CV10','CV8','CV10_3') then model_dx_new = 'CV9';
        else if model_dx in ('OM1','RS8','OR1','OR2','TR1','TR2','MT3','OR4','NP2') then model_dx_new='OM1';
        else if model_dx in ('RN4','RN5','RN2') then model_dx_new='RN1';
        else if model_dx in ('GI11','GI9','GI4') then model_dx_new='GI7';
        else if model_dx in ('MT2','MT5') then model_dx_new='MT6';
        else if model_dx in ('SP6','SP3') then model_dx_new='SP5';
        else if model_dx in ('CV5') then model_dx_new='CV5';
        else if model_dx in ('NP1') then model_dx_new='NP3';
        else if model_dx in ('NU1') then model_dx_new='NU9';
        else if model_dx in ('HM2') then model_dx_new='HM1';
        else if model_dx in ('RS13') then model_dx_new='RS11';
        else if model_dx in ('NU4') then model_dx_new='NU8';
        else model_dx_new = model_dx;

        if model_proc = 'NONE' then model_proc_flag=0;
        else model_proc_flag=1;
        drop model_dx model_proc;
        rename model_dx_new = model_dx model_proc_flag = model_proc;

        age_cat_new = put(age_cat,age.);
        albval_cat_new = put(albval_cat,albval.);
        bili_cat_new = put(bili_cat,bili.);
        bun_cat_new = put(bun_cat,bun.);
        cr_cat_new = put(cr_cat,cr.);
        glucose_cat_new = put(glucose_cat,glucose.);
        hct_cat_new = put(hct_cat,hct.);
        na_cat_new = put(na_cat,na.);
        wbc_cat_new = put(wbc_cat,wbc.);
        pao2_cat_new = put(pao2_cat,pao.);
        lac_cat_new = put(lac_cat,lacid_fmt.);
        pulse_cat_new = put(pulse_cat,pulse_fmt.);
        pulseox_cat_new = put(pulseox_cat,pulseox_fmt.);
        resp_cat_new = put(resp_cat,resp_fmt.);
        temp_cat_new = put(temp_cat,temp_fmt.);
        bp_cat_new = put(bp_cat,bp_fmt.);
        married_new = put(married,married.);
        lward_new = put(lward,lward.);

        if cpk > 2097 then delete;
        if platelets > 646 then delete;
        if cholesterol > 290 then delete;

        if n_hosp90d_sepsisadm > 3 then numhosp90_cat = '4+';
        else numhosp90_cat = n_hosp90d_sepsisadm;

        if n_obs90d_sepsisadm > 1 then numobs90_cat = '2+';
        else numobs90_cat = n_obs90d_sepsisadm;

        if num_acuteorgdysf > 3 then num_acuteorgdysf_cat = '4+';
        else num_acuteorgdysf_cat = num_acuteorgdysf;

        if (platelets > 0 and platelets < 50) then platelets_cat = '0-50';
        else if (platelets >= 50 and platelets < 250) then platelets_cat = '50-250';
        else if (platelets >= 250 and platelets < 260) then platelets_cat = '250-260';
        else if (platelets >= 260 and platelets < 400) then platelets_cat = '260-400';
        else if platelets >= 400 then platelets_cat = '400+';
        else if platelets = . then platelets_cat = 'N/A';

        if (cholesterol >= 0 and cholesterol < 200) then cholesterol_cat = '0-200';
        else if (cholesterol > 200 and cholesterol <= 239) then cholesterol_cat = '200-239';
        else if cholesterol >= 240 then cholesterol_cat = '240+';
        else if cholesterol = . then cholesterol_cat = 'N/A';

        if (cpk >= 0 and cpk < 10) then cpk_cat = '0-10';
        else if (cpk >= 10 and cpk < 120) then cpk_cat = '10-120';
        else if cpk >= 120 then cpk_cat = '120+';
        else cpk_cat = 'N/A';

        los_prior_cat_new = put(los_prior_cat,los_prior.);

        drop &labs_cat &vital_signs_cat age_cat los_prior_cat married lward;

        rename age_cat_new = age_cat
               albval_cat_new = albval_cat
               bili_cat_new = bili_cat
               bun_cat_new = bun_cat
               cr_cat_new = cr_cat
               glucose_cat_new = glucose_cat
               hct_cat_new = hct_cat
               na_cat_new = na_cat
               wbc_cat_new = wbc_cat
               pao2_cat_new = pao2_cat
               lac_cat_new = lac_cat
               pulse_cat_new = pulse_cat
               pulseox_cat_new = pulseox_cat
               resp_cat_new = resp_cat
               temp_cat_new = temp_cat
               bp_cat_new = bp_cat
               los_prior_cat_new = los_prior_cat
               married_new = married
               lward_new = lward;

        label cpk = 'Total creatine phosphokinase';
    run;

    /* Create dev_flag variable: current quarter is validation; prior 2 years are model development */
    data sep_data.model_sepsis;
        set sep_data.model_sepsis;
        if sepsis_ASE = 1;
        dev_flag = .;

        if &quar = 1 then do;
            if (discharge_yr = &outyr and discharge_qtr = 1) or discharge_yr in (%eval(&outyr-1), %eval(&outyr-2));
            end;
        end;

        else if &quar = 2 then do;
            if (discharge_yr = &outyr and discharge_qtr in (1,2))
                or (discharge_yr = %eval(&outyr-1))
                or (discharge_yr = %eval(&outyr-2) and discharge_qtr in (2,3,4));
            end;
        end;

        else if &quar = 3 then do;
            if (discharge_yr = &outyr and discharge_qtr in (1,2,3))
                or (discharge_yr = %eval(&outyr-1))
                or (discharge_yr = %eval(&outyr-2) and discharge_qtr in (3,4));
            end;
        end;

        else if &quar = 4 then do;
            if (discharge_yr = &outyr)
                or (discharge_yr = %eval(&outyr-1))
                or (discharge_yr = %eval(&outyr-2) and discharge_qtr in (4));
            end;
        end;

        if (discharge_yr = &outyr and discharge_qtr = &quar) then dev_flag = 0;
        else dev_flag = 1;
    run;

    proc tabulate data=sep_data.model_sepsis;
        class discharge_yr discharge_qtr dev_flag;
        table discharge_yr*discharge_qtr, dev_flag*N;
    run;

    %put NOTE: Model data created and stored in sep_data.model_sepsis for outyr=&outyr quar=&quar;

%mend create_model_data;

/****************************************************************************************
* Example usage:
* %create_model_data(outyr=2026, quar=1);
****************************************************************************************/
