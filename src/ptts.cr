require "./pages.cr"
require "./display.cr"
require "./file_handle.cr"
require "./pdf_export.cr"

#####################
# PROCESS ARGUMENTS #
#####################

def help
  abort "usage: ptts [flags] <filename>\n" \
      + "flags: \n" \
      + "       -h, --help        prints this help message\n" \
      + "       -p, --plaintext   do not add escape sequences\n" \
      + "       -w, --width <num> sets output width\n" \
      + "       -s, --stdout      do not use tui interface" \
      + "       -m, --meta        concat metadata at the end" \
      + "       -x, --pdf         export to pdf"

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

      when "stdout"
         Data.output_mode = :stdout

      when "pdf"
         Data.output_mode = :pdf

      when "meta"
         Data.concat_metadata = true

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

         when 's'
            Data.output_mode = :stdout

         when 'x'
            Data.output_mode = :pdf

         when 'm'
            Data.concat_metadata = true

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

help if filename.empty?

# measure term if not in pdf
unless Data.output_mode == :pdf || width_set
   Data.term_width = `tput cols`.to_i
   Data.term_height = `tput lines`.to_i
end

# detect if piped
unless STDOUT.tty?
   Data.output_mode = :stdout
end

#########################
# PROCESS FILE CONTENTS #
#########################
process_file filename

if Data.output_mode == :tui || Data.output_mode == :stdout
   display
elsif Data.output_mode == :pdf
   pdf_export
end
