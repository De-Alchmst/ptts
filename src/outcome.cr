require "./data.cr"
require "./pages.cr"

module Outcome
   class_property pages, fg, bg, alingment, bold, italic, underline, indent

   @@alingment = Alingment::Left

   @@fg = "39"
   @@bg = "39"

   @@bold = false
   @@italic = false
   @@underline = false

   @@indent = 0

   @@pages = [Page.new(@@alingment, 0)]

   def self.alingment=(@@alingment : Alingment)
      cur_page() = @alingment
   end

   # insert text to line like normal
   def self.append(text : String)
      overflow = @@pages.last.append text

      unless overflow.empty?
         @@pages << Page.new(@@alingment, @@indent)
         self.append overflow
      end
   end

   # change stuff

   def self.fg=(new)
      @@fg = Colors.fg[new]
   end
   def self.bg=(new)
      @@bg = Colors.bg[new]
   end

   def self.bold=(new)
      @@bold = new
   end
   def self.italic=(new)
      @@italic = new
   end
   def self.underline=(new)
      @@underline = new
   end
end
