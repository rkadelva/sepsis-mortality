/****************************************************************************************
* Program: 04_build_logistic_model.sas
* Purpose: Develop the logistic regression model using the previous 8 quarters of data
*          with in-hospital death as the outcome variable
* Author: Rajendra Kadel
* Date: 2026
****************************************************************************************/

%macro sepsismortalitymodel_fixed(dsnin, outlib, outcome, suf, modelwhere, modeltitle, where);

    data all;
        set &dsnin (where=(unitspec_grp not in (1,2,6,8,9) and occurrence_inp=1 and &outcome ne .
            and discharge_yr ge 2016 and lvad_pre ne 1 &where));

        * Discharge dead within 4 hours;
        if deathtime ne . and adm_dt+4*60*60 > death_dt then delete;
        if admtime ne . and distime ne . and adm_dt+4*60*60 > dis_dt and index(discharge_status, 'DEATH') then delete;

        * Create outcome variable for the model;
        if dev_flag=1 then &outcome.2 = &outcome;

        * Exclude hospice from the model dataset;
        if hospice_pre ne 1 then output all;
    run;

    proc tabulate data=all;
        class discharge_yr discharge_qtr dev_flag;
        table discharge_yr*discharge_qtr, dev_flag*N;
    run;

    ods exclude classlevelinfo type3;
    options pageno=1;

    proc logistic data=all descending outest=betas;
        class
            bun_cat (ref='[LOW,16.9]')
            na_cat (ref='(134,154]')
            albval_cat (ref='(2.4,4.4]')
            bili_cat (ref='[LOW,1.9]')
            glucose_cat (ref='(59,199]')
            cr_cat (ref='(0.4,1.4]')
            hct_cat (ref='(40.9,49]')
            wbc_cat (ref='(2.9,19.9]')
            lac_cat (ref='[low,2]')
            pulse_cat (ref='[50,99]')
            pulseox_cat (ref='[90,high]')
            resp_cat (ref='[14,24]')
            temp_cat (ref='[36,38.4]')
            bp_cat (ref='[80,99]')
            age_cat (ref='[LOW,45)')
            lward (ref='Clinic/ED' param=ref)
            model_dx (ref='CV9' param=ref)
            model_proc
            anyicustay24(ref='No')
            num_acuteorgdysf_cat
            covid
            platelets_cat(ref='0-50')
            /param=reference;

        where trns ne 1 &modelwhere;

        model &outcome.2 =
            anyicustay24
            age_cat
            albval_cat
            bili_cat
            bun_cat
            glucose_cat
            wbc_cat
            lac_cat
            pulseox_cat
            resp_cat
            temp_cat
            bp_cat
            model_dx
            model_proc
            immuno
            lward
            vasopressor_flag
            mvent_flag
            covid
            platelets_flag
            lactic_acid_flag
            cr_flag
            bili_flag
            box0sp6 box0sp9 lward platelets_cat insurance
            cancer_mets drug_abuse wghtloss cancer_leuk psychoses liver_sev neuro_oth pulmcirc coag cbvd cancer_solid renlfl_sev
            depress chf anemdef obese diab_cx lung_chronic
            /ridging=none lackfit rsq;

        output out=pp0_&suf p=p0 xbeta=index;
        title 'Mortality Model';
        title2 'Fixed Coefficients - Previous 2 Years';
        title3 'Transplants &modeltitle Excluded from Analysis';
        title4 'Acute Care &suf Model';
    run;

    ods select all;
    title1; title2; title3; title4;

    data deciles_&suf;
        set pp0_&suf;
        if 0 le p0 lt 0.025 then p0_group=1;
        else if 0.025 le p0 lt .05 then p0_group=2;
        else if .05 le p0 lt .10 then p0_group=3;
        else if .10 le p0 lt .30 then p0_group=4;
        else if p0 ge .30 then p0_group=5;
        format p0_group sev.;
        if p0=. then delete;
        if 0 le p0 le .1 then decile = 0;
        else if .1 lt p0 le .2 then decile = 1;
        else if .2 lt p0 le .3 then decile = 2;
        else if .3 lt p0 le .4 then decile = 3;
        else if .4 lt p0 le .5 then decile = 4;
        else if .5 lt p0 le .6 then decile = 5;
        else if .6 lt p0 le .7 then decile = 6;
        else if .7 lt p0 le .8 then decile = 7;
        else if .8 lt p0 le .9 then decile = 8;
        else if p0 gt .9 then decile = 9;
        cp=.002*int(p0/.002);
        format decile decile.;
    run;

    %c_hl_general(,where dev_flag in (1), deciles_&suf, &outcome, p0, Acute Care &suf Development);
    title2 "&suf Model";
    %smrbydecile(deciles_&suf, where dev_flag in (1), Acute Care Development); title2;

    %c_hl_general(,where dev_flag=0 and discharge_yr=&outyr, deciles_&suf, &outcome, p0, Acute Care &suf Validation);
    title2 "&suf Model";
    %smrbydecile(deciles_&suf, where dev_flag=0 and discharge_yr=&outyr, Acute Care Validation); title2;

    %c_hl_general(,where dev_flag = 1 or discharge_yr=&outyr, deciles_&suf, &outcome, p0, Acute Care &suf Development and Validation);
    title2 "&suf Model";
    %smrbydecile(deciles_&suf, where dev_flag = 1 or discharge_yr=&outyr, Acute Care Development and Validation); title2;

    data &outlib..sepsissmr&suf.reportfile_&outyr;
        retain id id2 patid scrssn visn site site_orig unittype2 unittype_level losingspec unitspec_grp unitspec_rpt
               discharge_yr discharge_qtr occurrence_inp lward
               medsurg admweekend insurance discharge_status
               dxcat model_dx model_proc dxgrpst dxclass proc_class p0_group glucose_grp mean_glucose_grp
               p0 &outcome index operative decile adm_dt dis_dt ue_dt ud_dt death_dt
               disdate distime admdate admtime uedatein uetimein uddatein udtimein deathdate deathtime
               level complexity_level hospice_pre hospice_post covid dev_flag;

        set deciles_&suf;

        label decile = 'Decile of Estimated Probability'
              glucose_grp = 'Glucose Category'
              mean_glucose_grp = 'Category of Mean Glucose'
              p0_group = 'Category of Estimated Probability'
              medsurg = 'Medical or Surgical Losing Specialty'
              admweekend = 'Admission on Saturday or Sunday'
              insurance = 'Patient Has Insurance = 1';

        keep id id2 patid scrssn visn site site_orig unittype2 unittype_level losingspec unitspec_grp unitspec_rpt
             discharge_yr discharge_qtr occurrence_inp lward
             medsurg admweekend insurance discharge_status
             dxcat dxgrpst dxclass proc_class p0_group glucose_grp mean_glucose_grp
             p0 &outcome index operative decile adm_dt dis_dt ue_dt ud_dt death_dt
             disdate distime admdate admtime uedatein uetimein uddatein udtimein deathdate deathtime
             level complexity_level hospice_pre hospice_post covid dev_flag
             num_acuteorgdysf_cat anyicustay24 ulos_cat box0sp9 box0sp6 platelets_cat insurance
             married anyicustay24 medsurg age_cat na_cat albval_cat bili_cat bun_cat glucose_cat cr_cat hct_cat
             wbc_cat lac_cat pulse_cat pulseox_cat resp_cat temp_cat bp_cat model_dx model_proc immuno lward
             infection_flag vasopressor_flag mvent_flag platelets_flag lactic_acid_flag cr_flag bili_flag
             n_hosp90d_sepsisadm n_obs90d_sepsisadm
             &elixhauser_model;
    run;

    proc sort data=&outlib..sepsissmr&suf.reportfile_&outyr;
        by id;
    run;

%mend sepsismortalitymodel_fixed;

/****************************************************************************************
* Example usage:
* %sepsismortalitymodel_fixed(dsnin=sep_data.model_sepsis,
*                            outlib=sep_data,
*                            outcome=deaddis,
*                            suf=ACUTE,
*                            modelwhere=,
*                            modeltitle=Acute,
*                            where=);
****************************************************************************************/
