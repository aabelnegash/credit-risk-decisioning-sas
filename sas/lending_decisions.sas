/* Connect to CAS */

cas mySession;
caslib _all_ assign;


/* Print preview of scored variables */

proc print data=CASUSER.HMEQ_SCORED(obs=20);
    var LOAN BAD P_BAD1 P_BAD0;
run;

/* Make lending decisions */

data CASUSER.HMEQ_DECISIONS;
    set CASUSER.HMEQ_SCORED;

    length DECISION $7;

    if P_BAD1 >= 0.10 then
        DECISION = "REJECT";
    else
        DECISION = "APPROVE";
        run;

/* Print preview with lending decisions */

proc print data=CASUSER.HMEQ_DECISIONS(obs=20);
        var LOAN P_BAD1 DECISION BAD;
run;
