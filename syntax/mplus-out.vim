if exists("b:current_syntax")
   finish
endif

"" The syntax of an Mplus output. Each kind of line is found where and as
"" Mplus prints it, by the rules that test/corpus/kinds.py states and that
"" test/corpus/check-syntax.sh holds this file to, line by line. Folds have
"" three levels: a part of the output (MODEL RESULTS, TECHNICAL 1 OUTPUT),
"" a sub-header inside it (PARAMETER SPECIFICATION, Loglikelihood), and the
"" name of a matrix or table (NU, Means), which is at level 2 directly under
"" a part. The echoed input is highlighted as an input file. Warnings and
"" errors are highlighted and start no fold. The status of the estimation
"" and the footer stand outside every fold.

"" The echoed input, from INPUT INSTRUCTIONS to the first line with text at
"" column 0. Mplus echoes every line of the input with an indent of two, so
"" the input syntax applies inside this region and nowhere else. Its items
"" are all contained, and its sections fold at level 2. A section of a
"" single line starts no fold, as a fold by syntax needs two lines.
unlet! b:current_syntax
syn include @mplusInput syntax/mplus-inp.vim
unlet! b:current_syntax
syn case match

"" Parts of a pattern, each tried at the start of the text of a line.
"" No decimal number on the line (a period between a digit or a space and a
"" digit), no period at its end, no lowercase letter, and no run of two
"" spaces between words, which sets out columns.
let s:nodec = '\%(.*\%(\a\|_\|\.\)\@1<!\.\d\)\@!'
let s:noend = '\%(.*\.\s*$\)\@!'
let s:nolow = '\%(.*\l\)\@!'
let s:low = '\%(.*\l\)\@='
let s:nogap = '\%(.*\S \{2,}\S\)\@!'
"" Mplus starts none of its headers with an article, a note, or an asterisk,
"" and the line that ends the reading of the input is no header either.
let s:nomsg = '\%(\s*\%(THE \|The \|NOTE:\|\*\|INPUT READING TERMINATED NORMALLY\s*$\)\)\@!'
"" The line above is empty, and the line below is empty or there is none.
let s:above = '\%(^\s*\n\)\@<='
let s:alone = '\%(\n\s*$\|\%$\)\@='

"" Labels in capitals that stand where and as a part header stands, but name
"" a section inside a part: the fit section CFI/TLI, the labels of a class, a
"" level, and a set of variables that older versions print in capitals, and
"" the pair of variables of a table of CROSSTABS ("U1 AND U2"). The $ stands
"" in a group of its own, so that it means the end of the line whatever
"" follows it.
let s:pair = '\u[[:alnum:]_#$&.]* AND \u[[:alnum:]_#$&.]*'
let s:labels = '\%(CFI\/TLI\|CLASS \d\+\|WITHIN\|BETWEEN\|VARIABLE SET \d\+\|' . s:pair . '\)\%(\s*$\)'

"" A part header: a line at column 0 in capitals that starts with a capital
"" letter and has an empty line above, alone or with a second line of the
"" same kind below it (FINAL CLASS COUNTS ... / BASED ON THE ESTIMATED
"" MODEL), and an empty line after it.
let s:part1 = '\%(' . s:labels . '\)\@!' . s:nolow . s:nodec . s:noend . s:nomsg
let s:part2 = '\S\@=' . s:part1 . '\%(.*\u\)\@=.*'
let s:part = '^\u\@=' . s:above . s:part1 . '.*\%(\n' . s:part2 . '\)\=' . s:alone
"" The parts named TECHNICAL hold no status of the estimation, as TECHNICAL 9
"" prints a status line for every replication and bootstrap draw.
let s:techpart = '^\%(TECHNICAL\)\@=' . s:above . s:part1 . '.*\%(\n' . s:part2 . '\)\=' . s:alone
let s:otherpart = '^\%(TECHNICAL\)\@!\u\@=' . s:above . s:part1 . '.*\%(\n' . s:part2 . '\)\='
    \ . s:alone

"" A sub-header at column 0: a label in capitals as above, or a line with a
"" lowercase letter and single spaces between its words (Loglikelihood,
"" Latent Class 1, STDYX Standardization). The line above is empty or
"" indented, or ends a sentence, so that a label directly below the heads of
"" the columns counts too. In an analysis of groups the pair of CROSSTABS
"" stands directly below the indented line that names the group ("  Group
"" MALE"). A second line may follow a sub-header at column 0, or
"" indented when it starts with a parenthesis ("     (Ordinal) Outcomes").
"" The start of a region inside a region whose end pattern spans lines ends
"" with its first line, so the second line is a match of its own (s:sub2).
let s:sub0text = s:low . s:nogap . s:nodec . s:noend . s:nomsg
let s:sub2text = '\%(\S\|\s\+(\)\@=' . s:sub0text . '.*'
let s:sub0 = '^\u\@=\%(\%(' . s:above . s:labels
    \ . '\|\%(^\s.*\n\)\@<=' . s:pair . '\%(\s*$\)\)' . s:alone
    \ . '\|' . s:sub0text . '\%(\%(^\|^\s.*\|^.*\a\a\.\s*\)\n\)\@<=.*'
    \ . '\%(\%(\n' . s:sub2text . '\)\=\%(\n\s*$\|\%$\)\)\@=\)'
let s:sub2 = '^\%(^\u.*\n\)\@<=' . s:sub2text . s:alone
"" An indented sub-header: alone between empty lines, with single spaces
"" between its words, and the next line with text at most one column less
"" deep, as the lines of a section stand under its header. The group \(\)
"" takes the indent but one column, and \1 asks for it on the next line.
"" It is the only capturing group of this file, so \1 stays right in every
"" pattern that holds it.
let s:subind = '^\%(\s\+\u\)\@=' . s:above . '\(\s*\)\s\S\@=' . s:nogap . s:nodec . s:noend . s:nomsg
    \ . '.*\%(\n\s*\n\%(\s*\n\)*\1\s*\S\)\@='
let s:sub = s:sub0 . '\|' . s:subind

"" The name of a matrix or table: an indented line with a line of column
"" names below it and a rule of underscores, eight to a column, below that.
"" The line of column names is written \s*\S.* and not .*\S.*, which the
"" backtracking engine would try in a time that grows with the square of
"" the length of the line, and the rest of a line is taken whole (\@>), so
"" that a line with no rule two lines below fails at once.
let s:tablelook = '\s\+\S\%(.*\n\)\@>\s*\S\%(.*\n\)\@>\s*_\{8}\%(\s\+_\{8}\)*\s*$'
let s:table = '^\s\+\S\%(.*\)\@>\ze\n\s*\S\%(.*\n\)\@>\s*_\{8}\%(\s\+_\{8}\)*\s*$'

"" The footer starts at MUTHEN & MUTHEN after an empty line, or at the line
"" Mplus VERSION that Mplus on Linux writes above it.
let s:footer = '^\%(^\s*\n\)\@<=MUTHEN & MUTHEN\s*$'
    \ . '\|^Mplus VERSION.*\n\%(\s*\n\)\+MUTHEN & MUTHEN\s*$'

"" The status of the estimation starts at THE MODEL ESTIMATION TERMINATED
"" NORMALLY at column 0, at the error of an estimation that did not end
"" normally, or at the verdict on the random starts when such a line follows
"" it as the next paragraph.
let s:failed = '\s*\%(THE MODEL ESTIMATION DID NOT TERMINATE NORMALLY\|NO CONVERGENCE\.\)'
let s:statusline = 'THE MODEL ESTIMATION TERMINATED NORMALLY\s*$'
let s:status = '^\%(' . s:statusline . '\|' . s:failed . '\|' . s:above
    \ . '\%(THE BEST LOGLIKELIHOOD VALUE HAS BEEN REPLICATED'
    \ . '\|\s\+WARNING:\s\+THE BEST LOGLIKELIHOOD VALUE WAS NOT REPLICATED\)'
    \ . '.*\n\%(.*\S.*\n\)*\%(\s*\n\)\+\%(' . s:statusline . '\|' . s:failed . '\)\)'

"" The first words of a message that Mplus marks as a warning or an error,
"" or that tells of a doubtful or a failed estimation. Mplus words these as
"" it words its other messages, so only the wording tells them apart.
let s:warnings = '\*\*\* WARNING\|WARNING\>\|\d\+ WARNING(S) FOUND IN THE INPUT INSTRUCTIONS'
    \ . '\|PROBLEMS\= \%(OCCURRED\|INVOLVING\)\|COMPUTATIONAL PROBLEMS'
    \ . '\|THE MODEL ESTIMATION HAS REACHED'
    \ . '\|THE STANDARD ERRORS OF THE MODEL PARAMETER ESTIMATES'
    \ . '\|ONE OR MORE \%(\u\+ \)*PARAMETERS WERE FIXED\|THE CONDITION NUMBER IS'
    \ . '\|THE NONIDENTIFICATION IS\|THE \%(H1 \)\=MODEL ESTIMATION DID NOT CONVERGE'
    \ . '\|THIS ANALYSIS MAY HAVE MULTIPLE SOLUTIONS\|THE EFFECTIVE SAMPLE SIZE'
    \ . '\|THE WARNING IS DUE TO\|A MATRIX COULD NOT BE INVERTED'
let s:errors = '\*\*\* \%(ERROR\|FATAL ERROR\)\|ERROR\>'
    \ . '\|\d\+ ERROR(S) FOUND IN THE INPUT INSTRUCTIONS\|Errors for replication with data file'
    \ . '\|NO CONVERGENCE\|THE MODEL ESTIMATION DID NOT TERMINATE'
    \ . '\|Model estimation did not terminate normally\|THE LOGLIKELIHOOD DECREASED'
    \ . '\|THE FOLLOWING DATA SET(S) DID NOT RESULT\|DEMO VERSION MAXIMUM EXCEEDED'

"" Comments and class labels, as in the input (! ..., %OVERALL%).
syn match mplusComment "!.*$"
syn match mplusSection "%[^%]\+%"

"" The banner, above INPUT INSTRUCTIONS.
syn region mplusBanner start="\%^" end="^\zeINPUT INSTRUCTIONS\s*$"

"" The folds. A fold ends above the next header of its level or of a level
"" above, and above the footer. A part other than TECHNICAL ends above the
"" status of the estimation too. A sub-header at column 0 also ends above
"" the next line with text at column 0 that has an empty line above and is
"" no row of numbers, as the modification indices print their rows at
"" column 0. Each fold has keepend, so the folds inside it end with it.
""
"" Every pattern below starts with \%#=1, which has Vim try it with the
"" backtracking engine. The automatic engine takes the NFA one for these
"" patterns, and with their nested lookahead and lookbehind it reads an
"" output about a hundred times slower.
let s:contents = 'mplusWarning,mplusError,mplusComment,mplusSection'
let s:anypart = s:part . '\|' . s:footer
execute 'syn region mplusPartFold matchgroup=mplusPart start="\%#=1' . s:otherpart . '"'
    \ 'end="\%#=1^\%(' . s:anypart . '\|' . s:status . '\)\@=" fold keepend'
    \ 'contains=mplusSubFold,mplusTableFold,' . s:contents
execute 'syn region mplusPartFold matchgroup=mplusPart start="\%#=1' . s:techpart . '"'
    \ 'end="\%#=1^\%(' . s:anypart . '\)\@=" fold keepend'
    \ 'contains=mplusSubFold,mplusTableFold,' . s:contents
execute 'syn region mplusSubFold matchgroup=mplusSub start="\%#=1' . s:sub0 . '"'
    \ 'end="\%#=1^\%(' . s:sub . '\|' . s:anypart
    \ . '\|' . s:above . '\S\%(.*\%(\a\|_\|\.\)\@1<!\.\d\)\@!\%(.*\/\s*$\)\@!\)\@=" fold keepend'
    \ 'contains=mplusSub,mplusTableFold,' . s:contents
execute 'syn match mplusSub "\%#=1' . s:sub2 . '" contained'
execute 'syn region mplusSubFold matchgroup=mplusSub start="\%#=1' . s:subind . '"'
    \ 'end="\%#=1^\%(' . s:sub . '\|' . s:anypart . '\)\@=" fold keepend'
    \ 'contains=mplusTableFold,' . s:contents
execute 'syn region mplusTableFold matchgroup=mplusTable start="\%#=1' . s:table . '"'
    \ 'end="\%#=1^\%(' . s:tablelook . '\|' . s:sub . '\|' . s:anypart . '\)\@=" fold keepend'
    \ 'contains=' . s:contents

"" The echoed input. It is defined after the folds, so that INPUT
"" INSTRUCTIONS starts it and no part.
syn region mplusEcho matchgroup=mplusPart start="^INPUT INSTRUCTIONS\s*$" end="^\ze\S"
    \ fold keepend contains=@mplusInput

"" Warnings and errors run from their first line to the end of the
"" paragraph, and start no fold. Mplus writes its messages about the input
"" one below the other, each marked with ***, and the lines that count them
"" below the last, so such a line of the other kind ends one as well. The
"" indent is taken whole (\@>), so that the first words are tried once.
execute 'syn region mplusWarning start="\%#=1^\%(\%(\s*\)\@>\%(' . s:warnings . '\)\)\@="'
    \ 'end="^\ze\%(\s*$\|\s*\%(\*\*\* \%(ERROR\|FATAL ERROR\)\|\d\+ ERROR(S) FOUND\)\)"'
execute 'syn region mplusError start="\%#=1^\%(\%(\s*\)\@>\%(' . s:errors . '\)\)\@="'
    \ 'end="^\ze\%(\s*$\|\s*\%(\*\*\* WARNING\|\d\+ WARNING(S) FOUND\)\)"'

"" The status of the estimation, outside every fold up to the next part or
"" the footer. It is defined after the warnings and errors, so that it starts
"" where one of them starts and holds it.
execute 'syn region mplusStatusBlock start="\%#=1^\%(' . s:status . '\)\@="'
    \ 'end="\%#=1^\%(' . s:anypart . '\)\@=" keepend'
    \ 'contains=mplusStatus,' . s:contents
execute 'syn match mplusStatus "^' . s:statusline . '" contained'

"" The footer, from MUTHEN & MUTHEN or Mplus VERSION to the end.
execute 'syn region mplusFooter start="\%#=1\%(' . s:footer . '\)\@=" end="\%$"'

"" The title, which Mplus prints as it was written between the messages
"" about the input and the summary of the analysis. The messages end with the
"" line INPUT READING TERMINATED NORMALLY or, when there were warnings or
"" errors that Mplus passed over (an option it ignores), with the last of the
"" lines that count them. Every one of the 428 example outputs has one of
"" these lines and the summary. A run that stops after the title has no
"" summary, and there the title ends at the first line that cannot belong to
"" it. Mplus prints every line of the title without its indent, so an
"" indented line ends it (the warnings about a singular sample covariance
"" matrix). A run that Mplus stops has the line *** FATAL ERROR after the
"" title, with the indented lines of the message below it. That line ends
"" the title where the next line with text is indented, so a title line of
"" the same text ends the title only when it is the last one and warnings
"" follow it. The output of a run that was ended ends with the title, and
"" the footer ends it too. The title is title text whatever it looks like,
"" so nothing is matched in it. The region starts on the empty line that
"" Mplus writes after such a line, and its pattern tests that a line is
"" empty before it looks back at the line above.
execute 'syn region mplusTitle extend'
    \ 'start="^\_$\%(\%(INPUT READING TERMINATED NORMALLY'
    \ . '\|\s*\d\+ \%(WARNING\|ERROR\)(S) FOUND IN THE INPUT INSTRUCTIONS\)\s*\n\)\@<="'
    \ 'end="^\zeSUMMARY OF ANALYSIS\s*$\|^\ze\s\+\S\|^\ze\*\*\* FATAL ERROR\s*\n\%(\s*\n\)*\s\+\S'
    \ . '\|^\%(' . s:footer . '\)\@="'

"" Highlight links. Each can be linked anew, for example with
"" ":highlight link mplusSub Identifier" in a file after/syntax/mplus-out.vim.
hi def link mplusHeader  Type
hi def link mplusPart    mplusHeader
hi def link mplusSub     mplusHeader
hi def link mplusTable   mplusHeader
hi def link mplusBanner  mplusHeader
hi def link mplusFooter  Comment
hi def link mplusStatus  Special
hi def link mplusWarning WarningMsg
hi def link mplusError   ErrorMsg
hi def link mplusSection Include
hi def link mplusComment Comment
hi def link mplusTitle   String

"" Sections, block comments, and the printed title are regions of many
"" lines, and a line reads differently inside one of them. Folding by syntax
"" parses the whole buffer in any case, so every line is read with the state
"" that the lines above it leave, wherever the window starts.
syn sync fromstart

let b:current_syntax = "mplus-out"
