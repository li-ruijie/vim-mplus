if exists("b:current_syntax")
   finish
endif
syn match mplusHeader "^\u[A-Z ]\+$"
syn match mplusHeader "^\d\{2}\/\d\{2}\/\d\{4}\s\+\d\+:\d\+\s\+.M$"
syn keyword mplusStatement ANALYSIS ARE CATEGORICAL DATA FILE LINK MISSING MODEL
syn keyword mplusStatement MODINDICES NAMES OUTPUT PLOT PROCESSORS RESIDUAL SAMPSTAT STANDARDIZED
syn keyword mplusStatement STD STDYX TITLE TYPE USEVAR USEVARIABLE VARIABLE
syn keyword mplusStatement TECH1 TECH2 TECH3 TECH4 TECH5 TECH6 TECH7 TECH8
syn keyword mplusStatement TECH9 TECH10 TECH11 TECH12 TECH13 TECH14 TECH15 TECH16
syn match   mplusStatement "^SUMMARY OF DATA$"

syn keyword mplusModel with by on WITH BY ON @ PWITH at AT xwith XWITH ind IND via VIA ALL
syn match mplusComment "!.*$"

syn match mplusSection
    \ "^  \(TITLE\||DATA\|VARIABLE\|MODEL\|ANALYSIS\|OUTPUT\):"
syn match mplusSection
    \ "^  \(DEFINE\|SAVEDATA\|PLOT\|MODEL\|CONSTRAINT\|INDIRECT\):"

"" from http://www.statmodel.com/language.html
"" Data command
syn keyword mplusCommand INDIVIDUAL COVARIANCE CORRELATION FULLCOV
syn keyword mplusCommand FULLCORR MEANS STDEVIATIONS MONTECARLO IMPUTATION
syn keyword mplusCommand TYPE IS NOBSERVATIONS ARE NGROUPS VARIANCES CHECK NOCHECK FREE
syn keyword mplusCommand FREE

"" for sanity
syn keyword mplusSpeccom ARE IS

"" Some day...
""syn match mplusSpeccom "\p{S}" "\@" "^\@$" "=" "\=$"

"" VARIABLE COMMAND
syn keyword mplusCommand NAMES USEOBSERVATIONS USEVARIABLES MISSING CENSORED
syn keyword mplusCommand CATEGORICAL NOMINAL COUNT GROUPING IDVARIABLE WEIGHT FORMAT
syn keyword mplusCommand CLUSTER STRATIFICATION CENTERING TSCORES AUXILIARY CLASSES
syn keyword mplusCommand KNOWNCLASS TRAINING WITHIN BETWEEN PATTERN COHORT COPATTERN
syn keyword mplusCommand COHRECODE TIMEMEASURES TNAMES MEMBERSHIP PROBABILITIES

"" DEFINE command
syn keyword mplusCommand IF THEN CUT

"" ANALYSIS command
syn keyword mplusCommand TYPE ESTIMATOR PARAMETERIZATION CHOLESKY ALGORITHM INTEGRATION MCSEED ADAPTIVE INFORMATION BOOTSTRAP DIFFTEST STARTS STITERATIONS STCONVERGENCE STSCALE STSEED OPTSEED COVERAGE ITERATIONS SDITERATIONS H1ITERATIONS MITERATIONS MCITERATIONS MUITERATIONS CONVERGENCE H1CONVERGENCE LOGCRITERION MCONVERGENCE MCCONVERGENCE MUCONVERGENCE MIXC MIXU LOGHIGH LOGLOW UCELLSIZE VARIANCE MATRIX
syn keyword mplusCommand GENERAL BASIC MEANSTRUCTURE MISSING MCOHORT H1 RANDOM COMPLEX MIXTURE BASIC MISSING RANDOM COMPLEX TWOLEVEL BASIC MISSING H1 RANDOM MIXTURE EFA  BASIC MISSING LOGISTIC ML MLM MLMV MLR MLF MUML WLS WLSM WLSMV GLS ULS DELTA THETA LOGIT LOGLINEAR ON OFF EMA EM ODLL INTEGRATION STANDARD GAUSSHERMITE MONTECARLO STANDARD OBSERVED EXPECTED COMBINATION ITERATIONS CONVERGENCE COVARIANCE CORRELATION

"" MODEL command
highlight link mplusStatement Statement
highlight link mplusCommand   Statement
highlight link mplusModel     Function
highlight link mplusSection   Include
highlight link mplusComment   Comment
highlight link mplusSpeccom   Special
highlight link mplusHeader    Type


let b:current_syntax = "mplus-out"
