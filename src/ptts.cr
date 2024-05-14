require "./pages.cr"
require "./display.cr"
require "./file_handle.cr"

#####################
# PROCESS ARGUMENTS #
#####################

def help
  abort "usage: ptts [flags] <filename>\n" \
      + "flags: \n" \
      + "       -h, --help        prints this help message\n" \
      + "       -p, --plaintext   do not add escape sequences\n" \
      + "       -w, --width <num> sets output width\n" \

end

filename = ""

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

#########################
# PROCESS FILE CONTENTS #
#########################
process_file filename
display
