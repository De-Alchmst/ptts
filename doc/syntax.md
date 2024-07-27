Text blocks are seperated by double newline, additional newlines are displayed
as is. '@' at the beginning of line indicates formatting instruction. Anything
after that instruction is interpreted as normal text. Instructions can affect
only text on same line, entire text block, or entire document from itself
afterwards. Instructions can have arguments inside '{}' and multiple
instructions can be seperated by ';'

ptts can operate in two modes: 'plaintext' and 'terminal'

ptts implements pages. how are they implemented depends on implementation

# Instructions

## formatting

### general
- @@ - just inserts '@'

- @cnt - sets curent line as block beginning and makes text from now on centered
- @cntln - makse current line its own line and makse it centered
- @lft - sets curent line as block beginning and makes text from now on left aligned
- @lftln - makse current line its own line and makse it left aligned
- @rght - sets curent line as block beginning and makes text from now on left aligned
- @rghtln - makse current line its own line and makse it right aligned

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
- @footnote{note} - inserts footnote mark and adds footnote atbottom of page

### terminal/pdf only
- @b - makes line bold
- @bb - begins bold area
- @eb ends bold area
- @i - makes line italic
- @bi - begins italic area
- @ei - ends italic area
- @u - makes line underlined
- @bu - begins underlined area
- @eu - ends underlined area
- @blnk - makes line blinking
- @bblink - begins blinking block
- @eblink - end blinking block

- @cl{color-word} - makes line in given color, color is given as word
- @bcl{color-word} - begins color area, color is given as word
- @rgb{r;g;b} - makes line in given color, color is given as ';' separated rgb values
- @brgb{r;g;b} - begins color area, color is given as ';' separated rgb values
- @hex{hex} - makes line in given color, color is given as hex code with optional '#'
- @bhex{hex} - begins color area, color is given as hex code with optional '#' 

## formatting control
- @fg - makes following color-changing instructions affect foreground
- @bg - makes following color-changing instructions affect background
- @setindl{num} - sets indentation level to given number of spaces

- @set{name;val} - sets value of variable to come value separated by first ';'
- @eval{name} - evaluetes certain variable contents as instructions
- @val{name} - inserts value of certain variable as text

- @hardnl - stops joining lines like normal and seperates blocks by single newline
- @softnl - returns to joining lines like normal

- @bart - sets hardnl and does not strip leading spaces
- @eart - sets previous lining and starts striping leading spaces

- @bnum - begins numbering lines
- @enum - ends numbering lines

- @wrap - numbers blocks instead of lines
- @nowrap - returns to numbering each line normally

- @setfootnote{marks} - sets ';' separated list of footnote marks, once last on
reached, first repeats doubled

- @meta{key:value-list} - adds metadata as key-value pair list separated by ';', key and value are seperated by ':'

- @cmnt - ignores this line from now onward

- @sourcetxt{path} - inserts contents of file at 'path' to this place, set configs are ignored
- @sourcecnfg{path} - sources formatting, variables and meta from file at 'path'
- @sourceall{path} - inserts and sources everything from file at 'path'

- @startswith{text} - will insert this text at beginning of lines from now onward
- @startswithnothing - will reser @startswith to nothing
