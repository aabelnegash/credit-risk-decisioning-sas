# Experiment Log

This is a record of the major experiments completed in SAS Viya for the HMEQ credit-risk project. The purpose is to document what was tested, what changed, and what was kept or rejected while I am learning the modeling workflow.

Model development decisions were based primarily on validation performance. The test partition was not used to guide iterative tuning to maintain a true final test of each model.

## Baseline model comparison

Decision Tree
- Validation AUC: 0.8581
- Validation KS: 0.7019
- Validation misclassification: 0.1169

Logistic Regression
- Validation AUC: 0.6441
- Validation KS: 0.2631

Random Forest
- Validation AUC: 0.9379
- Validation KS: 0.7258
- Validation ASE: 0.0732
- Validation misclassification: 0.0956

Gradient Boosting
- Validation AUC: 0.9343
- Validation KS: 0.7159

Random Forest was the strongest initial model. Gradient Boosting was close enough to continue developing as it showed strong validation performance and a relatively small train-validation gap.

## Missing-value treatment

### Imputation only

Configuration:
- Median imputation for interval variables
- Count imputation for class variables
- Original variables rejected after imputation
- No missingness indicators

Results:
- Logistic Regression validation AUC: 0.7888
- Decision Tree validation AUC: 0.6399
- Random Forest validation AUC: 0.9344
- Gradient Boosting validation AUC: 0.9452
- Gradient Boosting validation KS: 0.7426
- Gradient Boosting validation ASE: 0.0692
- Gradient Boosting validation misclassification: 0.0923

Imputation improved Gradient Boosting and Logistic Regression, but Decision Tree performance dropped significantly.

### Imputation + unique missingness indicators

The same imputation strategy was used but a separate missingness indicator was created for each imputed variable and used as an input.

Results:
- Logistic Regression validation AUC: 0.7834
- Decision Tree validation AUC: 0.8577
- Random Forest validation AUC: 0.9367
- Gradient Boosting validation AUC: 0.9486
- Gradient Boosting validation KS: 0.7572
- Gradient Boosting validation ASE: 0.0657
- Gradient Boosting validation misclassification: 0.0917
- Gradient Boosting validation accuracy: 0.9083
- Top-decile cumulative lift: about 4.68

The unique missingness indicators improved the overall Gradient Boosting performance and restored Decision Tree performance, so they were kept.

## Feature engineering

### LOAN_TO_VALUE

```sas
LOAN_TO_VALUE = LOAN / IMP_VALUE;
```

Results:
- Validation AUC: 0.9454
- Validation KS: 0.7460
- Validation ASE: 0.0672
- Cumulative lift: about 4.57

This feature did not improve the Gradient Boosting model relative to the previous benchmark, so it was rejected.

### MORT_TO_VALUE

```sas
if IMP_VALUE > 0 then do;
    MORT_TO_VALUE = IMP_MORTDUE / IMP_VALUE;
end;
else do;
    MORT_TO_VALUE = .;
end;
```

Results:
- Validation AUC: 0.9511
- Validation KS: 0.7558
- Validation ASE: 0.0650
- Validation accuracy: 0.9139
- Cumulative lift: about 4.71

MORT_TO_VALUE improved AUC, ASE, accuracy, and lift. KS was slightly lower than the previous Gradient Boosting benchmark, but the feature was kept because the overall validation results were stronger.

## Gradient Boosting hyperparameter tuning

Autotuning was attempted, but the SAS environment returned:

> `ERROR: Autotune is not allowed for this environment.`

The main Gradient Boosting hyperparameters were therefore tested manually.

### Number of trees: 100 vs. 200

100 trees:
- Validation AUC: 0.9511
- Validation KS: 0.7558
- Validation ASE: 0.0650
- Validation misclassification: 0.0861

200 trees:
- Validation AUC: 0.9522
- Validation KS: 0.7593
- Validation ASE: 0.0636
- Validation misclassification: 0.0839

The train-validation AUC gap increased slightly at 200 trees, but validation AUC, KS, ASE, and misclassification all improved. The additional trees therefore earned their place.

### Learning rate: 0.10 vs. 0.05

Learning rate 0.10:
- Validation AUC: 0.9522
- Validation KS: 0.7593
- Validation ASE: 0.0636

Learning rate 0.05:
- Validation AUC: 0.8320
- Validation KS: 0.6528
- Validation ASE: 0.1524

The lower learning rate performed worse. Increasing the tree count with learning rate 0.05 did not recover performance; 0.10 was retained.

### Maximum depth

Depth 2 performed substantially worse than the existing configuration.

Depth 4:
- Validation AUC: 0.9522
- Validation KS: 0.7593
- Validation ASE: 0.0636

Depth 6:
- Validation AUC: 0.9656
- Validation KS: 0.8153
- Validation ASE: 0.0564

The depth-6 model reached approximately 1.000 training AUC, so overfitting risk was monitored closely. Validation performance still improved substantially, so depth 6 was kept.

Depth 8 was then tested.

Depth 6 / 400 trees:
- Validation AUC: 0.9663
- Validation KS: 0.8181
- Validation ASE: 0.0563
- Validation accuracy: 0.9284

Depth 8 / 300 trees:
- Validation AUC: 0.9406
- Validation KS: 0.7545
- Validation ASE: 0.0744
- Validation accuracy: 0.9010

Depth 8 / 400 trees:
- Validation AUC: 0.9406
- Validation KS: 0.7545
- Validation ASE: 0.0744
- Validation accuracy: 0.9010

Depth 8 clearly reduced validation performance, so depth 6 remained the strongest setting.

### Tree count after changing depth

Because maximum depth changed, tree count was tested again.

Observed pattern:
- 40 trees performed worse
- 100 trees improved
- 200 trees improved again
- 400 trees produced the strongest validation results
- 500 trees did not produce a meaningful additional improvement

At depth 6 and 400 trees:
- Validation AUC: 0.9663
- Validation KS: 0.8181
- Validation ASE: 0.0563
- Validation accuracy: 0.9284
- Validation F1: 0.8112

The improvement had largely flattened by 500 trees, so 400 trees was retained rather than continuing to test increasingly small changes.

### Subsample rate

Subsample 0.30:
- Validation AUC: 0.9527
- Validation KS: 0.7586
- Validation ASE: 0.0648

Subsample 0.50:
- Validation AUC: 0.9663
- Validation KS: 0.8181
- Validation ASE: 0.0563

Subsample 0.70:
- Validation AUC: 0.9630
- Validation KS: 0.8034
- Validation ASE: 0.0583

The default 0.50 subsample rate remained strongest across AUC, KS, and ASE.

### Minimum leaf size

Leaf size 5:
- Validation AUC: 0.9663
- Validation KS: 0.8181
- Validation ASE: 0.0563
- Validation accuracy: 0.9284
- Validation F1: 0.8112

Leaf size 10:
- Validation AUC: 0.9636
- Validation KS: 0.8168
- Validation ASE: 0.0558
- Validation accuracy: 0.9295
- Validation F1: 0.8158

Leaf size 20:
- Validation AUC: 0.9438
- Validation KS: 0.7544
- Validation ASE: 0.0689
- Validation accuracy: 0.9094
- Validation F1: 0.7638

Leaf size 10 slightly improved ASE, accuracy, and F1, but leaf size 5 retained the strongest AUC and KS. Since KS is the primary selection statistic for this project, leaf size 5 was kept.

## Champion Model: Gradient Boosting configuration

- Number of trees: 400
- Maximum depth: 6
- Learning rate: 0.10
- Subsample rate: 0.50
- Minimum leaf size: 5

Current validation results:
- AUC: 0.9663
- KS: 0.8181
- ASE: 0.0563
- Accuracy: 0.9284
- F1: 0.8112
- Cumulative lift: about 4.73


## Feature Selection

Feature selection was tested to determine whether reducing the number of inputs could improve the Gradient Boosting model or preserve performance with a simpler feature set.

A Variable Selection node using Fast Supervised Selection was added after feature engineering. The Gradient Boosting model after variable selection used the same hyperparameters as the full-feature model so that feature selection remained the main difference.

Full-feature Gradient Boosting:
- Validation AUC: 0.9663
- Validation KS: 0.8181
- Validation ASE: 0.0563

Gradient Boosting after Variable Selection:
- Validation AUC: 0.9241
- Validation KS: 0.7173
- Validation ASE: 0.0756

The selected-feature model performed substantially worse across the main validation metrics.

The reduced feature set was rejected and the full feature set was retained. This showed that variables with lower individual importance can still provide useful information to Gradient Boosting through nonlinear relationships and interactions.


## Threshold Optimization

A separate threshold analysis program was created to compare lending decisions across multiple probability cutoffs.

The initial comparison included thresholds from 0.05 through 0.50. Lower thresholds rejected more borrowers and caught more defaults, while higher thresholds approved more borrowers but also allowed more defaults.

Selected results:

- Threshold 0.05:
  - Approval rate: 73.31%
  - Bad approvals: 34
  - Good borrowers rejected: 436
  - Total modeled cost: $1,722,000

- Threshold 0.10:
  - Approval rate: 76.54%
  - Bad approvals: 49
  - Good borrowers rejected: 258
  - Total modeled cost: $1,741,000

Although 0.05 produced the lowest modeled cost in the broader search, 0.10 approved substantially more borrowers and rejected far fewer good borrowers while increasing modeled cost by only $19,000.

A finer search was then performed around 0.10.

Results near the selected threshold:

- 0.095: total cost $1,753,000
- 0.100: total cost $1,741,000
- 0.105: total cost $1,734,000
- 0.110: total cost $1,766,000

The 0.105 threshold produced the lowest observed cost in the local search. Compared with 0.10, it approved 16 additional good borrowers while also approving one additional borrower who defaulted.

Under the assumed costs:

- 16 fewer good rejections saved $32,000
- 1 additional bad approval cost $25,000
- Net observed improvement: $7,000

However, the final selected threshold was 0.10 rather than 0.105.

Although 0.105 produced the lowest observed cost in the local search, the improvement over 0.10 was only $7,000. Because the threshold was being refined on the same scored dataset, selecting increasingly precise cutoffs could overfit the decision policy to small sample-specific differences. The cost assumptions were also hypothetical. The 0.10 threshold was therefore retained as the simpler and more robust choice for this exercise.

Final selected lending threshold: 0.10.
