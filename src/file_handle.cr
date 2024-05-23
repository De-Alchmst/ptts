require "./data.cr"
require "./outcome.cr"
require "./instructions.cr"

def process_file(filename : String)
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

      unless line.starts_with?("@") && line.size > 1
         Outcome.append line
      else

         instructions = [] of Array(String)
         enclose_level = 0 # for nested '{' '}'
         prev = 0
         txt = ""

         # split into instructions
         (2..line.size-1).each { |i|
            case "#{line[i]}"
            when '{'
               enclose_level += 1
            when '}'
               enclose_level -= 1
            when /[;\s]/
               if enclose_level == 0
                  inst = line[prev+1..i-1] # entire instruction

                  # get argument
                  arg_match = inst.match /\{(.*?)\}/
                  # only the capture if found
                  arg = arg_match ? arg_match[1] : ""

                  instructions << [inst.sub(/\{.*/, ""), arg]

                  if line[i] == ';'
                     prev = i
                  else
                     txt = line[i+1..]
                     break
                  end
               end
            end
         }

         # CALL BEFORE ADDTING TEXT #
         cmnt = false
         # puts instructions
         instructions.each { |inst|
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
         instructions.each { |inst|
            if Insts.no_arg.has_key? inst[0]
               Insts.no_arg[inst[0]][1].call
            else
               Insts.with_arg[inst[0]][1].call(inst[1])
            end
         }
      end
   }
end
