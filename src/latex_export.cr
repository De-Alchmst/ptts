require "./data.cr"
require "./outcome.cr"
require "./esc_to_latex.cr"

require "path"

######################
# put stuff together #
######################
def prepare_tmp
   unless Dir.exists? "/tmp/ptts"
      Dir.mkdir "/tmp/ptts"
   end
end

def prepare_latex
   dat = locate_font
   prepare_tmp

   document, index = outcome2latex

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
\\usepackage{hyperref}
\\usepackage{graphicx}

% Load the external font
\\setmainfont{#{Data.font_name}}[
   Path=#{dat.dir},
   Extension=#{dat.ext},
   UprightFont=*#{dat.regular_word},
   BoldFont=*#{dat.bold ? "-Bold" : dat.regular_word},
   ItalicFont=*#{dat.italic ? "-Italic" :
                 (dat.oblique ? "-Oblique" : dat.regular_word)},
   BoldItalicFont=*#{dat.bolditalic ? "-BoldItalic" :
                     (dat.boldoblique ? "-BoldOblique" : dat.regular_word)},
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

% links
\\hypersetup{
  colorlinks=true,
  urlcolor=bblue,
  pdfborder={0 0 0}
}

% footnotes
\\renewcommand{\\footnotesize}{\\fontsize{#{fontsize}pt}{#{fontsize}pt}}
\\setlength{\\footnotemargin}{0em}

% https://tex.stackexchange.com/questions/30720/footnote-without-a-marker
\\newcommand\\blfootnote[1]{%
  \\begingroup
  \\renewcommand\\thefootnote{}\\footnote{\\raggedright\\textcolor{fgdefault}{#1}}
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

% labels
% https://stackoverflow.com/questions/3831705/how-can-i-attach-a-latex-marker-to-an-arbitrary-place-in-text
\\newcounter{lc}

\\begin{document}

{
\\fontsize{#{fontsize}pt}{#{fontsize}pt}\\selectfont
\\pagecolor{bgdefault}
\\color{fgdefault}

\\fboxsep0pt
#{index if Data.index_front}
#{"\\newpage" if Data.index_front}

#{document}

#{"\\newpage" if Data.index_end}
#{index if Data.index_end}
}

\\end{document}}

   File.write "/tmp/ptts/#{Data.export_name}.tex", latex
end

############################
# CONVERT OUTCOME TO LATEX #
############################

def outcome2latex
   txt = ""
   ind = ""

   Outcome.pages.each_with_index { |page, i|
      page.lines.each { |line|
         # label
         unless line.labels.empty?
            line.labels.each { |label|
               l = txt2latex label
               txt += "\\refstepcounter{lc}\\label{#{l}}"
               lb = l
               if lb.size > Data.term_width - 4
                  lb = lb[0..Data.term_width - 7] + "..."
               end
               ind += "\\pageref{#{l}} \\hyperref[#{l}]{#{lb}}\n\n"
            }
         end

         # text
         txt += "#{txt2latex(line.align)}\n"

         # footnote
         unless line.footnotes.empty?
            line.footnotes.each { |fn|
               if fn.type == :footnote
                  txt += "\\blfootnote{#{
                     txt2latex fn.text.gsub(/\s*\n\s*/, " ").strip, true}}\n\n"
               elsif fn.type == :link
                  txt += "\\blfootnote{#{txt2latex fn.mark}~\\href{#{
                      txt2latex fn.link}}{#{
                      txt2latex fn.text.sub(fn.mark+" ", ""), true}}}\n\n"
               elsif fn.type == :img
                  path = fn.link
                  txt += "\n\\includegraphics{#{
                     path[0] == '/' ? path : "#{__DIR__}/#{path}"
                  }}\n\n"
               elsif fn.type == :label
                  txt += "\\blfootnote{#{txt2latex fn.mark}~\\hyperref[#{
                      txt2latex fn.label}]{#{
                      txt2latex fn.text.sub(fn.mark+" ", ""), true}}}\n\n"
               end
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

   unless ind.empty?
      ind = txt2latex("-" * ((Data.term_width - 5) / 2).floor.to_i \
          + "INDEX" + "-" * ((Data.term_width - 5) / 2).ceil.to_i) \
          + "\n\n" + ind
   end

   return txt + "", ind
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
   line = line.gsub '-', "\\textendash "
   esc2latex line
end

struct FontData
   property dir, ext, regular_word, bold, italic, bolditalic,
      oblique, boldoblique

   def initialize(@dir : String, @ext : String, @regular_word : String,
         @bold : Bool, @italic : Bool, @bolditalic : Bool,
         @oblique : Bool, @boldoblique : Bool)
   end
end

def locate_font
   font_dirs = [Dir.current+"/", "#{Dir.current}/../data/Hack/", __DIR__ + "/ptts-fonts/", Data.file_path]

   ["/usr/share/fonts/", "/usr/local/share/fonts/",
    "#{ENV["HOME"]}/.local/share/fonts/"].each { |dir|
      Dir.children(dir).each { |child|
         font_dirs << "#{dir}#{child}/"
      }
   }

   font_extensions = [".ttf", ".otf", ".TTF", ".OTF"]

   dat = FontData.new "", "", "-Regular", false, false, false, false, false

   font_dirs.each { |dir|
      next unless Dir.exists? dir
      font_extensions.each { |ext|
         puts "#{dir}#{Data.font_name}#{ext}"
         if File.exists? "#{dir}#{Data.font_name}-Regular#{ext}"
            dat.dir = dir
            dat.ext = ext
            break
         end
         if File.exists? "#{dir}#{Data.font_name}#{ext}"
            dat.dir = dir
            dat.ext = ext
            dat.regular_word = ""
            break
         end
      }
      break if dat.dir != ""
   }

   if dat.dir == ""
      abort "font not found: #{Data.font_name} "
   end

   dat.bold = File.exists? "#{dat.dir}#{Data.font_name}-Bold#{dat.ext}"
   dat.italic = File.exists? "#{dat.dir}#{Data.font_name}-Italic#{dat.ext}"
   dat.oblique = File.exists? "#{dat.dir}#{Data.font_name}-Oblique#{dat.ext}"
   dat.bolditalic = File.exists? \
      "#{dat.dir}#{Data.font_name}-BoldItalic#{dat.ext}"
   dat.boldoblique = File.exists? \
      "#{dat.dir}#{Data.font_name}-BoldOblique#{dat.ext}"

   return dat
end
