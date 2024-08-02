require "./data.cr"

def esc2latex(line : String)
   num_of_bracs = 0
   tokens = line.split "\x1b"
   outcome = tokens.shift

   is_italic = false
   is_bold = false
   is_underline = false
   reset = false

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
            is_italic = false
            is_bold = false
            is_underline = false
            Data.export_last_fg = "\\textcolor{fgdefault}{"
            Data.export_last_bg = "\\colorbox{bgdefault}{"
            num_of_bracs = -1
         when "39"
            outcome += sf("\\textcolor{fgdefault}{")
         when "49"
            sb("\\colorbox{bgdefault}{")
            reset = true

         # font #
         when "1"
            outcome += "\\textbf{"
            is_bold = true
         when "3"
            outcome += "\\textit{"
            is_italic = true
         when "4"
            outcome += "\\underline{"
            is_underline = true

         when "22"
            is_bold = false
            reset = true
         when "23"
            is_italic = false
            reset = true
         when "24"
            is_underline = false
            reset = true

         # fg normal #
         when "30"
            outcome += sf("\\textcolor{nblack}{")
         when "31"
            outcome += sf("\\textcolor{nred}{")
         when "32"
            outcome += sf("\\textcolor{ngreen}{")
         when "33"
            outcome += sf("\\textcolor{nyellow}{")
         when "34"
            outcome += sf("\\textcolor{nblue}{")
         when "35"
            outcome += sf("\\textcolor{nmagenta}{")
         when "36"
            outcome += sf("\\textcolor{ncyan}{")
         when "37"
            outcome += sf("\\textcolor{nwhite}{")

         # fg bright #
         when "90"
            outcome += sf("\\textcolor{bblack}{")
         when "91"
            outcome += sf("\\textcolor{bred}{")
         when "92"
            outcome += sf("\\textcolor{bgreen}{")
         when "93"
            outcome += sf("\\textcolor{byellow}{")
         when "94"
            outcome += sf("\\textcolor{bblue}{")
         when "95"
            outcome += sf("\\textcolor{bmagenta}{")
         when "96"
            outcome += sf("\\textcolor{bcyan}{")
         when "97"
            outcome += sf("\\textcolor{bwhite}{")

         # bg normal #
         when "40"
            sb("\\colorbox{nblack}{")
            reset = true
         when "41"
            sb("\\colorbox{nred}{")
            reset = true
         when "42"
            sb("\\colorbox{ngreen}{")
            reset = true
         when "43"
            sb("\\colorbox{nyellow}{")
            reset = true
         when "44"
            sb("\\colorbox{nblue}{")
            reset = true
         when "45"
            sb("\\colorbox{nmagenta}{")
            reset = true
         when "46"
            sb("\\colorbox{ncyan}{")
            reset = true
         when "47"
            sb("\\colorbox{nwhite}{")
            reset = true

         # bg bright #
         when "100"
            sb("\\colorbox{bblack}{")
            reset = true
         when "101"
            sb("\\colorbox{bred}{")
            reset = true
         when "102"
            sb("\\colorbox{bgreen}{")
            reset = true
         when "103"
            sb("\\colorbox{byellow}{")
            reset = true
         when "104"
            sb("\\colorbox{bblue}{")
            reset = true
         when "105"
            sb("\\colorbox{bmagenta}{")
            reset = true
         when "106"
            sb("\\colorbox{bcyan}{")
            reset = true
         when "107"
            sb("\\colorbox{bwhite}{")
            reset = true

         # RGB #
         when "38"
            escs.shift
            r = escs.shift
            g = escs.shift
            b = escs.shift
            outcome += sf("\\textcolor[RGB]{#{r},#{g},#{b}}{")

         when "48"
            escs.shift
            r = escs.shift
            g = escs.shift
            b = escs.shift
            sb("\\colorbox[RGB]{#{r},#{g},#{b}}{")
            reset = true

         else 
            num_of_bracs -= 1

         end

         if reset
            reset = false
            outcome += "}" * num_of_bracs

            t = construct_beginning is_bold, is_italic, is_underline
            num_of_bracs = t.count('{') - t.count('}') - 1
            outcome += t
         end      

         num_of_bracs += 1
      end

      outcome += txt
   }
   outcome += "}" * num_of_bracs

   # remove ampty colorboxes
   return outcome.gsub \
      /\\colorbox(?:\[RGB\])?\{[^\}]+\}\{(?:\\\w+(?:\{\})?\ ?)*\}/, ""
end

def sf(txt : String)
   Data.export_last_fg = txt
end

def sb(txt : String)
   Data.export_last_bg = txt
end

def construct_beginning(is_bold, is_italic, is_underline)
   txt = Data.export_last_fg + Data.export_last_bg
   if is_bold
      txt += "\\textbf{"
   end
   if is_italic
      txt += "\\textit{"
   end
   if is_underline
      txt += "\\underline{"
   end

   txt
end
