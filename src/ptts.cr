require "./pages.cr"
require "./display.cr"
require "./file_handle.cr"
require "./latex_export.cr"

require "file_utils"

#####################
# PROCESS ARGUMENTS #
#####################

def help
   abort get_help
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
         Data.max_width = Data.term_width

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
         Data.meta_front = true

      when "meta-end"
         Data.meta_end = true

      when "index"
         Data.index_front = true

      when "index-end"
         Data.index_end = true

      when "dark"
         Data.export_darkmode = true

      when "manual"
         Data.manual_mode = true

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
            Data.max_width = Data.term_width

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
            Data.meta_front = true

         when 'M'
            Data.meta_end = true

         when 'i'
            Data.index_front = true

         when 'I'
            Data.index_end = true

         when 'd'
            Data.export_darkmode = true

         when 'H'
            Data.manual_mode = true

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

help if filename.empty? && !Data.manual_mode

# detect if piped
unless STDOUT.tty?
   Data.output_mode = :stdout
end

# TUI doesn't work on Windows
{% if flag?(:windows) %}
   if Data.output_mode == :tui
      Data.output_mode = :stdout
   end
{% end %}

# measure term if not in pdf or latex
unless Data.output_mode == :pdf
   {% unless flag?(:windows) %}
      Data.term_height = `tput lines`.to_i
      Data.term_width = `tput cols`.to_i unless width_set
   {% else %}
      Data.term_height = `powershell -command "$HOST.UI.RawUI.windowSize.height"`.to_i
      Data.term_width = `powershell -command "$HOST.UI.RawUI.windowSize.width"`.to_i unless width_set
   {% end %}
   Data.actual_width = Data.term_width
end

# check for xelatech
if Data.output_mode == :pdf || Data.output_mode == :latex
   {% unless flag?(:windows) %}
      abort "xelatex not found" if `which xelatex`.empty?
   {% else %}
      if `powershell -command "get-command ptts -ErrorAction silentlyContinue"`.empty?
         abort "xelatex not found"
      end
   {% end %}
end

#########################
# PROCESS FILE CONTENTS #
#########################
unless Data.manual_mode
   process_file filename
else
   get_manual
end

if Data.output_mode == :tui || Data.output_mode == :stdout
   display
else
   prepare_latex

{% unless flag?(:windows) %}
   if Data.output_mode == :pdf
      cur_dir = Dir.current
      Dir.cd "/tmp/ptts"
      # needs to run twice, because of labels
      system "xelatex /tmp/ptts/#{Data.export_name}.tex"
      system "xelatex /tmp/ptts/#{Data.export_name}.tex"
      Dir.cd cur_dir
      FileUtils.mv "/tmp/ptts/#{Data.export_name}.pdf", "./#{Data.export_name}.pdf"
   else
      File.copy "/tmp/ptts/#{Data.export_name}.tex", "./#{Data.export_name}.tex"
   end 
{% else %}
   if Data.output_mode == :pdf
      cur_dir = Dir.current
      Dir.cd "#{ENV["TEMP"]}/ptts"
      # needs to run twice, because of labels
      system "xelatex #{ENV["TEMP"]}/ptts/#{Data.export_name}.tex"
      system "xelatex #{ENV["TEMP"]}/ptts/#{Data.export_name}.tex"
      Dir.cd cur_dir
      FileUtils.mv "#{ENV["TEMP"]}/ptts/#{Data.export_name}.pdf", "./#{Data.export_name}.pdf"
   else
      File.copy "#{ENV["TEMP"]}/ptts/#{Data.export_name}.tex", "./#{Data.export_name}.tex"
   end 
{% end %}
end
