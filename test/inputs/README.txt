Inputs for run-tests.sh that hold what no Mplus example has. Each is run
through Mplus as written and after gq, like an example, and data.dat is
their data.

title-same-line.inp   The text on the TITLE: line would be a section header
                      on a line of its own. Mplus reads it as the title.
title-mid-line.inp    The same words in the middle of the title line.
header-same-line.inp  A command name and a colon after the MODEL: header.
                      Mplus takes a command only at the start of a line and
                      stops with an error here, before and after gq.
