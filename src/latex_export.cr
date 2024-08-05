require "./data.cr"
require "./outcome.cr"
require "./esc_to_latex.cr"
# require "./font_data.cr"

######################
# put stuff together #
######################
def prepare_tmp
   unless Dir.exists? "/tmp/ptts"
      Dir.mkdir "/tmp/ptts"
   end

   if Data.default_font
      `cp ../data/#{Data.font_name}-Regular.ttf /tmp/ptts/`
      `cp ../data/#{Data.font_name}-Bold.ttf /tmp/ptts/`
      `cp ../data/#{Data.font_name}-Italic.ttf /tmp/ptts/`
      `cp ../data/#{Data.font_name}-BoldItalic.ttf /tmp/ptts/`
      # File.open("/tmp/ptts/#{Data.font_name}", "wb") { |f|
      #    f.write FontData.data
      # }
   end
end

def prepare_latex
   prepare_tmp

   document = outcome2latex

   page_width = 595.0 - Data.export_margin * 2
   fontsize = page_width / Data.term_width * 1.5
   fontsize = fontsize.floor
   side_margin = (595 - fontsize / 1.5 * Data.term_width) / 2

   latex = %{
\\documentclass{article}
\\usepackage{xcolor}
\\usepackage{fontspec}
\\usepackage[a4paper, left=#{side_margin}pt, right=#{side_margin}pt, top=#{Data.export_margin}pt, bottom=#{
   Data.export_margin >= 40 ? Data.export_margin : 40
}pt]{geometry}
\\usepackage[skip=-1pt]{parskip}
\\usepackage{footmisc}
\\usepackage{ifthen}
\\usepackage{fancyhdr}

% Load the external font
\\setmainfont{#{Data.font_name}}[
   Path=/tmp/ptts/,
   Extension = #{Data.font_extension},
   UprightFont=*-Regular,
   BoldFont=*-Bold,
   ItalicFont=*-Italic,
   BoldItalicFont=*-BoldItalic
]

\\definecolor{nblack}{rgb}{0,0,0}
\\definecolor{nred}{rgb}{0.8,0,0}
\\definecolor{ngreen}{rgb}{0,0.8,0}
\\definecolor{nyellow}{rgb}{0.8,0.8,0}
\\definecolor{nblue}{rgb}{0,0,0.8}
\\definecolor{nmagenta}{rgb}{0.8,0,0.8}
\\definecolor{ncyan}{rgb}{0,0.8,0.8}
\\definecolor{nwhite}{rgb}{0.8,0.8,0.8}

\\definecolor{bblack}{rgb}{0.2,0.2,0.2}
\\definecolor{bred}{rgb}{1,0,0}
\\definecolor{bgreen}{rgb}{0,1,0}
\\definecolor{byellow}{rgb}{1,1,0}
\\definecolor{bblue}{rgb}{0,0,1}
\\definecolor{bmagenta}{rgb}{1,0,1}
\\definecolor{bcyan}{rgb}{0,1,1}
\\definecolor{bwhite}{rgb}{1,1,1}

\\definecolor{fgdefault}{rgb}{#{Data.export_darkmode ? "1,1,1" : "0,0,0"}}
\\definecolor{bgdefault}{rgb}{#{Data.export_darkmode ? "0.1,0.1,0.2" : "1,1,1"}}

% footnotes
\\renewcommand{\\footnotesize}{\\fontsize{#{fontsize}}{#{fontsize}}}
\\setlength{\\footnotemargin}{0em}

% https://tex.stackexchange.com/questions/30720/footnote-without-a-marker
\\newcommand\\blfootnote[1]{%
  \\begingroup
  \\renewcommand\\thefootnote{}\\footnote{\\textcolor{fgdefault}{#1}}%
  \\addtocounter{footnote}{-1}%
  \\endgroup
}

% page numbermypagenumcolor
\\pagestyle{fancy}
\\fancyhf{}
\\fancyfoot[C]{\\textcolor{fgdefault}{\\thepage}}

\\renewcommand{\\footnoterule}{%
    \\kern -4pt
    \\color{fgdefault}%
    \\hrule width \\linewidth height 0.4pt
    \\kern 3.4pt
}

% page breaks
\\newcommand{\\forceevenpage}{
  \\ifthenelse{\\isodd{\\thepage}}{
    \\hbox{}\\newpage
    \\hbox{}\\newpage
  }{
    \\newpage
  }
}

\\newcommand{\\forceoddpage}{
  \\ifthenelse{\\isodd{\\thepage}}{
    \\newpage
  }{
    \\hbox{}\\newpage
    \\hbox{}\\newpage
  }
}

\\begin{document}

{
\\fontsize{#{fontsize}}{#{fontsize}}\\selectfont
\\pagecolor{bgdefault}
\\color{fgdefault}

\\fboxsep0pt
#{document}
}

\\end{document}}

   File.write "/tmp/ptts/#{Data.export_name}.tex", latex
end

############################
# CONVERT OUTCOME TO LATEX #
############################

def outcome2latex
   txt = ""

   Outcome.pages.each_with_index { |page, i|
      page.lines.each { |line|
         # text
         txt += "#{txt2latex(line.align)}\n"
         # footnote
         unless line.footnotes.empty?
            line.footnotes.each { |fn|
               txt += "\\blfootnote{#{
                  txt2latex fn.text.gsub(/\s*\n\s*/, " ").strip, true}}\n\n"
            }
         else
            txt += "\n"
         end
      }

      if i < Outcome.pages.size - 1
         case Outcome.pages[i+1].page_type
         when :regular
            txt += "\\newpage\n"
         when :odd
            txt += "\\forceoddpage\n"
         when :even
            txt += "\\forceevenpage\n"
         end
      end
   }

   return txt + ""
end

def txt2latex(line : String, nobreak = false)
   unless nobreak
      line = line.gsub ' ', '\t' 
   else
      line = line.sub ' ', '\t' 
   end
   line = line.gsub '\\', "\\textbackslash "
   line = line.gsub '^', "\\textasciicircum "
   line = line.gsub '$', "\\$"
   line = line.gsub '%', "\\%"
   line = line.gsub '&', "\\&"
   line = line.gsub '{', "\\{"
   line = line.gsub '}', "\\}"
   line = line.gsub '_', "\\_"
   line = line.gsub '~', "\\textasciitilde "
   line = line.gsub '#', "\\#"
   line = line.gsub '\t', '~'
   line = line.gsub /-(?=-)/, "\\textendash "
   esc2latex line
end
