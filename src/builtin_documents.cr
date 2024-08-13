require "./data.cr"
require "./file_handle.cr"

def get_help
   "usage: ptts [flags <flag args>] <filename>\n" \
 + "flags: \n" \
 + "       -h, --help            prints this help message\n" \
 + "       -p, --plaintext       do not add escape sequences\n" \
 + "       -w, --width <num>     sets output width\n" \
 + "       -s, --stdout          do not use tui interface\n" \
 + "       -m, --meta            concat metadata at the end\n" \
 + "       -x, --pdf             export to pdf\n" \
 + "       -l, --latex           export to latex (not pretty)\n" \
 + "       -d, --dark            uses darkmode in export\n" \
 + "       -f, --font <fontname> sets font\n" \
 + "       -H, --manual          generates the user manual\n"
end

def get_meta
   key_length = 0
   Data.meta.keys.each {|k|
      key_length = k.size if k.size > key_length
   }

   reset_data

   contents = "@setindl{#{key_length+3}} \n\n"
   Data.meta.each {|k, v|
      contents += "@rindl{0} \n"
      contents += k
      contents += "\n@tab{#{key_length - k.size}} "
      contents += "\n@cl{yellow} : \n"
      contents += "@softbindl{1} " + v + "\n"
   }

   process_file "meta", contents

   return Outcome.pages.last.lines
end

def get_manual
   reset_data

   contents = %{
@set{h1;cntln;b;cl{blue};vtab{1};rindl{0}}
@set{h2;b;cl{green};vtab{1};rindl{0}}

@setindl{2}

@x{h1} ptts USER MANUAL

@vtab{1} ptts is a free as in freedom typesetter inspired by roff and
designed specifically for working with monospaced text in a terminal enviroment.
It can be viewed via TUI, outputted to SDTOUT or exported as a PDF file.
(it also supports LaTeX, but it's not nice and is intended only for making small
manual changes before export)

@vtab{1}
Sourcecode can be downloaded from my GitHub
@link{https://github.com/De-Alchmst/ptts}

@x{h1} CLI flags

@bart;vtab{1}
#{get_help.strip}
@eart

@x{h1} TUI controlls

@hardnl;vtab{1}
h, ?, F1 : toggle this manual
C-c, q   : quit
k, Up    : scroll one line up
j, Down  : scroll one line down
gg, Home : go to the top of the document
G, End   : go to the ond of the document
/, C-f   : perform a regex search
n        : go to the next match
N        : go to the previous match
M        : toggle metadata
@softnl

@x{h1} usage
@vtab{1}
Document is organised in text blocks (paragraphs).
Text blocks are seperated by double newline or some specific instructions.
Instructions are called by starting a line with '@' and are optionally
terminated by a whitespace followed by text.
Some instructions operate on this line of text
Multiple instructions can be called from one line by seperating them with ';'.
Some instructions take arguments in curly brackets.

@vtab{1} ptts can operate in three modes: 'plaintext', 'terminal' and 'pdf'.
In 'plaintext' mode, any text formatting relying on escape sequences is ignored.

@x{h1} instructions
@vtab{1}

@set{-;-}
@set{:;:}

@cmnt instruction header
@set{ih;rindl{1};cl{magenta};val{-};aval{:}}
@cmnt instruction body
@set{ib;softbindl{2}}

@x{h2} general

@x{ih} @
@x{ib} writes a '@'

@vtab{1}
@x{ih} @cnt
@x{ib} sets curent line as block beginning and makes text from now on centered
@x{ih} @cntln
@x{ib} makse current line its own line and makse it centered
@x{ih} @lft
@x{ib} sets curent line as block beginning and makes text from now on left
aligned
@x{ih} @lftln
@x{ib} makse current line its own line and makse it left aligned
@x{ih} @rght
@x{ib} sets curent line as block beginning and makes text from now on left
aligned
@x{ih} @rghtln
@x{ib} makse current line its own line and makse it right aligned

@vtab{1}
@x{ih} @indl{num}
@x{ib} sets curent line as block beginning and indents it by extra 'num'
levels, rest of block will be not affected, negative num decreses indent
@x{ih} @brndl{num}
@x{ib} sets indent level from now on
@x{ih} @bindl{num}
@x{ib} sets curent line as block beginning and all text will be
indented by extra 'num' levels, negative num decreases indent
@x{ih} @softbindl{num}
@x{ib} adds indent without breaking block
@x{ih} @indn{num}
@x{ib} sets curent line as block beginning and indents it by extra 'num'
spaces. rest of block will be not affected, negative num decreases indent
@x{ih} @rindn{num}
@x{ib} sets extra space indent
@x{ih} @bindn{num}
@x{ib} sets curent line as block beginning and all text will be
indented by extra 'num' spaces, negative num decreases indent
@x{ih} @softbindn{num}
@x{ib} adds extra indent without breaking block

@vtab{1}
@x{ih} @line
@x{ib} adds full width line
@x{ih} @tab{num}
@x{ib} adds 'num' spaces
@x{ih} @vtab{num}
@x{ib} adds 'num' newlines, also breaks blocks

@vtab{1}
@x{ih} @pgbr
@x{ib} pagebreak
@x{ih} @pgeven
@x{ib} pagebreak at least once until even page number
@x{ih} @pgodd
@x{ib} pagebreak at least once until odd page number
@x{ih} @footnote{note}
@x{ib} inserts footnote mark and adds footnote at the bottom of the page
@x{ih} @link{url}
@x{ib} inserts hyperlink (footnote in terminal mode)
@x{ih} @img{url;alt}
@x{ib} inserts image (alt with a footnote in terminal mode)

@x{h2} terminal/pdf only

@x{ih} @b
@x{ib} makes line bold
@x{ih} @bb
@x{ib} begins bold area
@x{ih} @eb
@x{ib} ends bold area
@x{ih} @i
@x{ib} makes line italic
@x{ih} @bi
@x{ib} begins italic area
@x{ih} @ei
@x{ib} ends italic area
@x{ih} @u
@x{ib} makes line underlined
@x{ih} @bu
@x{ib} begins underlined area
@x{ih} @eu
@x{ib} ends underlined area
@x{ih} @blnk
@x{ib} makes line blinking
@x{ih} @bblink
@x{ib} begins blinking block
@x{ih} @eblink
@x{ib} ends blinking block

@vtab{1}
@x{ih} @cl{colr-word}
@x{ib} makes line in given color, color is given as a word
@x{ih} @bcl{colr-word}
@x{ib} begins color area, color is given as a word
@x{ih} @rgb{r;g;b}
@x{ib} makes line in given color, color is given as ';' separated rgb values
@x{ih} @brgb{r;g;b}
@x{ib} begins color area, color is given as ';' separated rgb values
@x{ih} @hex{hex}
@x{ib} makes line in given color, color is given as a hex code with optional '#'
@x{ih} @bhex{hex}
@x{ib} begins color area, color is given as a hex code with optional '#' 

@x{h2} formatting control

@x{ih} @bg
@x{ib} makes following color-changing instructions affect background
@x{ih} @fg
@x{ib} makes following color-changing instructions affect foreground

@vtab{1}
@x{ih} @setindl{num}
@x{ib} sets indentation level to given number of spaces

@vtab{1}
@x{ih} @set{name;val}
@x{ib} sets value of a variable
@x{ih} @x{name}
@x{ib} evaluetes certain variable contents as instructions
@x{ih} @val{name}
@x{ib} inserts value of certain variable as text
@x{ih} @aval{name}
@x{ib} inserts value of certain variable as text after the line

@vtab{1}
@x{ih} @hardnl
@x{ib} stops joining lines like normal and seperates blocks by single newline
@x{ih} @softnl
@x{ib} returns to joining lines like normal

@vtab{1}
@x{ih} @bart
@x{ib} sets hardnl and does not strip leading spaces
@x{ih} @eart
@x{ib} sets previous lining and starts striping leading spaces

@vtab{1}
@x{ih} @bnum
@x{ib} begins numbering lines
@x{ih} @enum
@x{ib} ends numbering lines

@vtab{1}
@x{ih} @wrap
@x{ib} numbers blocks instead of lines
@x{ih} @nowrap
@x{ib} returns to numbering each line normally

@vtab{1}
@x{ih} @setfootnote{marks}
@x{ib} sets ';' separated list of footnote marks, once last one
reached, first repeats doubled

@vtab{1}
@x{ih} @meta{key:value-list}
@x{ib} adds metadata as key-value pair list separated by ';', key and value are seperated by ':'

@vtab{1}
@x{ih} @cmnt
@x{ib} ignores this line from now onward including any left instructions

@vtab{1}
@x{ih} @sourcetxt{path}
@x{ib} inserts contents of file at 'path' to this place, set configs are ignored
@x{ih} @sourcecnfg{path}
@x{ib} sources formatting, variables and meta from file at 'path'
@x{ih} @sourceall{path}
@x{ib} inserts and sources everything from file at 'path'

@vtab{1}
@x{ih} @startswith{text}
@x{ib} will insert this text at beginning of lines from now onward
@x{ih} @startswithnothing
@x{ib} will reser @startswith to nothing

@x{h1} colors

@vtab{1};cnt
@fg;cl{black} black
-
@bg;cl{black} black

@fg;cl{red} red
-
@bg;cl{red} red

@fg;cl{green} green
-
@bg;cl{green} green

@fg;cl{yellow} yellow
-
@bg;cl{yellow} yellow

@fg;cl{blue} blue
-
@bg;cl{blue} blue

@fg;cl{magenta} magenta
-
@bg;cl{magenta} magenta

@fg;cl{cyan} cyan
-
@bg;cl{cyan} cyan

@fg;cl{white} white
-
@bg;cl{white} white

@vtab{1}
@fg;cl{bright-black} bright-black
-
@bg;cl{bright-black} bright-black

@fg;cl{bright-red} bright-red
-
@bg;cl{bright-red} bright-red

@fg;cl{bright-green} bright-green
-
@bg;cl{bright-green} bright-green

@fg;cl{bright-yellow} bright-yellow
-
@bg;cl{bright-yellow} bright-yellow

@fg;cl{bright-blue} bright-blue
-
@bg;cl{bright-blue} bright-blue

@fg;cl{bright-magenta} bright-magenta
-
@bg;cl{bright-magenta} bright-magenta

@fg;cl{bright-cyan} bright-cyan
-
@bg;cl{bright-cyan} bright-cyan

@fg;cl{bright-white} bright-white
-
@bg;cl{bright-white} bright-white

@vtab{1}
@fg;cl{default} default
-
@bg;cl{default} default

@fg

@x{h1} MIT License

Copyright (c) 2024 Đe-Alchmst
@lft;vtab{1}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

@vtab{1} The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

@vtab{1} THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

   process_file "manual", contents

   return Outcome.pages.last.lines
end
