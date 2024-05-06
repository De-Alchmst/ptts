require "./data.cr"
require "./pages.cr"

module Outcome
   class_property pages, fg, bg, alingment, bold, italic, underline

   @@alingment = Alingment::Left

   @@fg = "39"
   @@bg = "39"

   @@bold = false
   @@italic = false
   @@underline = false


   @@pages = [Page.new(@@alingment)]

   def cur_page
      @@pages.last
   end

   def alingment=(@@alingment : Alingment)
      cur_page() = @alingment
   end

   # insert text to line like normal
   def append(text : String)

   end

   # change stuff

   def fg=(new)
      @@fg = Colors.fg[new]
   end
   def bg=(new)
      @@bg = Colors.bg[new]
   end

   def bold=(new)
      @@bold = new
   end
   def italic=(new)
      @@italic = new
   end
   def underline=(new)
      @@underline = new
   end
end
