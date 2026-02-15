" Vim syntax file
" Language:    Mplus (shared rules)
" URL:         https://github.com/li-ruijie/vim-mplus
" Reference:   https://www.statmodel.com/language.html

setlocal iskeyword+=:
syn case ignore

"" Timestamp header (e.g., 01/15/2026  10:30  AM)
syn match mplusHeader "^\d\{2}\/\d\{2}\/\d\{4}\s\+\d\+:\d\+\s\+.M$"

"" Comments
syn match mplusComment "!.*$"

"" Class/level labels (%OVERALL%, %c#1%, %BETWEEN subject%, etc.)
syn match mplusSection "%[^%]\+%"

"" Numbers: integers, floats, scientific notation (1.5E-3, 0.100D-05)
syn match mplusNumber "-\?\d\+\.\?\d*\([EDed][-+]\?\d\+\)\?"
syn match mplusNumber "-\?\.\d\+\([EDed][-+]\?\d\+\)\?"

"" Parameter operators: * (start value/free), @ (fix value)
syn match mplusModel "\*"
syn match mplusModel "@"
syn match mplusModel "#"
syn match mplusModel "\["
syn match mplusModel "\]"
syn match mplusModel "("
syn match mplusModel ")"

"" Match patterns
syn match mplusStatement "^SUMMARY OF DATA$"

"" Statement keywords
syn keyword mplusStatement ANALYSIS CATEGORICAL DEFINE FILE LINK MISSING SAVEDATA
syn match   mplusStatement "\<DATA\>"
syn match   mplusStatement "\<MODEL\>"
syn keyword mplusStatement MODINDICES NAMES OUTPUT PLOT PROCESSORS RESIDUAL SAMPSTAT STANDARDIZED
syn keyword mplusStatement STD STDYX TITLE TYPE USEVAR USEV USEVARIABLE VARIABLE
syn keyword mplusStatement TECH1 TECH2 TECH3 TECH4 TECH5 TECH6 TECH7 TECH8
syn keyword mplusStatement TECH9 TECH10 TECH11 TECH12 TECH13 TECH14 TECH15 TECH16

"" Output options
syn keyword mplusStatement STDY CINTERVAL SVALUES NOCHISQUARE NOSERROR H1SE
syn keyword mplusStatement H1TECH3 H1MODEL CROSSTABS FSCOEFFICIENT FSDETERMINACY
syn keyword mplusStatement FSCOMPARISON BASEHAZARD LOGRANK ALIGNMENT ENTROPY MONTECARLO
syn keyword mplusStatement PATTERNS

"" Model operators
syn keyword mplusModel WITH BY ON PWITH AT XWITH IND VIA ALL
syn keyword mplusModel PON NEW MOD LOOP DO DIFF DIFFERENCE SQRT EXP LOG
syn match   mplusModel "|"
syn match   mplusModel "&"

"" Connectors
syn keyword mplusSpeccom ARE IS
syn match   mplusSpeccom "="

"" --- Data command ---
syn keyword mplusCommand INDIVIDUAL COVARIANCE CORRELATION FULLCOV
syn keyword mplusCommand FULLCORR MEANS STDEVIATIONS IMPUTATION
syn keyword mplusCommand NOBSERVATIONS NGROUPS VARIANCES CHECK NOCHECK FREE
syn keyword mplusCommand LISTWISE SWMATRIX NDATASETS WIDE LONG REPETITION
syn keyword mplusCommand CUTPOINT TRANSFORM IMPUTE BINARY CONTINUOUS
syn keyword mplusCommand DESCRIPTIVE DDROPOUT SDROPOUT
syn keyword mplusCommand TWOPART WIDETOLONG LONGTOWIDE

"" --- Variable command ---
syn keyword mplusCommand USEOBSERVATIONS USEVARIABLES CENSORED
syn keyword mplusCommand NOMINAL COUNT GROUPING IDVARIABLE WEIGHT FORMAT
syn keyword mplusCommand CLUSTER STRATIFICATION CENTERING TSCORES AUXILIARY CLASSES
syn keyword mplusCommand KNOWNCLASS TRAINING WITHIN BETWEEN PATTERN COHORT COPATTERN
syn keyword mplusCommand COHRECODE TIMEMEASURES TNAMES MEMBERSHIP PROBABILITIES
syn keyword mplusCommand DSURVIVAL FREQWEIGHT WTSCALE REPWEIGHTS SUBPOPULATION
syn keyword mplusCommand SURVIVAL TIMECENSORED LAGGED TINTERVAL
syn keyword mplusCommand BWEIGHT B2WEIGHT B3WEIGHT BWTSCALE FINITE CTIME
syn keyword mplusCommand R3STEP BCH DU3STEP DE3STEP D3STEP D3STEPC BCHC
syn keyword mplusCommand DCATEGORICAL DCONTINUOUS

"" --- Define command ---
syn keyword mplusCommand IF THEN CUT
syn keyword mplusCommand CENTER STANDARDIZE GRANDMEAN GROUPMEAN CLUSTER_MEAN

"" --- Analysis command ---
"" Types and estimators
syn keyword mplusCommand ESTIMATOR PARAMETERIZATION CHOLESKY ALGORITHM MCSEED ADAPTIVE
syn keyword mplusCommand INFORMATION BOOTSTRAP DIFFTEST STARTS STITERATIONS STCONVERGENCE
syn keyword mplusCommand STSCALE STSEED OPTSEED COVERAGE SDITERATIONS H1ITERATIONS
syn keyword mplusCommand MITERATIONS MCITERATIONS MUITERATIONS H1CONVERGENCE LOGCRITERION
syn keyword mplusCommand MCONVERGENCE MCCONVERGENCE MUCONVERGENCE MIXC MIXU LOGHIGH LOGLOW
syn keyword mplusCommand UCELLSIZE VARIANCE MATRIX ITERATIONS CONVERGENCE INTEGRATION STANDARD
syn keyword mplusCommand GENERAL BASIC MEANSTRUCTURE MCOHORT H1 RANDOM COMPLEX MIXTURE
syn keyword mplusCommand TWOLEVEL EFA ESEM BSEM BESEM LOGISTIC
syn keyword mplusCommand ML MLM MLMV MLR MLF MUML WLS WLSM WLSMV GLS ULS
syn keyword mplusCommand DELTA THETA LOGIT LOGLINEAR
syn keyword mplusCommand ON OFF EMA EM ODLL GAUSSHERMITE
syn keyword mplusCommand OBSERVED EXPECTED COMBINATION
syn keyword mplusCommand THREELEVEL CROSSCLASSIFIED ULSMV BAYES ARIMA ARMA
"" Model structure
syn keyword mplusCommand CONFIGURAL SCALAR NOMEANSTRUCTURE NOCOVARIANCES ALLFREE
"" Distribution and parameterization
syn keyword mplusCommand NORMAL SKEWNORMAL TDISTRIBUTION SKEWT PROBABILITY PROBIT
"" Rotation
syn keyword mplusCommand GEOMIN QUARTIMIN OBLIMIN VARIMAX PROMAX TARGET
syn keyword mplusCommand CRAWFER OBLIQUE ORTHOGONAL KAISER
"" Resampling
syn keyword mplusCommand JACKKNIFE JACKKNIFE1 JACKKNIFE2 BRR FAY REPSE
"" Bayesian
syn keyword mplusCommand BITERATIONS FBITERATIONS CHAINS BSEED BCONVERGENCE THIN
syn keyword mplusCommand MDITERATIONS KOLMOGOROV PRIOR GIBBS
"" Other analysis options
syn keyword mplusCommand LRTBOOTSTRAP MULTIPLIER ADDFREQUENCY RITERATIONS AITERATIONS
syn keyword mplusCommand RLOGCRITERION RCONVERGENCE ACONVERGENCE SIMPLICITY TOLERANCE
syn keyword mplusCommand POINT STVALUES PREDICTOR INTERACTIVE
syn keyword mplusCommand DISTRIBUTION ROTATION ROWSTANDARDIZATION METRIC NESTED UW UB
syn keyword mplusCommand LRTSTARTS RSTARTS ASTARTS H1STARTS
syn keyword mplusCommand RESCOVARIANCES RESCOV UNPERTURBED PERTURBED FS MH
"" Hyphenated analysis keywords
syn match mplusCommand "\<K-1STARTS\>"
syn match mplusCommand "\<\(CF-VARIMAX\|CF-QUARTIMAX\|CF-EQUAMAX\|CF-PARSIMAX\|CF-FACPARSIM\)\>"
syn match mplusCommand "\<\(BI-GEOMIN\|BI-CF-QUARTIMAX\)\>"

"" --- Savedata command ---
syn keyword mplusCommand MISSFLAG RECORDLENGTH SIGBETWEEN ESTIMATES RANKING
syn keyword mplusCommand FSCORES CPROBABILITIES BPARAMETERS BCHWEIGHTS PROPENSITY
syn keyword mplusCommand LRESPONSES MFILE MNAMES MFORMAT MMISSING MSELECT
syn keyword mplusCommand SAMPLE RESULTS STDRESULTS STDDISTRIBUTION SAVE FACTORS
syn keyword mplusCommand KAPLANMEIER ESTBASELINE RESPONSE H5RESULTS
syn keyword mplusCommand MAHALANOBIS LOGLIKELIHOOD INFLUENCE COOKS

"" --- Plot command ---
syn keyword mplusCommand SERIES OUTLIERS MONITOR SENSITIVITY PLOT1 PLOT2 PLOT3
syn keyword mplusCommand DRIFT

"" --- Montecarlo command ---
syn keyword mplusCommand NREPS SEED GENERATE CUTPOINTS GENCLASSES NCSIZES CSIZES
syn keyword mplusCommand HAZARDC PATMISS PATPROBS REPSAVE STARTING

"" --- Confidence intervals ---
syn keyword mplusCommand SYMMETRIC BCBOOTSTRAP EQTAIL HPD

"" Highlight links
highlight link mplusStatement Statement
highlight link mplusCommand   Statement
highlight link mplusModel     Function
highlight link mplusNumber    Number
highlight link mplusSection   Include
highlight link mplusComment   Comment
highlight link mplusSpeccom   Special
highlight link mplusHeader    Type
