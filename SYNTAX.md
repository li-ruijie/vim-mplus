# Mplus Syntax Reference

Reference for syntax groups used by the vim-mplus plugin. Keywords are
case-insensitive. Keywords longer than 4 characters can be abbreviated
to as few as 4 characters; the syntax file highlights all intermediate
truncations.
Source: <https://www.statmodel.com/language.html>.

### Ambiguous 4-character abbreviations

The following keywords share a 4-character prefix with another keyword.
Use 5 or more characters to disambiguate.

```
┌──────┬──────────────────────────────────────┐
│ Abbr │ Keywords                             │
├──────┼──────────────────────────────────────┤
│ CENT │ CENTER, CENTERING                    │
│ CROS │ CROSSCLASSIFIED, CROSSTABS           │
│ DIFF │ DIFFERENCE, DIFFTEST                 │
│ ESTI │ ESTIMATES, ESTIMATOR                 │
│ FSCO │ FSCOEFFICIENT, FSCOMPARISON, FSCORES │
│ FULL │ FULLCORR, FULLCOV                    │
│ GENE │ GENERAL, GENERATE                    │
│ GROU │ GROUPING, GROUPMEAN                  │
│ IMPU │ IMPUTATION, IMPUTE                   │
│ INDI │ INDIRECT, INDIVIDUAL                 │
│ INTE │ INTEGRATION, INTERACTIVE             │
│ LOGI │ LOGISTIC, LOGIT                      │
│ LOGL │ LOGLIKELIHOOD, LOGLINEAR, LOGLOW     │
│ MEAN │ MEANS, MEANSTRUCTURE                 │
│ MISS │ MISSFLAG, MISSING                    │
│ NOCH │ NOCHECK, NOCHISQUARE                 │
│ OBLI │ OBLIMIN, OBLIQUE                     │
│ PROB │ PROBABILITIES, PROBABILITY, PROBIT   │
│ REPS │ REPSAVE, REPSE                       │
│ SAMP │ SAMPLE, SAMPSTAT                     │
│ SKEW │ SKEWNORMAL, SKEWT                    │
│ STAN │ STANDARD, STANDARDIZE, STANDARDIZED  │
│ STAR │ STARTING, STARTS                     │
│ TIME │ TIMECENSORED, TIMEMEASURES           │
│ VARI │ VARIABLE, VARIANCES, VARIMAX         │
└──────┴──────────────────────────────────────┘
```

## File Structure

```
mplus-inp.vim                    mplus-out.vim
(*.inp files)                    (*.out files)
     │                           (standalone — no shared base)
     │  runtime syntax/mplus.vim
     │
     ▼
  mplus.vim (shared)
┌─────────────────┐
│ case ignore     │
│ mplusTitle      │  ◄── TITLE body (to ;), no keywords
│ mplusString     │  ◄── "…" and '…' quoted strings
│ mplusStatement  │
│ mplusCommand    │
│ mplusModel      │  ◄── BY, ON, *, @, |, &, SQRT…
│ mplusNumber     │  ◄── integers, floats, E/D notation
│ mplusSpeccom    │
│ mplusComment    │  ◄── block comments have @Spell
│ mplusSection    │  ◄── %label% markers
│ mplusHeader     │  ◄── timestamp only
│ highlight links │
└─────────────────┘
     ▼
mplus-inp.vim adds:          mplus-out.vim defines:
  mplusFold regions            mplusComment  (! comments)
  matchgroup=mplusSection      mplusSection  (%labels%, indented headers)
  ^TITLE:  (contains mplusTitle) mplusHeader (timestamp + all-caps lines
                                              + mixed-case syn matches)
  ^(DATA|MODEL)(\s\S+)?:      mplusFold     (between all-caps headers
                                              + mixed-case fit headers)
                               \C^\s*\u[A-Z 0-9/,&():.*%=-]+$
```

## Highlight Groups

```
┌────────────────┬───────────┬──────────────────────────────────────┐
│ Group          │ Links To  │ Usage                                │
├────────────────┼───────────┼──────────────────────────────────────┤
│ mplusStatement │ Statement │ Top-level and OUTPUT option keywords │
│ mplusCommand   │ Statement │ Section-specific command options     │
│ mplusModel     │ Function  │ Model operators: BY, ON, *, @, |, &  │
│ mplusNumber    │ Number    │ Integers, floats, scientific (E/D)   │
│ mplusSection   │ Include   │ Section headers, %label% markers     │
│ mplusComment   │ Comment   │ Line comments (!) and block (!*…*!)  │
│ mplusSpeccom   │ Special   │ ARE, IS, = connectors                │
│ mplusHeader    │ Type      │ Timestamp and output headers         │
│ mplusTitle     │ String    │ TITLE section body (no keywords)     │
│ mplusString    │ String    │ Quoted strings ("…" and '…')         │
└────────────────┴───────────┴──────────────────────────────────────┘
```

## Section Headers (mplusSection)

Input files match at column 1; output files match with 2-space indent.
Compound headers (`MODEL X:`, `DATA X:`) are matched via `\(\s\+[^: \t]\+\)\?`.
Abbreviated section names are matched with `\w*` (e.g., `ANAL:` matches `ANALYSIS:`).
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
│ ON         │ Regression (= ON → Command)  │
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
│ END        │ End loop (END DO)            │
│ DIFFERENCE │ Parameter difference         │
│ SQRT       │ Square root function         │
│ EXP        │ Exponential function         │
│ LOG        │ Natural logarithm function   │
│ *          │ Start value / free parameter │
│ @          │ Fix parameter value          │
│ \|         │ Growth model pipe operator   │
│ &          │ Lag operator (e.g., f&1)     │
│ #          │ Category/inflation operator  │
│ [ ]        │ Thresholds/Means             │
│ ( )        │ Labels/Constraints           │
│ { }        │ Scale factors                │
│ $          │ Threshold separator          │
│ ~          │ Distribution (Bayesian)      │
│ + - /      │ Arithmetic operators         │
│ < >        │ Inequality constraints       │
│ N          │ Normal prior (Bayesian)      │
│ IG         │ Inverse Gamma prior          │
│ IW         │ Inverse Wishart prior        │
│ D          │ Dirichlet prior              │
│ EQ         │ Equal comparison             │
│ NE         │ Not equal comparison         │
│ GT         │ Greater than                 │
│ LT         │ Less than                    │
│ GE         │ Greater than or equal        │
│ LE         │ Less than or equal           │
│ AND        │ Logical AND                  │
│ OR         │ Logical OR                   │
│ NOT        │ Logical NOT                  │
└────────────┴──────────────────────────────┘
```

## Statement Keywords (mplusStatement)

### Top-Level

```
┌────────────┬────────────────────────────┐
│ Keyword    │ Description                │
├────────────┼────────────────────────────┤
│ ANALYSIS   │ Analysis section keyword   │
│ DATA       │ Data section keyword       │
│ DEFINE     │ Define section keyword     │
│ MODEL      │ Model section keyword      │
│ MONTECARLO │ Montecarlo section keyword │
│ OUTPUT     │ Output section keyword     │
│ PLOT       │ Plot section keyword       │
│ SAVEDATA   │ Savedata section keyword   │
│ TITLE      │ Title section keyword      │
│ VARIABLE   │ Variable section keyword   │
└────────────┴────────────────────────────┘
```

### Output Options

```
┌───────────────┬─────────────────────────────────┐
│ Keyword       │ Description                     │
├───────────────┼─────────────────────────────────┤
│ MODINDICES    │ Modification indices            │
│ RESIDUAL      │ Residual output                 │
│ SAMPSTAT      │ Sample statistics               │
│ STANDARDIZED  │ Standardized solution           │
│ STD           │ Unstandardized std solution     │
│ STDYX         │ StdYX standardized solution     │
│ STDY          │ StdY standardized solution      │
│ CINTERVAL     │ Confidence intervals            │
│ SVALUES       │ Starting values in output       │
│ NOCHISQUARE   │ Suppress chi-square test        │
│ NOSERROR      │ Suppress standard errors        │
│ H1SE          │ H1 model standard errors        │
│ H1TECH3       │ H1 model TECH3 output           │
│ H1MODEL       │ H1 model estimation             │
│ CROSSTABS     │ Cross-tabulations               │
│ FSCOEFFICIENT │ Factor score coefficients       │
│ FSDETERMINACY │ Factor score determinacy        │
│ FSCOMPARISON  │ Factor score comparison         │
│ LOGRANK       │ Log-rank test                   │
│ ALIGNMENT     │ Alignment optimization          │
│ ENTROPY       │ Entropy statistic               │
│ PATTERNS      │ Missing data patterns           │
│ PAIRS         │ Pairwise output                 │
│ CONSTRAINT    │ MODEL CONSTRAINT sub-section    │
│ INDIRECT      │ MODEL INDIRECT sub-section      │
│ POPULATION    │ MODEL POPULATION sub-section    │
│ PRIORS        │ MODEL PRIORS sub-section        │
│ COVERAGE      │ MODEL COVERAGE sub-section      │
│ TEST          │ MODEL TEST sub-section          │
│ TECH1–TECH16  │ Technical outputs 1 through 16  │
│ SYMMETRIC     │ Symmetric confidence interval   │
│ BCBOOTSTRAP   │ Bias-corrected bootstrap CI     │
│ EQTAIL        │ Equal-tail credibility interval │
│ HPD           │ Highest posterior density CI    │
└───────────────┴─────────────────────────────────┘
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
│ PLAUSIBLE     │ Plausible values          │
│ LATENT        │ Latent variable data      │
│ TWOPART       │ Two-part model            │
│ WIDETOLONG    │ Wide to long conversion   │
│ LONGTOWIDE    │ Long to wide conversion   │
│ FILE          │ Data file specification   │
└───────────────┴───────────────────────────┘
```

### VARIABLE

```
┌─────────────────┬───────────────────────────────┐
│ Keyword         │ Description                   │
├─────────────────┼───────────────────────────────┤
│ NAMES           │ Variable names                │
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
│ CATEGORICAL     │ Categorical variable decl     │
│ MISSING         │ Missing value code            │
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
│ TYPE             │ Analysis/data type              │
│ LINK             │ Link function                   │
│ PROCESSORS       │ Number of processors            │
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
┌──────────────────┬────────────────────────────────┐
│ Keyword          │ Description                    │
├──────────────────┼────────────────────────────────┤
│ NORMAL           │ Normal distribution            │
│ SKEWNORMAL       │ Skew-normal distribution       │
│ TDISTRIBUTION    │ t-distribution                 │
│ SKEWT            │ Skew-t distribution            │
│ PROBABILITY      │ Probability parameterization   │
│ PROBIT           │ Probit link                    │
│ POISSON          │ Poisson distribution           │
│ NEGATIVEBINOMIAL │ Negative binomial distribution │
│ ZIP              │ Zero-inflated Poisson          │
│ ZINB             │ Zero-inflated neg. binomial    │
│ GAMMA            │ Gamma distribution             │
└──────────────────┴────────────────────────────────┘
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
┌────────────────────┬─────────────────────────────┐
│ Keyword            │ Description                 │
├────────────────────┼─────────────────────────────┤
│ BASEHAZARD         │ Baseline hazard function    │
│ LRTBOOTSTRAP       │ LRT bootstrap test          │
│ MULTIPLIER         │ Multiplier adjustment       │
│ ADDFREQUENCY       │ Add frequency               │
│ RITERATIONS        │ Ridging iterations          │
│ AITERATIONS        │ Acceleration iterations     │
│ RLOGCRITERION      │ Ridging log criterion       │
│ RCONVERGENCE       │ Ridging convergence         │
│ ACONVERGENCE       │ Acceleration convergence    │
│ SIMPLICITY         │ Simplicity function         │
│ TOLERANCE          │ Tolerance criterion         │
│ POINT              │ Point estimate              │
│ STVALUES           │ Starting values             │
│ PREDICTOR          │ Predictor specification     │
│ INTERACTIVE        │ Interactive mode            │
│ DISTRIBUTION       │ Distribution specification  │
│ ROTATION           │ Rotation method             │
│ ROWSTANDARDIZATION │ Row standardization         │
│ METRIC             │ Alignment metric            │
│ NESTED             │ Nested model specification  │
│ UW                 │ Unrotated within (EFA)      │
│ UB                 │ Unrotated between (EFA)     │
│ LRTSTARTS          │ LRT random starts           │
│ RSTARTS            │ Random starts (ridging)     │
│ ASTARTS            │ Acceleration starts         │
│ H1STARTS           │ H1 model starts             │
│ K-1STARTS*         │ K-1 random starts           │
│ RESCOVARIANCES     │ Residual covariances        │
│ UNPERTURBED        │ Unperturbed start values    │
│ PERTURBED          │ Perturbed start values      │
│ FS                 │ Fisher scoring algorithm    │
│ MH                 │ Metropolis-Hastings sampler │
└────────────────────┴─────────────────────────────┘
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
│ POPULATION │ Population model values       │
└────────────┴───────────────────────────────┘
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
┌─────────────────────────────────────────┬─────────┐
│ Pattern                                 │ Group   │
├─────────────────────────────────────────┼─────────┤
│ ^\d{2}/\d{2}/\d{4}\s+\d+:\d+\s+.M$      │ Header  │
│ \C^\s*\u[A-Z 0-9/,&():.*%=-]+$ (output) │ Header  │
│ Mixed-case fit headers (output)         │ Header  │
│ ^(SECTION):  (input, column 1)          │ Section │
│ ^(DATA|MODEL)(\s[^: \t]+)?:  (input)    │ Section │
│ ^  (SECTION):  (output, 2-space indent) │ Section │
│ %[^%]+%  (class/level labels)           │ Section │
│ -?\d+\.?\d*([EDed][-+]?\d+)?            │ Number  │
│ -?.\d+([EDed][-+]?\d+)?                 │ Number  │
│ * (start value), @ (fix value)          │ Model   │
│ \<ON\> (model operator by default)      │ Model   │
│ \%(=\s*\)\@<=\<ON\> (setting value)     │ Command │
│ !.*$                                    │ Comment │
│ ^\s*!\*...\*! (block comment, @Spell)   │ Comment │
│ ^TITLE\> ... ;  (TITLE body region)     │ Title   │
│ "…" and '…' (quoted strings)            │ String  │
└─────────────────────────────────────────┴─────────┘
```

## Abbreviations

Complete list of keywords and their abbreviated forms, generated from
the syntax files. Each keyword is followed by all valid truncations
(4 characters through one less than the full keyword). See the
ambiguity table above for 4-character prefixes shared by multiple
keywords.

### mplusStatement

```
ALIGNMENT      ALIG ALIGN ALIGNM ALIGNME ALIGNMEN
ANALYSIS       ANAL ANALY ANALYS ANALYSI
BCBOOTSTRAP    BCBO BCBOO BCBOOT BCBOOTS BCBOOTST BCBOOTSTR BCBOOTSTRA
CINTERVAL      CINTE CINTER CINTERV CINTERVA
CONSTRAINT     CONS CONST CONSTR CONSTRA CONSTRAI CONSTRAIN
COVERAGE       COVE COVER COVERA COVERAG
CROSSTABS      CROS CROSS CROSST CROSSTA CROSSTAB
DEFINE         DEFI DEFIN
ENTROPY        ENTR ENTRO ENTROP
EQTAIL         EQTA EQTAI
FSCOEFFICIENT  FSCO FSCOE FSCOEF FSCOEFF FSCOEFFI FSCOEFFIC FSCOEFFICI
               FSCOEFFICIE FSCOEFFICIEN
FSCOMPARISON   FSCO FSCOM FSCOMP FSCOMPA FSCOMPAR FSCOMPARI FSCOMPARIS
               FSCOMPARISO
FSDETERMINACY  FSDE FSDET FSDETE FSDETER FSDETERM FSDETERMI FSDETERMIN
               FSDETERMINA FSDETERMINAC
H1MODEL        H1MO H1MOD H1MODE
H1TECH3        H1TE H1TEC H1TECH
INDIRECT       INDI INDIR INDIRE INDIREC
LOGRANK        LOGR LOGRA LOGRAN
MODEL
MODINDICES     MODI MODIN MODIND MODINDI MODINDIC MODINDICE
MONTECARLO     MONT MONTE MONTEC MONTECA MONTECAR MONTECARL
NOCHISQUARE    NOCH NOCHI NOCHIS NOCHISQ NOCHISQU NOCHISQUA NOCHISQUAR
NOSERROR       NOSE NOSER NOSERR NOSERRO
OUTPUT         OUTP OUTPU
PAIRS          PAIR
PATTERNS       PATT PATTE PATTER PATTERN
POPULATION     POPU POPUL POPULA POPULAT POPULATI POPULATIO
PRIORS         PRIO PRIOR
RESIDUAL       RESI RESID RESIDU RESIDUA
SAMPSTAT       SAMP SAMPS SAMPST SAMPSTA
SAVEDATA       SAVED SAVEDA SAVEDAT
STANDARDIZED
STDYX          STDY
SVALUES        SVAL SVALU SVALUE
SYMMETRIC      SYMM SYMME SYMMET SYMMETR SYMMETRI
TECH1          TECH
TECH10         TECH TECH1
TECH11         TECH TECH1
TECH12         TECH TECH1
TECH13         TECH TECH1
TECH14         TECH TECH1
TECH15         TECH TECH1
TECH16         TECH TECH1
TECH2          TECH
TECH3          TECH
TECH4          TECH
TECH5          TECH
TECH6          TECH
TECH7          TECH
TECH8          TECH
TECH9          TECH
TITLE          TITL
VARIABLE       VARI VARIA VARIAB VARIABL
```

### mplusCommand

```
ACONVERGENCE        ACON ACONV ACONVE ACONVER ACONVERG ACONVERGE ACONVERGEN
                    ACONVERGENC
ADAPTIVE            ADAP ADAPT ADAPTI ADAPTIV
ADDFREQUENCY        ADDF ADDFR ADDFRE ADDFREQ ADDFREQU ADDFREQUE ADDFREQUEN
                    ADDFREQUENC
AITERATIONS         AITE AITER AITERA AITERAT AITERATI AITERATIO AITERATION
ALGORITHM           ALGO ALGOR ALGORI ALGORIT ALGORITH
ALLFREE             ALLF ALLFR ALLFRE
ARIMA               ARIM
ASTARTS             ASTA ASTAR ASTART
AUXILIARY           AUXI AUXIL AUXILI AUXILIA AUXILIAR
B2WEIGHT            B2WE B2WEI B2WEIG B2WEIGH
B3WEIGHT            B3WE B3WEI B3WEIG B3WEIGH
BASEHAZARD          BASE BASEH BASEHA BASEHAZ BASEHAZA BASEHAZAR
BASIC               BASI
BAYES               BAYE
BCHWEIGHTS          BCHW BCHWE BCHWEI BCHWEIG BCHWEIGH BCHWEIGHT
BCONVERGENCE        BCON BCONV BCONVE BCONVER BCONVERG BCONVERGE BCONVERGEN
                    BCONVERGENC
BESEM               BESE
BETWEEN             BETW BETWE BETWEE
BINARY              BINA BINAR
BITERATIONS         BITE BITER BITERA BITERAT BITERATI BITERATIO BITERATION
BOOTSTRAP           BOOT BOOTS BOOTST BOOTSTR BOOTSTRA
BPARAMETERS         BPAR BPARA BPARAM BPARAME BPARAMET BPARAMETE BPARAMETER
BSEED               BSEE
BWEIGHT             BWEI BWEIG BWEIGH
BWTSCALE            BWTS BWTSC BWTSCA BWTSCAL
CATEGORICAL         CATE CATEG CATEGO CATEGOR CATEGORI CATEGORIC CATEGORICA
CENSORED            CENS CENSO CENSOR CENSORE
CENTER              CENT CENTE
CENTERING           CENTERI CENTERIN
CHAINS              CHAI CHAIN
CHECK               CHEC
CHOLESKY            CHOL CHOLE CHOLES CHOLESK
CLASS               CLAS
CLASSES             CLAS CLASS CLASSE
CLUSTER             CLUS CLUST CLUSTE
CLUSTER_MEAN        CLUS CLUST CLUSTE CLUSTER CLUSTER_ CLUSTER_M CLUSTER_ME
                    CLUSTER_MEA
COHORT              COHO COHOR
COHRECODE           COHR COHRE COHREC COHRECO COHRECOD
COMBINATION         COMB COMBI COMBIN COMBINA COMBINAT COMBINATI COMBINATIO
COMPLEX             COMP COMPL COMPLE
CONFIGURAL          CONF CONFI CONFIG CONFIGU CONFIGUR CONFIGURA
CONTINUOUS          CONT CONTI CONTIN CONTINU CONTINUO CONTINUOU
CONVERGENCE         CONV CONVE CONVER CONVERG CONVERGE CONVERGEN CONVERGENC
COOKS               COOK
COPATTERN           COPA COPAT COPATT COPATTE COPATTER
CORRELATION         CORR CORRE CORREL CORRELA CORRELAT CORRELATI CORRELATIO
COUNT               COUN
COVARIANCE          COVA COVAR COVARI COVARIA COVARIAN COVARIANC
CPROBABILITIES      CPRO CPROB CPROBA CPROBAB CPROBABI CPROBABIL CPROBABILI
                    CPROBABILIT CPROBABILITI CPROBABILITIE
CRAWFER             CRAW CRAWF CRAWFE
CROSSCLASSIFIED     CROS CROSS CROSSC CROSSCL CROSSCLA CROSSCLAS
                    CROSSCLASSI CROSSCLASSIF CROSSCLASSIFI CROSSCLASSIFIE
CSIZES              CSIZ CSIZE
CTIME               CTIM
CUTPOINT            CUTP CUTPO CUTPOI CUTPOIN
CUTPOINTS           CUTP CUTPO CUTPOI CUTPOIN CUTPOINT
D3STEP              D3ST D3STE
D3STEPC             D3ST D3STE D3STEP
DCATEGORICAL        DCAT DCATE DCATEG DCATEGO DCATEGOR DCATEGORI DCATEGORIC
                    DCATEGORICA
DCONTINUOUS         DCON DCONT DCONTI DCONTIN DCONTINU DCONTINUO DCONTINUOU
DDROPOUT            DDRO DDROP DDROPO DDROPOU
DE3STEP             DE3S DE3ST DE3STE
DELTA               DELT
DESCRIPTIVE         DESC DESCR DESCRI DESCRIP DESCRIPT DESCRIPTI DESCRIPTIV
DIFFTEST            DIFF DIFFT DIFFTE DIFFTES
DISTRIBUTION        DIST DISTR DISTRI DISTRIB DISTRIBU DISTRIBUT DISTRIBUTI
                    DISTRIBUTIO
DRIFT               DRIF
DSURVIVAL           DSUR DSURV DSURVI DSURVIV DSURVIVA
DU3STEP             DU3S DU3ST DU3STE
ESTBASELINE         ESTB ESTBA ESTBAS ESTBASE ESTBASEL ESTBASELI ESTBASELIN
ESTIMATES           ESTI ESTIM ESTIMA ESTIMAT ESTIMATE
ESTIMATOR           ESTI ESTIM ESTIMA ESTIMAT ESTIMATO
EXPECTED            EXPE EXPEC EXPECT EXPECTE
FACTORS             FACT FACTO FACTOR
FBITERATIONS        FBIT FBITE FBITER FBITERA FBITERAT FBITERATI FBITERATIO
                    FBITERATION
FINITE              FINI FINIT
FORMAT              FORM FORMA
FREQWEIGHT          FREQ FREQW FREQWE FREQWEI FREQWEIG FREQWEIGH
FSCORES             FSCO FSCOR FSCORE
FULLCOV             FULL FULLC FULLCO FULLCOR
GAMMA               GAMM
GAUSSHERMITE        GAUS GAUSS GAUSSH GAUSSHE GAUSSHER GAUSSHERM GAUSSHERMI
                    GAUSSHERMIT
GENCLASS            GENC GENCL GENCLA GENCLAS
GENCLASSES          GENC GENCL GENCLA GENCLAS GENCLASS GENCLASSE
GENERAL             GENE GENER GENERA
GENERATE            GENE GENER GENERA GENERAT
GEOMIN              GEOM GEOMI
GIBBS               GIBB
GRANDMEAN           GRAN GRAND GRANDM GRANDME GRANDMEA
GROUPING            GROU GROUP GROUPI GROUPIN
GROUPMEAN           GROU GROUP GROUPM GROUPME GROUPMEA
H1CONVERGENCE       H1CO H1CON H1CONV H1CONVE H1CONVER H1CONVERG H1CONVERGE
                    H1CONVERGEN H1CONVERGENC
H1ITERATIONS        H1IT H1ITE H1ITER H1ITERA H1ITERAT H1ITERATI H1ITERATIO
                    H1ITERATION
H1STARTS            H1ST H1STA H1STAR H1START
H5RESULTS           H5RE H5RES H5RESU H5RESUL H5RESULT
HAZARDC             HAZA HAZAR HAZARD
IDVARIABLE          IDVA IDVAR IDVARI IDVARIA IDVARIAB IDVARIABL
IMPUTATION          IMPU IMPUT IMPUTA IMPUTAT IMPUTATI IMPUTATIO
IMPUTE              IMPU IMPUT
INDIVIDUAL          INDI INDIV INDIVI INDIVID INDIVIDU INDIVIDUA
INFLUENCE           INFL INFLU INFLUE INFLUEN INFLUENC
INFORMATION         INFOR INFORM INFORMA INFORMAT INFORMATI INFORMATIO
INTEGRATION         INTE INTEG INTEGR INTEGRA INTEGRAT INTEGRATI INTEGRATIO
INTERACTIVE         INTE INTER INTERA INTERAC INTERACT INTERACTI INTERACTIV
ITERATIONS          ITERS ITERA ITERAT ITERATI ITERATIO
JACKKNIFE           JACK JACKK JACKKN JACKKNI JACKKNIF
JACKKNIFE1          JACK JACKK JACKKN JACKKNI JACKKNIF JACKKNIFE
JACKKNIFE2          JACK JACKK JACKKN JACKKNI JACKKNIF JACKKNIFE
KAISER              KAIS KAISE
KAPLANMEIER         KAPL KAPLA KAPLAN KAPLANM KAPLANME KAPLANMEI KAPLANMEIE
KNOWNCLASS          KNOW KNOWN KNOWNC KNOWNCL KNOWNCLA KNOWNCLAS
KOLMOGOROV          KOLM KOLMO KOLMOG KOLMOGO KOLMOGOR KOLMOGORO
LAGGED              LAGG LAGGE
LATENT              LATE LATEN
LISTWISE            LISTW LISTWI LISTWIS
LOGCRITERION        LOGC LOGCR LOGCRI LOGCRIT LOGCRITE LOGCRITER LOGCRITERI
                    LOGCRITERIO
LOGHIGH             LOGH LOGHI LOGHIG
LOGISTIC            LOGI LOGIS LOGIST LOGISTI
LOGIT               LOGI
LOGLIKELIHOOD       LOGL LOGLI LOGLIK LOGLIKE LOGLIKEL LOGLIKELI LOGLIKELIH
                    LOGLIKELIHO LOGLIKELIHOO
LOGLINEAR           LOGL LOGLI LOGLIN LOGLINE LOGLINEA
LOGLOW              LOGL LOGLO
LONGTOWIDE          LONG LONGT LONGTO LONGTOW LONGTOWI LONGTOWID
LRESPONSES          LRES LRESP LRESPO LRESPON LRESPONS LRESPONSE
LRTBOOTSTRAP        LRTB LRTBO LRTBOO LRTBOOT LRTBOOTS LRTBOOTST LRTBOOTSTR
                    LRTBOOTSTRA
LRTSTARTS           LRTS LRTST LRTSTA LRTSTAR LRTSTART
MAHALANOBIS         MAHA MAHAL MAHALA MAHALAN MAHALANO MAHALANOB MAHALANOBI
MATRIX              MATR MATRI
MCCONVERGENCE       MCCO MCCON MCCONV MCCONVE MCCONVER MCCONVERG MCCONVERGE
                    MCCONVERGEN MCCONVERGENC
MCITERATIONS        MCIT MCITE MCITER MCITERA MCITERAT MCITERATI MCITERATIO
                    MCITERATION
MCOHORT             MCOH MCOHO MCOHOR
MCONVERGENCE        MCON MCONV MCONVE MCONVER MCONVERG MCONVERGE MCONVERGEN
                    MCONVERGENC
MCSEED              MCSE MCSEE
MDITERATIONS        MDIT MDITE MDITER MDITERA MDITERAT MDITERATI MDITERATIO
                    MDITERATION
MEANS               MEAN
MEANSTRUCTURE       MEAN MEANS MEANST MEANSTR MEANSTRU MEANSTRUC MEANSTRUCT
                    MEANSTRUCTU MEANSTRUCTUR
MEMBERSHIP          MEMB MEMBE MEMBER MEMBERS MEMBERSI MEMBERSHI
METRIC              METR METRI
MFILE               MFIL
MFORMAT             MFOR MFORM MFORMA
MISSFLAG            MISS MISSF MISSFL MISSFLA
MISSING             MISS MISSI MISSIN
MITERATIONS         MITE MITER MITERA MITERAT MITERATI MITERATIO MITERATION
MIXTURE             MIXT MIXTU MIXTUR
MMISSING            MMIS MMISS MMISSI MMISSIN
MNAMES              MNAM MNAME
MONITOR             MONI MONIT MONITO
MSELECT             MSEL MSELE MSELEC
MUCONVERGENCE       MUCO MUCON MUCONV MUCONVE MUCONVER MUCONVERG MUCONVERGE
                    MUCONVERGEN MUCONVERGENC
MUITERATIONS        MUIT MUITE MUITER MUITERA MUITERAT MUITERATI MUITERATIO
                    MUITERATION
MULTIPLIER          MULT MULTI MULTIP MULTIPL MULTIPLI MULTIPLIE
NAMES               NAME
NCSIZES             NCSI NCSIZ NCSIZE
NDATASETS           NDAT NDATA NDATAS NDATASE NDATASET
NEGATIVEBINOMIAL    NEGA NEGAT NEGATI NEGATIV NEGATIVE NEGATIVEB NEGATIVEBI
                    NEGATIVEBIN NEGATIVEBINO NEGATIVEBINOM NEGATIVEBINOMI
                    NEGATIVEBINOMIA
NESTED              NEST NESTE
NGROUPS             NGRO NGROU NGROUP
NOBSERVATIONS       NOBS NOBSE NOBSER NOBSERV NOBSERVA NOBSERVAT NOBSERVATI
                    NOBSERVATIO
NOCHECK             NOCH NOCHE NOCHEC
NOCOVARIANCES       NOCO NOCOV NOCOVA NOCOVAR NOCOVARI NOCOVARIA NOCOVARIAN
                    NOCOVARIANC NOCOVARIANCE
NOMEANSTRUCTURE     NOME NOMEA NOMEAN NOMEANS NOMEANST NOMEANSTR NOMEANSTRU
                    NOMEANSTRUC NOMEANSTRUCT NOMEANSTRUCTU NOMEANSTRUCTUR
NOMINAL             NOMI NOMIN NOMINA
NORMAL              NORM NORMA
NREPS               NREP
OBLIMIN             OBLI OBLIM OBLIMI
OBLIQUE             OBLI OBLIQ OBLIQU
OBSERVED            OBSE OBSER OBSERV OBSERVE
OPTSEED             OPTS OPTSE OPTSEE
ORTHOGONAL          ORTH ORTHO ORTHOG ORTHOGO ORTHOGON ORTHOGONA
OUTLIERS            OUTL OUTLI OUTLIE OUTLIER
PARAMETERIZATION    PARA PARAM PARAME PARAMET PARAMETE PARAMETER PARAMETERI
                    PARAMETERIZ PARAMETERIZA PARAMETERIZAT PARAMETERIZATI
                    PARAMETERIZATIO
PATMISS             PATM PATMI PATMIS
PATPROBS            PATP PATPR PATPRO PATPROB
PATTERN             PATT PATTE PATTER
PERTURBED           PERT PERTU PERTUR PERTURB PERTURBE
PLAUSIBLE           PLAU PLAUS PLAUSI PLAUSIB PLAUSIBL
PLOT1               PLOT
PLOT2               PLOT
PLOT3               PLOT
POINT               POIN
POISSON             POIS POISS POISSO
PREDICTOR           PRED PREDI PREDIC PREDICT PREDICTO
PRIOR               PRIO
PROBABILITIES       PROB PROBA PROBAB PROBABI PROBABIL PROBABILI PROBABILIT
                    PROBABILITI PROBABILITIE
PROBABILITY         PROB PROBA PROBAB PROBABI PROBABIL PROBABILI PROBABILIT
PROBIT              PROB PROBI
PROCESSORS          PROC PROCE PROCES PROCESS PROCESSO PROCESSOR
PROMAX              PROM PROMA
PROPENSITY          PROP PROPE PROPEN PROPENS PROPENSI PROPENSIT
QUARTIMIN           QUAR QUART QUARTI QUARTIM QUARTIMI
R3STEP              R3ST R3STE
RANDOM              RAND RANDO
RANKING             RANK RANKI RANKIN
RCONVERGENCE        RCON RCONV RCONVE RCONVER RCONVERG RCONVERGE RCONVERGEN
                    RCONVERGENC
RECORDLENGTH        RECO RECOR RECORD RECORDL RECORDLE RECORDLEN RECORDLENG
                    RECORDLENGT
REPETITION          REPE REPET REPETI REPETIT REPETITI REPETITIO
REPSAVE             REPS REPSA REPSAV
REPSE               REPS
REPWEIGHTS          REPW REPWE REPWEI REPWEIG REPWEIGH REPWEIGHT
RESCOV              RESC RESCO
RESCOVARIANCES      RESC RESCO RESCOV RESCOVA RESCOVAR RESCOVARI RESCOVARIA
                    RESCOVARIAN RESCOVARIANC RESCOVARIANCE
RESPONSE            RESP RESPO RESPON RESPONS
RESULTS             RESU RESUL RESULT
RITERATIONS         RITE RITER RITERA RITERAT RITERATI RITERATIO RITERATION
RLOGCRITERION       RLOG RLOGC RLOGCR RLOGCRI RLOGCRIT RLOGCRITE RLOGCRITER
                    RLOGCRITERI RLOGCRITERIO
ROTATION            ROTA ROTAT ROTATI ROTATIO
ROWSTANDARDIZATION  ROWS ROWST ROWSTA ROWSTAN ROWSTAND ROWSTANDA ROWSTANDAR
                    ROWSTANDARD ROWSTANDARDI ROWSTANDARDIZ ROWSTANDARDIZA
                    ROWSTANDARDIZAT ROWSTANDARDIZATI ROWSTANDARDIZATIO
RSTARTS             RSTA RSTAR RSTART
SAMPLE              SAMP SAMPL
SCALAR              SCAL SCALA
SDITERATIONS        SDIT SDITE SDITER SDITERA SDITERAT SDITERATI SDITERATIO
                    SDITERATION
SDROPOUT            SDRO SDROP SDROPO SDROPOU
SENSITIVITY         SENS SENSI SENSIT SENSITI SENSITIV SENSITIVI SENSITIVIT
SERIES              SERI SERIE
SIGBETWEEN          SIGB SIGBE SIGBET SIGBETW SIGBETWE SIGBETWEE
SIMPLICITY          SIMP SIMPL SIMPLI SIMPLIC SIMPLICI SIMPLICIT
SKEWNORMAL          SKEW SKEWN SKEWNO SKEWNOR SKEWNORM SKEWNORMA
SKEWT               SKEW
STANDARDIZE         STAN STAND STANDA STANDAR STANDARD STANDARDI STANDARDIZ
STARTING            STAR START STARTI STARTIN
STARTS              STAR START
STCONVERGENCE       STCO STCON STCONV STCONVE STCONVER STCONVERG STCONVERGE
                    STCONVERGEN STCONVERGENC
STDDISTRIBUTION     STDD STDDI STDDIS STDDIST STDDISTR STDDISTRI STDDISTRIB
                    STDDISTRIBU STDDISTRIBUT STDDISTRIBUTI STDDISTRIBUTIO
STDEVIATIONS        STDE STDEV STDEVI STDEVIA STDEVIAT STDEVIATI STDEVIATIO
                    STDEVIATION
STDRESULTS          STDR STDRE STDRES STDRESU STDRESUL STDRESULT
STITERATIONS        STIT STITE STITER STITERA STITERAT STITERATI STITERATIO
                    STITERATION
STRATIFICATION      STRA STRAT STRATI STRATIF STRATIFI STRATIFIC STRATIFICA
                    STRATIFICAT STRATIFICATI STRATIFICATIO
STSCALE             STSC STSCA STSCAL
STSEED              STSE STSEE
STVALUES            STVA STVAL STVALU STVALUE
SUBPOPULATION       SUBP SUBPO SUBPOP SUBPOPU SUBPOPUL SUBPOPULA SUBPOPULAT
                    SUBPOPULATI SUBPOPULATIO
SURVIVAL            SURV SURVI SURVIV SURVIVA
SWMATRIX            SWMA SWMAT SWMATR SWMATRI
TARGET              TARG TARGE
TDISTRIBUTION       TDIS TDIST TDISTR TDISTRI TDISTRIB TDISTRIBU TDISTRIBUT
                    TDISTRIBUTI TDISTRIBUTIO
THETA               THET
THREELEVEL          THRE THREE THREELE THREELEV THREELEVE
TIMECENSORED        TIME TIMEC TIMECE TIMECEN TIMECENS TIMECENSO TIMECENSOR
                    TIMECENSORE
TIMEMEASURES        TIME TIMEM TIMEME TIMEMEA TIMEMEAS TIMEMEASU TIMEMEASUR
                    TIMEMEASURE
TINTERVAL           TINT TINTE TINTER TINTERV TINTERVA
TNAMES              TNAM TNAME
TOLERANCE           TOLE TOLER TOLERA TOLERAN TOLERANC
TRAINING            TRAI TRAIN TRAINI TRAININ
TRANSFORM           TRAN TRANS TRANSF TRANSFO TRANSFOR
TSCORES             TSCO TSCOR TSCORE
TWOLEVEL            TWOL TWOLE TWOLEV TWOLEVE
TWOPART             TWOP TWOPA TWOPAR
UCELLSIZE           UCEL UCELL UCELLS UCELLSI UCELLSIZ
ULSMV               ULSM
UNPERTURBED         UNPE UNPER UNPERT UNPERTU UNPERTUR UNPERTURB UNPERTURBE
USEOBS              USEO USEOB
USEOBSERVATIONS     USEO USEOB USEOBS USEOBSE USEOBSER USEOBSERV USEOBSERVA
                    USEOBSERVAT USEOBSERVATI USEOBSERVATIO USEOBSERVATION
USEVAR              USEV USEVA
USEVARIABLES        USEV USEVA USEVAR USEVARI USEVARIA USEVARIAB USEVARIABL
                    USEVARIABLE
VARIANCE            VARI VARIA VARIAN VARIANC
VARIANCES           VARI VARIA VARIAN VARIANC VARIANCE
VARIMAX             VARI VARIM VARIMA
WEIGHT              WEIG WEIGH
WIDETOLONG          WIDE WIDET WIDETO WIDETOL WIDETOLO WIDETOLON
WITHIN              WITHI
WLSMV               WLSM
WTSCALE             WTSC WTSCA WTSCAL
```

### mplusModel

```
DIFFERENCE  DIFF DIFFE DIFFER DIFFERE DIFFEREN DIFFERENC
PWITH       PWIT
XWITH       XWIT
```
