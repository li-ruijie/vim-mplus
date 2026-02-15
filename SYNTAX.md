# Mplus Syntax Reference

Reference for syntax groups used by the vim-mplus plugin. Keywords are
case-insensitive. Source: <https://www.statmodel.com/language.html>.

## File Structure

```
mplus-inp.vim                    mplus-out.vim
(*.inp files)                    (*.out files)
     │                                │
     │  runtime syntax/mplus.vim      │  runtime syntax/mplus.vim
     │                                │
     └──────────┐          ┌──────────┘
                │          │
                ▼          ▼
              mplus.vim (shared)
           ┌──────────────────┐
           │ iskeyword, case  │
           │ mplusStatement   │
           │ mplusCommand     │
           │ mplusModel       │
           │ mplusSpeccom     │
           │ mplusComment     │
           │ mplusSection     │  ◄── %label% markers
           │ mplusHeader      │  ◄── timestamp only
           │ highlight links  │
           └──────────────────┘
                │          │
     ┌──────────┘          └──────────┐
     ▼                                ▼
mplus-inp.vim adds:          mplus-out.vim adds:
  mplusFold regions              mplusSection
  matchgroup=mplusSection        (2-space indent)
  ^TITLE:  (no keywords)        ^  TITLE:
  ^(DATA|MODEL)(\s\S+)?:        ^  (DATA|MODEL)(\s\S+)?:

                                 mplusHeader
                                 (all-caps lines)
                                 \C^\u[A-Z 0-9/,-]+$
```

## Highlight Groups

```
┌────────────────┬───────────┬──────────────────────────────────────┐
│ Group          │ Links To  │ Usage                                │
├────────────────┼───────────┼──────────────────────────────────────┤
│ mplusStatement │ Statement │ Top-level and OUTPUT option keywords │
│ mplusCommand   │ Statement │ Section-specific command options     │
│ mplusModel     │ Function  │ Model specification operators        │
│ mplusSection   │ Include   │ Section headers, %label% markers     │
│ mplusComment   │ Comment   │ Comments starting with !             │
│ mplusSpeccom   │ Special   │ ARE, IS connectors                   │
│ mplusHeader    │ Type      │ Timestamp and output headers         │
└────────────────┴───────────┴──────────────────────────────────────┘
```

## Section Headers (mplusSection)

Input files match at column 1; output files match with 2-space indent.
Compound headers (`MODEL X:`, `DATA X:`) are matched via `\(\s\+\S\+\)\?`.
Class/level labels (`%OVERALL%`, `%c#1%`, `%BETWEEN subject%`) are also
highlighted as mplusSection in the base file.

```
┌────────────┬───────────────────────────────────────────────────────────┐
│ Section    │ Sub-sections (compound headers)                           │
├────────────┼───────────────────────────────────────────────────────────┤
│ TITLE      │                                                           │
│ DATA       │ IMPUTATION MISSING TWOPART WIDETOLONG LONGTOWIDE SURVIVAL │
│            │ COHORT                                                    │
│ VARIABLE   │                                                           │
│ DEFINE     │                                                           │
│ ANALYSIS   │                                                           │
│ MODEL      │ CONSTRAINT INDIRECT POPULATION MISSING PRIORS PRIOR TEST  │
│            │ MONTECARLO COVERAGE <user-label> POPULATION-<label>       │
│ OUTPUT     │                                                           │
│ SAVEDATA   │                                                           │
│ PLOT       │                                                           │
│ MONTECARLO │                                                           │
└────────────┴───────────────────────────────────────────────────────────┘
```

## Model Operators (mplusModel)

```
┌────────────┬──────────────────────────────┐
│ Operator   │ Usage                        │
├────────────┼──────────────────────────────┤
│ BY         │ Factor loading specification │
│ ON         │ Regression                   │
│ WITH       │ Covariance                   │
│ PWITH      │ Pairwise covariance          │
│ XWITH      │ Interaction (latent)         │
│ AT         │ Fix/free parameter value     │
│ IND        │ Indirect effect path         │
│ VIA        │ Indirect effect path         │
│ ALL        │ All variables shorthand      │
│ PON        │ Partial ON                   │
│ NEW        │ New parameter declaration    │
│ MOD        │ Model modification           │
│ LOOP       │ Loop over values             │
│ DO         │ Loop construct               │
│ DIFF       │ Parameter difference (short) │
│ DIFFERENCE │ Parameter difference         │
│ SQRT       │ Square root function         │
│ EXP        │ Exponential function         │
│ LOG        │ Natural logarithm function   │
│ \|         │ Growth model pipe operator   │
│ &          │ Lag operator (e.g., f&1)     │
└────────────┴──────────────────────────────┘
```

## Statement Keywords (mplusStatement)

### Top-Level

```
┌─────────────┬────────────────────────────┐
│ Keyword     │ Description                │
├─────────────┼────────────────────────────┤
│ ANALYSIS    │ Analysis section keyword   │
│ CATEGORICAL │ Categorical variable decl  │
│ DATA        │ Data section keyword       │
│ FILE        │ Data file specification    │
│ LINK        │ Link function              │
│ MISSING     │ Missing value code         │
│ MODEL       │ Model section keyword      │
│ NAMES       │ Variable names             │
│ OUTPUT      │ Output section keyword     │
│ PLOT        │ Plot section keyword       │
│ PROCESSORS  │ Number of processors       │
│ TITLE       │ Title section keyword      │
│ TYPE        │ Analysis/data type         │
│ USEVAR      │ Use variables (short form) │
│ USEV        │ Use variables (short form) │
│ USEVARIABLE │ Use variables              │
│ VARIABLE    │ Variable section keyword   │
└─────────────┴────────────────────────────┘
```

### Output Options

```
┌───────────────┬────────────────────────────────┐
│ Keyword       │ Description                    │
├───────────────┼────────────────────────────────┤
│ MODINDICES    │ Modification indices           │
│ RESIDUAL      │ Residual output                │
│ SAMPSTAT      │ Sample statistics              │
│ STANDARDIZED  │ Standardized solution          │
│ STD           │ Unstandardized std solution    │
│ STDYX         │ StdYX standardized solution    │
│ STDY          │ StdY standardized solution     │
│ CINTERVAL     │ Confidence intervals           │
│ SVALUES       │ Starting values in output      │
│ NOCHISQUARE   │ Suppress chi-square test       │
│ NOSERROR      │ Suppress standard errors       │
│ H1SE          │ H1 model standard errors       │
│ H1TECH3       │ H1 model TECH3 output          │
│ H1MODEL       │ H1 model estimation            │
│ CROSSTABS     │ Cross-tabulations              │
│ FSCOEFFICIENT │ Factor score coefficients      │
│ FSDETERMINACY │ Factor score determinacy       │
│ FSCOMPARISON  │ Factor score comparison        │
│ BASEHAZARD    │ Baseline hazard function       │
│ LOGRANK       │ Log-rank test                  │
│ ALIGNMENT     │ Alignment optimization         │
│ ENTROPY       │ Entropy statistic              │
│ MONTECARLO    │ Monte Carlo integration info   │
│ PATTERNS      │ Missing data patterns          │
│ TECH1–TECH16  │ Technical outputs 1 through 16 │
└───────────────┴────────────────────────────────┘
```

## Command Keywords by Section (mplusCommand)

### DATA

```
┌───────────────┬───────────────────────────┐
│ Keyword       │ Description               │
├───────────────┼───────────────────────────┤
│ INDIVIDUAL    │ Individual-level data     │
│ COVARIANCE    │ Covariance matrix input   │
│ CORRELATION   │ Correlation matrix input  │
│ FULLCOV       │ Full covariance matrix    │
│ FULLCORR      │ Full correlation matrix   │
│ MEANS         │ Means input               │
│ STDEVIATIONS  │ Standard deviations input │
│ IMPUTATION    │ Multiple imputation data  │
│ NOBSERVATIONS │ Number of observations    │
│ NGROUPS       │ Number of groups          │
│ VARIANCES     │ Variance input            │
│ CHECK         │ Check data                │
│ NOCHECK       │ Skip data checking        │
│ FREE          │ Free format data          │
│ LISTWISE      │ Listwise deletion         │
│ SWMATRIX      │ Sample weight matrix      │
│ NDATASETS     │ Number of datasets        │
│ WIDE          │ Wide format data          │
│ LONG          │ Long format data          │
│ REPETITION    │ Repetition specification  │
│ CUTPOINT      │ Cutpoint specification    │
│ TRANSFORM     │ Data transformation       │
│ IMPUTE        │ Imputation specification  │
│ BINARY        │ Binary part (TWOPART)     │
│ CONTINUOUS    │ Continuous part (TWOPART) │
│ DESCRIPTIVE   │ Descriptive statistics    │
│ DDROPOUT      │ Dropout model (NMAR)      │
│ SDROPOUT      │ Selection model (NMAR)    │
└───────────────┴───────────────────────────┘
```

### VARIABLE

```
┌─────────────────┬───────────────────────────────┐
│ Keyword         │ Description                   │
├─────────────────┼───────────────────────────────┤
│ USEOBSERVATIONS │ Select observations           │
│ USEVARIABLES    │ Select variables              │
│ CENSORED        │ Censored variable declaration │
│ NOMINAL         │ Nominal variable declaration  │
│ COUNT           │ Count variable declaration    │
│ GROUPING        │ Grouping variable             │
│ IDVARIABLE      │ ID variable                   │
│ WEIGHT          │ Sampling weight               │
│ FORMAT          │ Data format                   │
│ CLUSTER         │ Cluster variable              │
│ STRATIFICATION  │ Stratification variable       │
│ CENTERING       │ Variable centering            │
│ TSCORES         │ Time scores                   │
│ AUXILIARY       │ Auxiliary variables           │
│ CLASSES         │ Latent class specification    │
│ KNOWNCLASS      │ Known class membership        │
│ TRAINING        │ Training data specification   │
│ WITHIN          │ Within-level variables        │
│ BETWEEN         │ Between-level variables       │
│ PATTERN         │ Missing data pattern          │
│ COHORT          │ Cohort variable               │
│ COPATTERN       │ Cohort pattern                │
│ COHRECODE       │ Cohort recode                 │
│ TIMEMEASURES    │ Time measures specification   │
│ TNAMES          │ Time variable names           │
│ MEMBERSHIP      │ Class membership              │
│ PROBABILITIES   │ Class probabilities           │
│ DSURVIVAL       │ Discrete-time survival        │
│ FREQWEIGHT      │ Frequency weight              │
│ WTSCALE         │ Weight scaling                │
│ REPWEIGHTS      │ Replicate weights             │
│ SUBPOPULATION   │ Subpopulation selection       │
│ SURVIVAL        │ Survival variable             │
│ TIMECENSORED    │ Time censoring indicator      │
│ LAGGED          │ Lagged variables              │
│ TINTERVAL       │ Time interval                 │
│ BWEIGHT         │ Between-level weight          │
│ B2WEIGHT        │ Level-2 weight                │
│ B3WEIGHT        │ Level-3 weight                │
│ BWTSCALE        │ Between weight scaling        │
│ FINITE          │ Finite population correction  │
│ CTIME           │ Continuous time               │
│ R3STEP          │ 3-step auxiliary (R)          │
│ BCH             │ BCH auxiliary method          │
│ DU3STEP         │ 3-step auxiliary (DU)         │
│ DE3STEP         │ 3-step auxiliary (DE)         │
│ D3STEP          │ 3-step auxiliary (D)          │
│ D3STEPC         │ 3-step auxiliary (DC)         │
│ BCHC            │ BCH auxiliary (corrected)     │
│ DCATEGORICAL    │ Distal categorical auxiliary  │
│ DCONTINUOUS     │ Distal continuous auxiliary   │
└─────────────────┴───────────────────────────────┘
```

### DEFINE

```
┌──────────────┬────────────────────────┐
│ Keyword      │ Description            │
├──────────────┼────────────────────────┤
│ IF           │ Conditional statement  │
│ THEN         │ Then clause            │
│ CUT          │ Cut variable at value  │
│ CENTER       │ Center variables       │
│ STANDARDIZE  │ Standardize variables  │
│ GRANDMEAN    │ Grand mean centering   │
│ GROUPMEAN    │ Group mean centering   │
│ CLUSTER_MEAN │ Cluster mean centering │
└──────────────┴────────────────────────┘
```

### ANALYSIS — Types and Estimators

```
┌──────────────────┬─────────────────────────────────┐
│ Keyword          │ Description                     │
├──────────────────┼─────────────────────────────────┤
│ ESTIMATOR        │ Estimation method               │
│ PARAMETERIZATION │ Parameterization type           │
│ ALGORITHM        │ Optimization algorithm          │
│ ML               │ Maximum likelihood              │
│ MLM              │ ML with robust SEs (mean adj)   │
│ MLMV             │ ML with robust SEs (mean/var)   │
│ MLR              │ ML robust                       │
│ MLF              │ ML with first derivatives       │
│ MUML             │ Muthén's limited-info estimator │
│ WLS              │ Weighted least squares          │
│ WLSM             │ WLS mean-adjusted               │
│ WLSMV            │ WLS mean/variance-adjusted      │
│ GLS              │ Generalized least squares       │
│ ULS              │ Unweighted least squares        │
│ ULSMV            │ ULS mean/variance-adjusted      │
│ BAYES            │ Bayesian estimation             │
│ GENERAL          │ General analysis type           │
│ BASIC            │ Basic statistics                │
│ RANDOM           │ Random effects                  │
│ COMPLEX          │ Complex survey data             │
│ MIXTURE          │ Mixture modeling                │
│ TWOLEVEL         │ Two-level modeling              │
│ THREELEVEL       │ Three-level modeling            │
│ CROSSCLASSIFIED  │ Cross-classified modeling       │
│ EFA              │ Exploratory factor analysis     │
│ ESEM             │ Exploratory SEM                 │
│ BSEM             │ Bayesian SEM                    │
│ BESEM            │ Bayesian exploratory SEM        │
│ LOGISTIC         │ Logistic regression             │
│ ARIMA            │ Autoregressive integrated MA    │
│ ARMA             │ Autoregressive moving average   │
└──────────────────┴─────────────────────────────────┘
```

### ANALYSIS — Settings

```
┌───────────────┬──────────────────────────────┐
│ Keyword       │ Description                  │
├───────────────┼──────────────────────────────┤
│ CHOLESKY      │ Cholesky decomposition       │
│ MCSEED        │ Monte Carlo seed             │
│ ADAPTIVE      │ Adaptive quadrature          │
│ INFORMATION   │ Information matrix type      │
│ BOOTSTRAP     │ Bootstrap samples            │
│ DIFFTEST      │ Difference testing           │
│ STARTS        │ Random start values          │
│ STITERATIONS  │ Start value iterations       │
│ STCONVERGENCE │ Start value convergence      │
│ STSCALE       │ Start value scaling          │
│ STSEED        │ Start value seed             │
│ OPTSEED       │ Optimization seed            │
│ COVERAGE      │ Coverage criterion           │
│ ITERATIONS    │ Maximum iterations           │
│ SDITERATIONS  │ Stepwise iterations          │
│ H1ITERATIONS  │ H1 model iterations          │
│ MITERATIONS   │ M-step iterations            │
│ MCITERATIONS  │ MC integration iterations    │
│ MUITERATIONS  │ MU iterations                │
│ CONVERGENCE   │ Convergence criterion        │
│ H1CONVERGENCE │ H1 convergence criterion     │
│ LOGCRITERION  │ Log-likelihood criterion     │
│ MCONVERGENCE  │ M-step convergence           │
│ MCCONVERGENCE │ MC convergence               │
│ MUCONVERGENCE │ MU convergence               │
│ INTEGRATION   │ Numerical integration        │
│ STANDARD      │ Standard integration         │
│ GAUSSHERMITE  │ Gauss-Hermite quadrature     │
│ MIXC          │ Mixture convergence          │
│ MIXU          │ Mixture update               │
│ LOGHIGH       │ Log-likelihood high bound    │
│ LOGLOW        │ Log-likelihood low bound     │
│ UCELLSIZE     │ Univariate cell size         │
│ VARIANCE      │ Variance specification       │
│ MATRIX        │ Matrix type                  │
│ MEANSTRUCTURE │ Mean structure modeling      │
│ MCOHORT       │ Multiple cohort              │
│ H1            │ Unrestricted H1 model        │
│ DELTA         │ Delta parameterization       │
│ THETA         │ Theta parameterization       │
│ LOGIT         │ Logit link                   │
│ LOGLINEAR     │ Log-linear model             │
│ ON            │ On setting                   │
│ OFF           │ Off setting                  │
│ EMA           │ EM acceleration              │
│ EM            │ EM algorithm                 │
│ ODLL          │ Observed-data log-likelihood │
│ OBSERVED      │ Observed information         │
│ EXPECTED      │ Expected information         │
│ COMBINATION   │ Combination approach         │
└───────────────┴──────────────────────────────┘
```

### ANALYSIS — Model Structure

```
┌─────────────────┬───────────────────────┐
│ Keyword         │ Description           │
├─────────────────┼───────────────────────┤
│ CONFIGURAL      │ Configural invariance │
│ SCALAR          │ Scalar invariance     │
│ NOMEANSTRUCTURE │ No mean structure     │
│ NOCOVARIANCES   │ No covariances        │
│ ALLFREE         │ All parameters free   │
└─────────────────┴───────────────────────┘
```

### ANALYSIS — Distribution and Parameterization

```
┌───────────────┬──────────────────────────────┐
│ Keyword       │ Description                  │
├───────────────┼──────────────────────────────┤
│ NORMAL        │ Normal distribution          │
│ SKEWNORMAL    │ Skew-normal distribution     │
│ TDISTRIBUTION │ t-distribution               │
│ SKEWT         │ Skew-t distribution          │
│ PROBABILITY   │ Probability parameterization │
│ PROBIT        │ Probit link                  │
└───────────────┴──────────────────────────────┘
```

### ANALYSIS — Rotation

```
┌──────────────────┬────────────────────────────┐
│ Keyword          │ Description                │
├──────────────────┼────────────────────────────┤
│ GEOMIN           │ Geomin rotation            │
│ QUARTIMIN        │ Quartimin rotation         │
│ OBLIMIN          │ Oblimin rotation           │
│ VARIMAX          │ Varimax rotation           │
│ PROMAX           │ Promax rotation            │
│ TARGET           │ Target rotation            │
│ CRAWFER          │ Crawford-Ferguson rotation │
│ OBLIQUE          │ Oblique rotation           │
│ ORTHOGONAL       │ Orthogonal rotation        │
│ KAISER           │ Kaiser normalization       │
│ CF-VARIMAX*      │ CF varimax rotation        │
│ CF-QUARTIMAX*    │ CF quartimax rotation      │
│ CF-EQUAMAX*      │ CF equamax rotation        │
│ CF-PARSIMAX*     │ CF parsimax rotation       │
│ CF-FACPARSIM*    │ CF factor parsimony        │
│ BI-GEOMIN*       │ Bi-factor geomin rotation  │
│ BI-CF-QUARTIMAX* │ Bi-factor CF quartimax     │
└──────────────────┴────────────────────────────┘
* = syn match (contains hyphen)
```

### ANALYSIS — Resampling

```
┌────────────┬───────────────────────────────┐
│ Keyword    │ Description                   │
├────────────┼───────────────────────────────┤
│ JACKKNIFE  │ Jackknife estimation          │
│ JACKKNIFE1 │ Jackknife type 1              │
│ JACKKNIFE2 │ Jackknife type 2              │
│ BRR        │ Balanced repeated replication │
│ FAY        │ Fay's adjustment              │
│ REPSE      │ Replicated SE method          │
└────────────┴───────────────────────────────┘
```

### ANALYSIS — Bayesian

```
┌──────────────┬────────────────────────────────┐
│ Keyword      │ Description                    │
├──────────────┼────────────────────────────────┤
│ BITERATIONS  │ Bayesian iterations            │
│ FBITERATIONS │ Fixed Bayesian iterations      │
│ CHAINS       │ Number of MCMC chains          │
│ BSEED        │ Bayesian seed                  │
│ BCONVERGENCE │ Bayesian convergence criterion │
│ THIN         │ MCMC thinning interval         │
│ MDITERATIONS │ Mode iterations                │
│ KOLMOGOROV   │ Kolmogorov-Smirnov test        │
│ PRIOR        │ Prior specification            │
│ GIBBS        │ Gibbs sampler                  │
└──────────────┴────────────────────────────────┘
```

### ANALYSIS — Other

```
┌────────────────────┬──────────────────────────────┐
│ Keyword            │ Description                  │
├────────────────────┼──────────────────────────────┤
│ LRTBOOTSTRAP       │ LRT bootstrap test           │
│ MULTIPLIER         │ Multiplier adjustment        │
│ ADDFREQUENCY       │ Add frequency                │
│ RITERATIONS        │ Ridging iterations           │
│ AITERATIONS        │ Acceleration iterations      │
│ RLOGCRITERION      │ Ridging log criterion        │
│ RCONVERGENCE       │ Ridging convergence          │
│ ACONVERGENCE       │ Acceleration convergence     │
│ SIMPLICITY         │ Simplicity function          │
│ TOLERANCE          │ Tolerance criterion          │
│ POINT              │ Point estimate               │
│ STVALUES           │ Starting values              │
│ PREDICTOR          │ Predictor specification      │
│ INTERACTIVE        │ Interactive mode             │
│ DISTRIBUTION       │ Distribution specification   │
│ ROTATION           │ Rotation method              │
│ ROWSTANDARDIZATION │ Row standardization          │
│ METRIC             │ Alignment metric             │
│ NESTED             │ Nested model specification   │
│ UW                 │ Unrotated within (EFA)       │
│ UB                 │ Unrotated between (EFA)      │
│ LRTSTARTS          │ LRT random starts            │
│ RSTARTS            │ Random starts (ridging)      │
│ ASTARTS            │ Acceleration starts          │
│ H1STARTS           │ H1 model starts              │
│ K-1STARTS*         │ K-1 random starts            │
│ RESCOVARIANCES     │ Residual covariances         │
│ RESCOV             │ Residual covariances (short) │
│ UNPERTURBED        │ Unperturbed start values     │
│ PERTURBED          │ Perturbed start values       │
│ FS                 │ Fisher scoring algorithm     │
│ MH                 │ Metropolis-Hastings sampler  │
└────────────────────┴──────────────────────────────┘
* = syn match (contains hyphen)
```

### SAVEDATA

```
┌─────────────────┬───────────────────────────────┐
│ Keyword         │ Description                   │
├─────────────────┼───────────────────────────────┤
│ MISSFLAG        │ Missing data flag value       │
│ RECORDLENGTH    │ Record length                 │
│ SIGBETWEEN      │ Significant between effects   │
│ ESTIMATES       │ Save parameter estimates      │
│ RANKING         │ Ranking information           │
│ FSCORES         │ Factor scores                 │
│ CPROBABILITIES  │ Class probabilities           │
│ BPARAMETERS     │ Bayesian parameter draws      │
│ BCHWEIGHTS      │ BCH weights                   │
│ PROPENSITY      │ Propensity scores             │
│ LRESPONSES      │ Latent responses              │
│ MFILE           │ Montecarlo output file        │
│ MNAMES          │ Montecarlo variable names     │
│ MFORMAT         │ Montecarlo format             │
│ MMISSING        │ Montecarlo missing flag       │
│ MSELECT         │ Montecarlo variable selection │
│ SAMPLE          │ Save sample data              │
│ RESULTS         │ Save results                  │
│ STDRESULTS      │ Save standardized results     │
│ STDDISTRIBUTION │ Standardized distribution     │
│ SAVE            │ Save specification            │
│ FACTORS         │ Save factor scores            │
│ KAPLANMEIER     │ Kaplan-Meier estimates        │
│ ESTBASELINE     │ Estimated baseline hazard     │
│ RESPONSE        │ Save response patterns        │
│ H5RESULTS       │ HDF5 results output           │
│ MAHALANOBIS     │ Mahalanobis distance          │
│ LOGLIKELIHOOD   │ Observation log-likelihood    │
│ INFLUENCE       │ Influence statistics          │
│ COOKS           │ Cook's distance               │
└─────────────────┴───────────────────────────────┘
```

### PLOT

```
┌─────────────┬───────────────────────────┐
│ Keyword     │ Description               │
├─────────────┼───────────────────────────┤
│ SERIES      │ Series plot specification │
│ OUTLIERS    │ Outlier plot              │
│ MONITOR     │ Convergence monitoring    │
│ SENSITIVITY │ Sensitivity analysis plot │
│ PLOT1       │ Plot type 1               │
│ PLOT2       │ Plot type 2               │
│ PLOT3       │ Plot type 3               │
│ DRIFT       │ Drift plot (continuous)   │
└─────────────┴───────────────────────────┘
```

### MONTECARLO

```
┌────────────┬───────────────────────────────┐
│ Keyword    │ Description                   │
├────────────┼───────────────────────────────┤
│ NREPS      │ Number of replications        │
│ SEED       │ Random seed                   │
│ GENERATE   │ Data generation specification │
│ CUTPOINTS  │ Cutpoints for categorization  │
│ GENCLASSES │ Generated latent classes      │
│ NCSIZES    │ Number of cluster sizes       │
│ CSIZES     │ Cluster sizes                 │
│ HAZARDC    │ Hazard function cutpoints     │
│ PATMISS    │ Missing data patterns         │
│ PATPROBS   │ Pattern probabilities         │
│ REPSAVE    │ Save replication results      │
│ STARTING   │ Starting values specification │
└────────────┴───────────────────────────────┘
```

### Confidence Intervals

```
┌─────────────┬─────────────────────────────────┐
│ Keyword     │ Description                     │
├─────────────┼─────────────────────────────────┤
│ SYMMETRIC   │ Symmetric confidence interval   │
│ BCBOOTSTRAP │ Bias-corrected bootstrap CI     │
│ EQTAIL      │ Equal-tail credibility interval │
│ HPD         │ Highest posterior density CI    │
└─────────────┴─────────────────────────────────┘
```

## Connectors (mplusSpeccom)

```
┌─────────┬────────────────────────────┐
│ Keyword │ Description                │
├─────────┼────────────────────────────┤
│ ARE     │ Variable list connector    │
│ IS      │ Value assignment connector │
│ =       │ Value assignment (syn IS)  │
└─────────┴────────────────────────────┘
```

## Match Patterns

```
┌─────────────────────────────────────────┬───────────┐
│ Pattern                                 │ Group     │
├─────────────────────────────────────────┼───────────┤
│ ^\d{2}/\d{2}/\d{4}\s+\d+:\d+\s+.M$      │ Header    │
│ ^SUMMARY OF DATA$                       │ Statement │
│ \C^\u[A-Z 0-9/,-]+$  (output only)      │ Header    │
│ ^(SECTION):  (input, column 1)          │ Section   │
│ ^(DATA|MODEL)(\s\S+)?:  (input)         │ Section   │
│ ^  (SECTION):  (output, 2-space indent) │ Section   │
│ %[^%]+%  (class/level labels)           │ Section   │
│ !.*$                                    │ Comment   │
└─────────────────────────────────────────┴───────────┘
```
