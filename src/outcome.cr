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

   @@pages = [] of Page

   def self.init
      @@pages = [Page.new(@@alingment, 0)]
      @@alingment = Alingment::Left

      @@fg = "39"
      @@bg = "39"

      @@bold = false
      @@italic = false
      @@underline = false

      @@indent = 0
   end

   def self.alingment=(@@alingment : Alingment)
      cur_page() = @alingment
   end

   # insert text to line like normal
   def self.append(text : String, strip=true)
      overflow = @@pages.last.append text, strip

      unless overflow.empty?
         @@pages << Page.new(@@alingment, @@indent)
         self.append overflow
      end
   end

   # inserts text sneakily
   def self.insert(text : String)
      @@pages.last.insert text
      nil
   end

   # wrappers over last page
   def self.curr_width
      @@pages.last.curr_width
   end

   def self.skip_space=(new)
      @@pages.last.skip_space = new
   end
   def self.skip_space
      @@pages.last.skip_space
   end

   def self.indent=(new)
      @@indent = new
      pages.last.indent = new
   end
   # change stuff

   def self.fg=(new)
      @@fg = Colors.fg[new]
   end
   def self.bg=(new)
      @@bg = Colors.bg[new]
   end

   def self.new_block
      eop = @@pages.last.new_block
      if eop
         @@pages << Page.new(@@alingment, @@indent)
      end
      nil
   end

   def self.reset_indent
      @@pages.last.reset_indent
   end
end
