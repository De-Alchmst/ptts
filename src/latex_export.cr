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
      `cp ../data/FiraMono-Regular.otf /tmp/ptts/#{Data.font_name}`
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
\\usepackage{xcolor} % Required for colored text
\\usepackage{fontspec} % Required for loading external fonts
\\usepackage[a4paper, margin=#{Data.export_margin}em]{geometry} % Set margins
% \\usepackage{listings}

% Load the external font
\\newfontface\\customfont[Path=/tmp/ptts/]{#{Data.font_name}}

% \\lstset{
%   basicstyle=\\customfont,
%   columns=fullflexible,
%   keepspaces=true,
%   numbers=none,
%   showstringspaces=false
% }

\\begin{document}

#{document}

\\end{document}}

   File.write "/tmp/ptts/#{Data.export_name}.tex", latex
end

############################
# CONVERT OUTCOME TO LATEX #
############################

def outcome2latex
   txt = "\\customfont\n"

   Outcome.pages.each_with_index { |page, i|
      page.lines.each { |line|
         txt += "#{line2latex(line.align)}\n\n"
      }
   }

   return txt + ""
end

def line2latex(line : String)
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
   esc2latex line
end
