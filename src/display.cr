require "./pages.cr"
require "./data.cr"

def show(book : String)
   # for some reason \n behaves as it should
   # probably a ncurses thing
   puts "#{Data.term_width}, #{Data.term_height}\r"
   puts book
end
