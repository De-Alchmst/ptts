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
      `cp ../data/AnonymousPro-Regular.ttf /tmp/ptts/`
      `cp ../data/AnonymousPro-Bold.ttf /tmp/ptts/`
      `cp ../data/AnonymousPro-Italic.ttf /tmp/ptts/`
      `cp ../data/AnonymousPro-BoldItalic.ttf /tmp/ptts/`
      # File.open("/tmp/ptts/#{Data.font_name}", "wb") { |f|
      #    f.write FontData.data
      # }
   end
end

def prepare_latex
   prepare_tmp

   document = outcome2latex

   latex = %{
\\documentclass{article}
\\usepackage{xcolor}
\\usepackage{fontspec}
\\usepackage[a4paper, margin=#{Data.export_margin}em]{geometry}
\\usepackage[skip=0pt]{parskip}
\\usepackage{footmisc}
\\usepackage{ifthen}

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
\\renewcommand{\\footnotesize}{\\normalsize}
\\setlength{\\footnotemargin}{0em}

% https://tex.stackexchange.com/questions/30720/footnote-without-a-marker
\\newcommand\\blfootnote[1]{%
  \\begingroup
  \\renewcommand\\thefootnote{}\\footnote{\\textcolor{fgdefault}{#1}}%
  \\addtocounter{footnote}{-1}%
  \\endgroup
}

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
    \\thispagestyle{empty}
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
    \\thispagestyle{empty}
    \\hbox{}\\newpage
  }
}

\\begin{document}

{
\\pagecolor{bgdefault}
\\color{fgdefault}
% \\fontsize{11pt}{11pt}


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
         # footnote
         unless line.footnotes.empty?
            line.footnotes.each { |fn|
               txt += "\\blfootnote{#{
                  txt2latex fn.text.gsub(/\s*\n\s*/, " ").strip}}\n"
            }
         end
         # text
         txt += "#{txt2latex(line.align)}\n\n"
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

def txt2latex(line : String)
   line = line.gsub ' ', '\t'
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
