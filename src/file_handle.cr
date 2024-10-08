require "./data.cr"
require "./outcome.cr"
require "./instructions.cr"
require "./inst_parse.cr"

def process_file(filename : String, contents="", init=true)
   if init
      Outcome.alingment = Alingment::Left
      Outcome.init
   end
   Data.filename = filename
   if init
      Data.file_path = File.dirname filename
                                                    # ↓ get rid of extension
      Data.export_name = File.basename(filename).sub /\.[^\.]*$/, ""

      Data.indent_level = 0
      Data.indent_level_length = 1
      Data.indent_extra = 0 # extra level independent indent
   end

   #################
   # READ THE FILE #
   #################

   lines = [] of String

   if contents.empty?
      abort "file not found: #{filename}" unless File.exists? filename

      {% if compare_versions(Crystal::VERSION, "1.13.0") == -1 %}
      abort "file not readable: #{filename}" unless File.readable? filename
      {% else %}
      abort "file not readable: #{filename}" unless File::Info.readable? filename
      {% end %}

      lines = File.read(filename).strip.split /\n/
   else
      lines = contents.strip.split /\n/
   end

   ##############
   # GO THROUGH #
   ##############
   Data.file_line_count = 0
   i = 0
   until lines.size == 0
      i += 1
      line = lines.shift + " "
      Data.file_line_count = i + 1
      Data.instructions = [] of Array(String)

      unless line.starts_with?("@") && line.size > 1
         Outcome.append line
      else

         txt = parse_insts line

         # CALL BEFORE ADDTING TEXT #
         cmnt = false
         # puts instructions
         Data.instructions.each { |inst|
            # SPECIAL CASES #
            # comments #
            if inst[0] == "cmnt"
               cmnt = true
               break
            end

            # sourcing #
            if inst[0] == "source" || inst[0] == "sourceclear"
               arg = inst[1]
               # checks
               if arg.empty?
                  abort "missing argument for: #{inst[0]}" \
                     + "in file: #{filename} at line #{i+1}"
               end
               unless File.exists? arg
                  abort "not a file: #{arg} " \
                     + "in file: #{filename} at line #{i+1}"
               end
               {% if compare_versions(Crystal::VERSION, "1.13.0") == -1 %}
                  unless File.readable? arg
                     abort "not readable: #{arg} " \
                        + "in file: #{filename} at line #{i+1}"
                  end
               {% else %}
                  unless File::Info.readable? arg
                     abort "not readable: #{arg} " \
                        + "in file: #{filename} at line #{i+1}"
                  end
               {% end %}

               insts = Data.instructions

               c = File.read(arg).rstrip + "\n"
               if inst[0] == "sourceclear" && !Data.plaintext
                  c += get_reset_line
               end
               process_file arg, contents=c, init=false

               lines.unshift ""

               # reset some more stuff
               Data.filename = filename
               Data.file_line_count = i + 1
               Data.instructions = insts

               next
               puts "here~!"
            end

            # no arg #
            if Insts.no_arg.has_key? inst[0]
               # check
               unless inst[1].empty?
                  abort "extra argument given to: #{inst[0]} " \
                     + "in file: #{filename} at line #{i+1}"
               end

               # call
               Insts.no_arg[inst[0]][0].call

            # 1 arg #
            elsif Insts.with_arg.has_key? inst[0]
               # check
               if inst[1].empty?
                  abort "missing argument for: #{inst[0]}" \
                     + " in file: #{filename} at line #{i+1}"
               end
               # call
               Insts.with_arg[inst[0]][0].call(inst[1])
            # missing inst #
            else
               abort "unknown instruction: #{inst[0]} in file: #{filename} " \
                  + "at line #{i+1}"
            end
         }

         # exit if comment
         next if cmnt
         
         # add text
         Outcome.append txt unless txt.strip.empty?


         # CALL AFTER ADDTING TEXT #
         Data.instructions.each { |inst|
            if Insts.no_arg.has_key? inst[0]
               Insts.no_arg[inst[0]][1].call
            else
               Insts.with_arg[inst[0]][1].call(inst[1])
            end
         }
      end
   end
end
