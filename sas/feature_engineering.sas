/* MORT_TO_VALUE feature used in Pipeline */


/* Training Code */
%dmcas_metachange(
    NAME=MORT_TO_VALUE,
    ROLE=INPUT,
    LEVEL=INTERVAL
);

/* Scoring Code */
length MORT_TO_VALUE 8;

if IMP_VALUE > 0 then
    MORT_TO_VALUE = IMP_MORTDUE / IMP_VALUE;
else
    MORT_TO_VALUE = .;