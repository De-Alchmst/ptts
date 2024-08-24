Document is organised in text blocks (paragraphs).
Text blocks are seperated by double newline or some specific instructions.
Instructions are called by starting a line with '@' and are optionally
terminated by a whitespace followed by text.
Some instructions operate on this line of text
Multiple instructions can be called from one line by seperating them with ';'.
Some instructions take arguments in curly brackets.

Text can be outputed as text, viewed in a TUI, or exported to a pdf.
You can also export to LaTeX, but it's not very readable.

ptts can operate in three modes: 'plaintext', 'terminal' and 'pdf'.
In 'plaintext' mode, any text formatting relying on escape sequences is ignored.

# Instructions

## formatting

### general
- @@ - just inserts '@'

- @cnt - sets curent line as block beginning and makes text from now on centered
- @cntln - makes current line its own line and makes it centered
- @lft - sets curent line as block beginning and makes text from now on left aligned
- @lftln - makes current line its own line and makes it left aligned
- @rght - sets curent line as block beginning and makes text from now on left aligned
- @rghtln - makes current line its own line and makes it right aligned

- @indl{num} - sets curent line as block beginning and indents it by extra 'num'
levels, rest of block will be not affected, negative num decreses indent
- @brndl{num} - sets indent level from now on
- @bindl{num} - sets curent line as block beginning and all text will be
indented by extra 'num' levels, negative num decreases indent
- @softbindl{num} - adds indent without breaking block
- @indn{num} - sets curent line as block beginning and indents it by extra 'num'
spaces. rest of block will be not affected, negative num decreases indent
- @rindn{num} - sets extra space indent
- @bindn{num} - sets curent line as block beginning and all text will be
indented by extra 'num' spaces, negative num decreases indent
- @softbindn{num} - adds extra indent without breaking block

- @line - adds full width line
- @tab{num} - adds 'num' spaces
- @vtab{num} - adds 'num' newlines, also breaks blocks

- @pgbr - pagebreak
- @pgeven - pagebreak at least once until even page number
- @pgodd - pagebreak at least once until odd page number
- @footnote{note} - inserts footnote mark and adds footnote at the bottom of the page
- @link{url} - inserts hyperlink (footnote in terminal mode)
- @img{url;alt} - inserts image (alt with a footnote in terminal mode)
- @label{name} - marks this line as a label of given name
- reflabel{name} - refers to label by given name

### terminal/pdf only
- @b - makes line bold
- @bb - begins bold area
- @eb - ends bold area
- @i - makes line italic
- @bi - begins italic area
- @ei - ends italic area
- @u - makes line underlined
- @bu - begins underlined area
- @eu - ends underlined area
- @blnk - makes line blinking
- @bblink - begins blinking block
- @eblink - ends blinking block

- @cl{color-word} - makes line in given color, color is given as a word
- @bcl{color-word} - begins color area, color is given as a word
- @rgb{r;g;b} - makes line in given color, color is given as ';' separated rgb values
- @brgb{r;g;b} - begins color area, color is given as ';' separated rgb values
- @hex{hex} - makes line in given color, color is given as a hex code with optional '#'
- @bhex{hex} - begins color area, color is given as a hex code with optional '#' 

## formatting control
- @bg - makes following color-changing instructions affect background
- @fg - makes following color-changing instructions affect foreground
- @setindl{num} - sets indentation level to given number of spaces

- @set{name;val} - sets value of a variable
- @x{name} - evaluetes certain variable contents as instructions
- @val{name} - inserts value of certain variable as text
- @aval{name} - inserts value of certain variable as text after the line

- @hardnl - stops joining lines like normal and seperates blocks by single newline
- @softnl - returns to joining lines like normal

- @bart - sets hardnl and does not strip leading spaces
- @eart - sets previous lining and starts striping leading spaces

- @bnum - begins numbering lines
- @enum - ends numbering lines

- @wrap - numbers blocks instead of lines
- @nowrap - returns to numbering each line normally

- @setfootnote{marks} - sets ';' separated list of footnote marks, once last one reached, first repeats doubled

- @meta{key:value-list} - adds metadata as key-value pair list separated by ';', key and value are seperated by ':'

- @cmnt - ignores this line from now onward including any left instructions

- @source{path} - inserts and sources everything from file at 'path'
- @sourceclear{path} - inserts and sources everything from file at 'path', but then resets to previous settings after that

- @startswith{text} - will insert this text at beginning of lines from now onward
- @startswithnothing - will reser @startswith to nothing
