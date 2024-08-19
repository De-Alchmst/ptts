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
      pages.last.alingment = @@alingment unless pages.empty?
   end

   def self.new_page(page_type = :regular)
      if pages.last.lines.last.empty
         pages.last.lines.pop
      end
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

   # footnotes #
   def self.add_footnote(text : String, type = :footnote)
      mark = Data.footnote_symbols[pages.last.footnote_index] \
                        * (pages.last.footnote_repeat + 1)

      pages.last.lines.pop if pages.last.lines.last.empty

      self.skip_space = true
      pages.last.append mark
      pages.last.lines.last.footnotes << Footnote.new(mark, text, type)

      pages.last.footnote_index += 1
      if pages.last.footnote_index == Data.footnote_symbols.size
         pages.last.footnote_index = 0
         pages.last.footnote_repeat += 1
      end
   end

   def self.add_label(text : String)
      pages.last.lines.last.labels << text
   end

   def self.reset_footnote_count
      pages.last.footnote_repeat = 0
      pages.last.footnote_index = 0
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
