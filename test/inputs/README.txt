Inputs for run-tests.sh that hold what no Mplus example has. Each is run
through Mplus as written and after gq, like an example. data.dat is the
data of the title and header inputs, and do.dat that of the DO inputs.

title-same-line.inp   The text on the TITLE: line would be a section header
                      on a line of its own. Mplus reads it as the title.
title-mid-line.inp    The same words in the middle of the title line.
header-same-line.inp  A command name and a colon after the MODEL: header.
                      Mplus takes a command only at the start of a line and
                      stops with an error here, before and after gq.
do-define.inp         DO statements over three lines and a DO inside a DO
                      over lines, in DEFINE, MODEL CONSTRAINT, and MODEL
                      TEST, with comments that hold a semicolon inside the
                      statements. gq indents the lines after DO one level
                      deeper and the line after the statement back.
do-priors.inp         The same in MODEL PRIORS, with the Bayes estimator.
                      TECH1 prints the priors that the loops give.
comments.inp          Comments in a title, where Mplus prints a line with a
                      ! or !* below the TITLE line, and block comments that
                      open after code and in a ! comment, which drop their
                      line and hold a header. gq keeps such lines as
                      written.
