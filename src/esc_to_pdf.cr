require "./data.cr"

def escM_to_pdf(esc : String)
   txt = ") Tj\n"

   escs = esc.split(";")
   while escs.size > 0
      e = escs.shift
      cl = ""
      case e
      when "0"
         cl = "0 0 0 rg\n"

      # FG standard #
      when "30"
         cl = "0 0 0 rg\n"
      when "31"
         cl = "0.8 0 0 rg\n"
      when "32"
         cl = "0 0.8 0 rg\n"
      when "33"
         cl = "0.8 0.8 0 rg\n"
      when "34"
         cl = "0 0 0.8 rg\n"
      when "35"
         cl = "0.8 0 0.8 rg\n"
      when "36"
         cl = "0 0.8 0.8 rg\n"
      when "37"
         cl = "0.8 0.8 0.8 rg\n"

      when "39"
         cl = "0 0 0 rg\n"

      when "90"
         cl = "0.2 0.2 0.2 rg\n"
      when "91"
         cl = "1 0 0 rg\n"
      when "92"
         cl = "0 1 0 rg\n"
      when "93"
         cl = "1 1 0 rg\n"
      when "94"
         cl = "0 0 1 rg\n"
      when "95"
         cl = "1 0 1 rg\n"
      when "96"
         cl = "0 1 1 rg\n"
      when "97"
         cl = "1 1 1 rg\n"

      # FG rgb #
      when "38"
         _ = escs.shift
         r = escs.shift.to_i / 255.0
         g = escs.shift.to_i / 255.0
         b = escs.shift.to_i / 255.0
         cl = "#{r} #{g} #{b} rg\n"

      # BG rgb #
      when "48"
         _ = escs.shift
         r = escs.shift.to_i / 255.0
         g = escs.shift.to_i / 255.0
         b = escs.shift.to_i / 255.0
         # cl = "#{r} #{g} #{b} rg\n"
      end

      txt += cl
   end
   return txt + " ("
end
