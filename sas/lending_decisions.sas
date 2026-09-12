cas _all_ terminate;
cas mySession;
caslib _all_ assign;


/* Preview scored model output */
proc print data=CASUSER.HMEQ_SCORED(obs=20);
    var LOAN BAD P_BAD1 P_BAD0;
run;


/* Apply selected lending threshold */

data CASUSER.HMEQ_DECISIONS;
    set CASUSER.HMEQ_SCORED;

    length DECISION $7;
    length RESULT $15;

    /* Final selected threshold for this exercise */
    if P_BAD1 >= 0.10 then
        DECISION = "REJECT";
    else
        DECISION = "APPROVE";


    /* Evaluate decisions using historical loan outcomes */

    if DECISION = "APPROVE" and BAD = 0 then
        RESULT = "GOOD_APPROVAL";

    else if DECISION = "APPROVE" and BAD = 1 then
        RESULT = "BAD_APPROVAL";

    else if DECISION = "REJECT" and BAD = 0 then
        RESULT = "GOOD_REJECTED";

    else if DECISION = "REJECT" and BAD = 1 then
        RESULT = "DEFAULT_AVOIDED";

run;


/* Preview final lending decisions */
proc print data=CASUSER.HMEQ_DECISIONS(obs=20);
    var LOAN P_BAD1 DECISION BAD RESULT;
run;


/* Summarize final policy */
proc freq data=CASUSER.HMEQ_DECISIONS;
    tables DECISION RESULT;
run;




    