cas mySession;
caslib _all_ assign;

/* Compare multiple lending thresholds */

data CASUSER.THRESHOLD_ANALYSIS;
    set CASUSER.HMEQ_SCORED;

    length DECISION $7;
    length RESULT $15;

    DO THRESHOLD = 0.09 to 0.11 by 0.005;

        if P_BAD1 >= THRESHOLD then
            DECISION = "REJECT";
        else
            DECISION = "APPROVE";

        if DECISION = "APPROVE" and BAD = 0 then
            RESULT = "GOOD_APPROVAL";
        else if DECISION = "APPROVE" and BAD = 1 then
            RESULT = "BAD_APPROVAL";
        else if DECISION = "REJECT" and BAD = 0 then
            RESULT = "GOOD_REJECTED";
        else if DECISION = "REJECT" and BAD = 1 then
            RESULT = "DEFAULT_AVOIDED"; 

        if RESULT = "BAD_APPROVAL" then
            COST = 25000;
        else if RESULT = "GOOD_REJECTED" then
            COST = 2000;
        else
            COST = 0;

        output;
    end;
run;

/* Create summary table to optimize decision threshold */

proc sql;
    create table WORK.THRESHOLD_SUMMARY as
    select 
        THRESHOLD,
        SUM(CASE WHEN RESULT = "BAD_APPROVAL" THEN 1 ElSE 0 END) AS BAD_APPROVALS,
        SUM(CASE WHEN RESULT = "GOOD_REJECTED" THEN 1 ELSE 0 END) AS GOOD_REJECTED,
        SUM(CASE WHEN RESULT = "DEFAULT_AVOIDED" THEN 1 ELSE 0 END) AS DEFAULTS_AVOIDED,
        sum(COST) as TOTAL_COST,
        100 * sum(case when DECISION = "APPROVE" then 1 else 0 end) / count(*) as APPROVAL_PCT
    from CASUSER.THRESHOLD_ANALYSIS
    group by THRESHOLD
    order by THRESHOLD;
quit;

proc print data=WORK.THRESHOLD_SUMMARY;
run;

/* Final selected threshold: 0.10
   0.105 had slightly lower observed cost, but the difference was small
   and was not considered strong enough to justify the finer threshold.
*/