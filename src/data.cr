require "ncurses"

NCurses.start

module Data
   class_property term_width, term_height
   @@term_width : Int32 = NCurses.width
   @@term_height : Int32 = NCurses.height
end
