require "./data.cr"
require "./pages.cr"

module Outcome
   class_property pages, alingment, indent

   @@alingment = Alingment::Left

   @@indent = 0

   @@pages = [] of Page

   def self.init
      @@pages = [Page.new(@@alingment, 0, :regular)]
      @@alingment = Alingment::Left

      @@indent = 0
   end

   def self.alingment=(@@alingment : Alingment)
      cur_page() = @alingment
   end

   def self.new_page(page_type = :regular)
      @@pages << Page.new(@@alingment, @@indent, page_type)
   end

   # insert text to line like normal
   def self.append(text : String, strip=true)
      overflow = @@pages.last.append text, strip

      unless overflow.empty?
         @@pages << Page.new(@@alingment, @@indent, :regular)
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

   def self.new_block
      eop = @@pages.last.new_block
      if eop
         @@pages << Page.new(@@alingment, @@indent, :regular)
      end
      nil
   end

   def self.reset_indent
      @@pages.last.reset_indent
   end
end
