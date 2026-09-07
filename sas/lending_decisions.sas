cas _all_ terminate;

cas mySession;
caslib _all_ assign;


/* Print preview of scored variables */

proc print data=CASUSER.HMEQ_SCORED(obs=20);
    var LOAN BAD P_BAD1 P_BAD0;
run;



data CASUSER.HMEQ_DECISIONS;
    set CASUSER.HMEQ_SCORED;

    length DECISION $7;
    length RESULT $15;

/* Make lending decisions */

    if P_BAD1 >= 0.10 then
        DECISION = "REJECT";
    else
        DECISION = "APPROVE";

/* Outline results from approval/rejection */

    if DECISION = "APPROVE" and BAD = 0 then
        RESULT = "GOOD_APPROVAL";
    else if DECISION = "APPROVE" and BAD = 1 then
        RESULT = "BAD_APPROVAL";
    else if DECISION = "REJECT" and BAD = 0 then
        RESULT = "GOOD_REJECTED";
    else if DECISION = "REJECT" and BAD = 1 then
        RESULT = "DEFAULT_AVOIDED"; 
    
/* Hypothetical lending costs for threshold analysis */

    if RESULT = "BAD_APPROVAL" then
        COST = 25000;
    else if RESULT = "GOOD_REJECTED" then
        COST = 2000;
    else
        COST = 0;
run;

/* Print preview with lending decisions */

proc print data=CASUSER.HMEQ_DECISIONS(obs=20);
        var LOAN P_BAD1 DECISION BAD RESULT COST;
run;


/* Identify approval/rejection rate against defaulters */

proc freq data=CASUSER.HMEQ_DECISIONS;
    tables RESULT;
run;

/* Identify cost of GOOD_REJECTED & BAD_APPROVAL */

proc means data=CASUSER.HMEQ_DECISIONS sum;
    var COST;
run;





    