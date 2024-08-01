require "./data.cr"

def esc2latex(line : String)
   num_of_bracs = 0
   tokens = line.split "\x1b"
   outcome = tokens.shift

   tokens.each { |token|

      splt = token.partition /m/
      # get escape codes
      escs = splt[0][(1..)].split ";"

      # get text
      txt = splt[2]

      outcome += txt

      while escs.size > 0
         esc = escs.shift
      end
   }

   return outcome
end
