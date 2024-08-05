require "./pages.cr"
require "./display.cr"
require "./file_handle.cr"
require "./latex_export.cr"

#####################
# PROCESS ARGUMENTS #
#####################

def help
  abort "usage: ptts [flags <flag args>] <filename>\n" \
      + "flags: \n" \
      + "       -h, --help            prints this help message\n" \
      + "       -p, --plaintext       do not add escape sequences\n" \
      + "       -w, --width <num>     sets output width\n" \
      + "       -s, --stdout          do not use tui interface\n" \
      + "       -m, --meta            concat metadata at the end\n" \
      + "       -x, --pdf             export to pdf\n" \
      + "       -l, --latex           export to latex (not pretty)\n" \
      + "       -d, --dark            uses darkmode in export\n" \
      + "       -f, --font <fontname> sets font\n"

end

filename = ""
width_set = false

until ARGV.empty?
   arg = ARGV.shift

   if arg.starts_with?("--")
      case arg[2..]
      when "help"
         help
      when "plaintext"
         Data.plaintext = true

      when "width"
         abort "missing argument for --width" if ARGV.empty?

         Data.term_width = ARGV.shift.to_i
         abort "width must be positive numeric vlue" if Data.term_width < 1

         width_set = true

      when "font"
         abort "missing argument for --font" if ARGV.empty?
         Data.font_name = ARGV.shift

      when "stdout"
         Data.output_mode = :stdout

      when "pdf"
         Data.output_mode = :pdf

      when "latex"
         Data.output_mode = :latex

      when "meta"
         Data.concat_metadata = true

      when "dark"
         Data.export_darkmode = true

      else
         puts "unknown flag: #{arg}"
         help
      end

   elsif arg.starts_with?("-")
      arg[1..].chars.each { |flag|
         case flag
         when 'h'
            help
         when 'p'
            Data.plaintext = true

         when 'w'
            abort "missing argument for --width" if ARGV.empty?

            Data.term_width = ARGV.shift.to_i
            abort "width must be positive numeric vlue" if Data.term_width < 1

            width_set = true

         when 'f'
            abort "missing argument for --font" if ARGV.empty?
            Data.font_name = ARGV.shift

         when 's'
            Data.output_mode = :stdout

         when 'x'
            Data.output_mode = :pdf

         when 'l'
            Data.output_mode = :latex

         when 'm'
            Data.concat_metadata = true

         when 'd'
            Data.export_darkmode = true

         else
            puts "unknown flag: -#{flag}"
            help
         end
      }

   else
      unless filename.empty?
         puts "unknown argument: #{arg}"
         help
      end

      filename = arg
   end
end

# dir and stuff

help if filename.empty?

# detect if piped
unless STDOUT.tty?
   Data.output_mode = :stdout
end

# measure term if not in pdf or latex
unless Data.output_mode == :pdf || Data.output_mode == :latex
   Data.term_height = `tput lines`.to_i
   Data.term_width = `tput cols`.to_i unless width_set
end

#########################
# PROCESS FILE CONTENTS #
#########################
process_file filename

if Data.output_mode == :tui || Data.output_mode == :stdout
   display
else
   prepare_latex

   if Data.output_mode == :pdf
      system "xelatex /tmp/ptts/#{Data.export_name}.tex"
   else
      File.copy "/tmp/ptts/#{Data.export_name}.tex", "./#{Data.export_name}.tex"
   end
end
