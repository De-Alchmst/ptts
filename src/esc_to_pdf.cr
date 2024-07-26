require "./data.cr"

def escM_to_pdf(esc : String)
   txt = ") Tj\n"

   esc.split(";").each { |e|
      cl = ""
      case e
      when "0"
         cl = "0 0 0 rg\n"

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
      end

      txt += cl
   }
   return txt + " ("
end
