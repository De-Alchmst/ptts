require "./data.cr"

def parse_insts(line)
   enclose_level = 0 # for nested '{' '}'
   prev = 0
   txt = ""

   # split into instructions
   (2..line.size-1).each { |i|
      case "#{line[i]}"
      when "{"
         enclose_level += 1
      when "}"
         enclose_level -= 1
      when /[;\s]/
         if enclose_level == 0
            inst = line[prev+1..i-1] # entire instruction

            # get argument
            # shamelessly taken fom here
            # https://stackoverflow.com/questions/19486686/recursive-nested-matching-pairs-of-curly-braces-in-ruby-regex
            arg_match = inst.match /(?=\{((?:[^{} ]*?|\{\g<1>\})*?)\})/
            # only the capture if found
            arg = arg_match ? arg_match[1] : ""

            Data.instructions << [inst.sub(/\{.*/, ""), arg]

            if line[i] == ';'
               prev = i
            else
               txt = line[i+1..]
               break
            end
         end
      end
   }

   return txt
end
