require "./data.cr"
require "./outcome.cr"
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

% Load the external font
\\newfontface\\customfont[Path=/tmp/ptts/]{#{Data.font_name}}

\\begin{document}

#{document}

\\end{document}}

   File.write "/tmp/ptts/#{Data.export_name}.tex", latex
end

############################
# CONVERT OUTCOME TO LATEX #
############################

def outcome2latex
   txt = "\\customfont{\n"

   Outcome.pages.each_with_index { |page, i|
      page.lines.each { |line|
         txt +=
            "\\begin{verbatim}\n#{line2latex(line.align)}\n\\end{verbatim}\n\n"
      }
   }

   return txt + "}"
end

def line2latex(line : String)
   line.gsub("\x1b", "").gsub('\\', "\\\\")
end
