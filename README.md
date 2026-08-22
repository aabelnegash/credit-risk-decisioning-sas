# Credit Risk Modeling in SAS Viya

This repository documents a practice credit-risk modeling project completed in SAS Viya Model Studio. The main goal of the project was to learn and apply a full supervised machine-learning workflow for predicting borrower default risk.

The project uses the HMEQ (Home Equity) dataset and focuses on model comparison, missing-value treatment, feature engineering, validation-based model selection, and Gradient Boosting hyperparameter tuning.

## Tools

- SAS Viya
- SAS Model Studio
- SAS Studio
- Git / GitHub

## Modeling Workflow

The workflow developed through the project included:

- Reviewing the target and input variables
- Splitting data into training, validation, and test partitions
- Comparing baseline classification models
- Handling missing values with imputation
- Adding missingness indicators
- Creating new features with SAS code
- Comparing models using validation metrics
- Manually tuning Gradient Boosting
- Monitoring train-validation gaps for overfitting

The test partition was kept separate from the main model-development process so that validation performance could drive tuning decisions.

## Models Tested

The main models compared were:

- Logistic Regression
- Decision Tree
- Random Forest
- Gradient Boosting

Random Forest was the strongest model early in the project, but Gradient Boosting improved substantially after preprocessing, feature engineering, and tuning.

## Missing-Value Treatment

For interval variables, median imputation was used.

For class variables, count imputation was used.

I also tested unique missingness indicators so the models could preserve information about which values were originally missing. This improved the overall Gradient Boosting benchmark and helped restore Decision Tree performance after imputation.

## Feature Engineering

Two ratio features were tested.

### LOAN_TO_VALUE

```sas
LOAN_TO_VALUE = LOAN / IMP_VALUE;
```

This did not improve the Gradient Boosting model enough to keep.

### MORT_TO_VALUE

```sas
if IMP_VALUE > 0 then do;
    MORT_TO_VALUE = IMP_MORTDUE / IMP_VALUE;
end;
else do;
    MORT_TO_VALUE = .;
end;
```

This feature improved several validation metrics and was kept in the modeling pipeline.

The variable was registered for downstream Model Studio nodes with:

```sas
%dmcas_metaChange(
    NAME=MORT_TO_VALUE,
    ROLE=INPUT,
    LEVEL=INTERVAL
);
```

## Gradient Boosting Tuning

SAS autotuning was not available in the current environment, so the main Gradient Boosting hyperparameters were tested manually.

The main settings tested included:

- Number of trees
- Learning rate
- Maximum depth
- Subsample rate
- Minimum leaf size

The strongest configuration found so far is:

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

The training AUC reached approximately 1.000 at the stronger depth settings, so validation performance and the train-validation gap were monitored closely rather than relying on training performance alone.

## Model Evaluation

The main metrics used throughout the project were:

- AUC for ranking ability
- KS for separation between events and non-events
- ASE for probability accuracy
- Misclassification rate
- Lift
- Accuracy
- F1
- Log loss where useful

KS is currently the primary model-selection statistic in the project, but model decisions were not made from a single metric alone.
