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

      while escs.size > 0
         case escs.shift
         when "0"
            outcome += "}" * num_of_bracs
            num_of_bracs = -1
         when "39"
            outcome += "\\textcolor{fgdefault}{"

         # fg normal #
         when "30"
            outcome += "\\textcolor{nblack}{"
         when "31"
            outcome += "\\textcolor{nred}{"
         when "32"
            outcome += "\\textcolor{ngreen}{"
         when "33"
            outcome += "\\textcolor{nyellow}{"
         when "34"
            outcome += "\\textcolor{nblue}{"
         when "35"
            outcome += "\\textcolor{nmagenta}{"
         when "36"
            outcome += "\\textcolor{ncyan}{"
         when "37"
            outcome += "\\textcolor{nwhite}{"

         # fg bright #
         when "90"
            outcome += "\\textcolor{bblack}{"
         when "91"
            outcome += "\\textcolor{bred}{"
         when "92"
            outcome += "\\textcolor{bgreen}{"
         when "93"
            outcome += "\\textcolor{byellow}{"
         when "94"
            outcome += "\\textcolor{bblue}{"
         when "95"
            outcome += "\\textcolor{bmagenta}{"
         when "96"
            outcome += "\\textcolor{bcyan}{"
         when "97"
            outcome += "\\textcolor{bwhite}{"

         # bg normal #
         when "40"
            outcome += "\\colorbox{nblack}{"
         when "41"
            outcome += "\\colorbox{nred}{"
         when "42"
            outcome += "\\colorbox{ngreen}{"
         when "43"
            outcome += "\\colorbox{nyellow}{"
         when "44"
            outcome += "\\colorbox{nblue}{"
         when "45"
            outcome += "\\colorbox{nmagenta}{"
         when "46"
            outcome += "\\colorbox{ncyan}{"
         when "47"
            outcome += "\\colorbox{nwhite}{"

         # bg bright #
         when "100"
            outcome += "\\colorbox{bblack}{"
         when "101"
            outcome += "\\colorbox{bred}{"
         when "102"
            outcome += "\\colorbox{bgreen}{"
         when "103"
            outcome += "\\colorbox{byellow}{"
         when "104"
            outcome += "\\colorbox{bblue}{"
         when "105"
            outcome += "\\colorbox{bmagenta}{"
         when "106"
            outcome += "\\colorbox{bcyan}{"
         when "107"
            outcome += "\\colorbox{bwhite}{"

         # RGB #
         when "38"
            escs.shift
            r = escs.shift
            g = escs.shift
            b = escs.shift
            outcome += "\\textcolor[RGB]{#{r},#{g},#{b}}{"

         when "48"
            escs.shift
            r = escs.shift
            g = escs.shift
            b = escs.shift
            outcome += "\\colorbox[RGB]{#{r},#{g},#{b}}{"

         else 
            num_of_bracs -= 1

         end

         num_of_bracs += 1
      end

      outcome += txt
   }
   outcome += "}" * num_of_bracs

   return outcome
end
