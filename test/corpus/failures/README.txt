Inputs of the "failures" set of make-corpus.sh. Each makes Mplus print the
messages of bad input or of a failed or doubtful estimation, which the
example outputs lack. The first line of each input is a comment that says
what it provokes, and its title is its name. The prefix gives the kind.

  err-       an error in the input, after which Mplus stops (exit status 1)
  warn-      a warning about the input, after which Mplus goes on
  misread-   data that Mplus reads without a message, but wrongly
  noconv-    an estimation that does not converge
  nonid-     a model that is not identified
  npd-       a covariance matrix that is not positive definite
  fatal-     a FATAL ERROR after the input was read (exit status 2)
  others     standard errors, empty cells, random starts, clusters,
             bootstrap, Wald test, imputed data, and a run that is ended
             at the time limit

The data were made for these inputs and hold no real values.

  cont.dat      300 cases of y1-y6 from two correlated factors, and the
                covariates x1 and x2
  binary.dat    200 cases of the binary items u1-u4 and xb. No case has
                u1 = 1 and u2 = 0, and u4 equals xb
  lca.dat       150 cases of six binary items from two latent classes
  twolevel.dat  20 clusters of 10 cases (y, x, the cluster value w, v that
                varies within clusters, and the cluster number)
  missing.dat   60 cases of y1-y3 and x with -99 for a missing value. Cases
                1 to 3 are missing on y1-y3, cases 4 and 5 on x
  psi.dat       a correlation matrix whose two factors correlate 1.67
  theta.dat     a correlation matrix with a Heywood case for y1
  singular.dat  a correlation matrix that is not positive definite
  short.dat     three columns for an input that names four variables
  symbol.dat    a word among the numbers
  implist.dat   a list of imputed data sets, one of which does not exist
