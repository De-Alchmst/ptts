require "./data.cr"
require "./outcome.cr"
require "./instructions.cr"
require "./inst_parse.cr"

def process_file(filename : String)
   Outcome.init
   Data.filename = filename

   #################
   # READ THE FILE #
   #################

   abort "file not found: #{filename}" unless File.exists? filename
   abort "file not readable: #{filename}" unless File.readable? filename

   lines = File.read(filename).strip.split /\n/

   ##############
   # GO THROUGH #
   ##############
   lines.size.times { |i|
      line = lines[i].strip + " "
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
            if inst[0] == "cmnt"
               cmnt = true
               break
            end

            # no arg #
            if Insts.no_arg.has_key? inst[0]
               # check
               unless inst[1].empty?
                  abort "extra argument given to: #{inst[0]} " \
                     + "in file: #{filename} at line #{i}"
               end

               # call
               Insts.no_arg[inst[0]][0].call

            # 1 arg #
            elsif Insts.with_arg.has_key? inst[0]
               # check
               if inst[1].empty?
                  abort "missing argument for: #{inst[0]}" \
                     + " in file: #{filename} at line #{i}"
               end
               # call
               Insts.with_arg[inst[0]][0].call(inst[1])
            # missing inst #
            else
               abort "unknown instruction: #{inst[0]} in file: #{filename} " \
                  + "at line #{i}"
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
   }
end
