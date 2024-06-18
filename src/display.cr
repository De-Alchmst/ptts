require "./data.cr"
require "./outcome.cr"

require "term-reader"

def display()

   if Data.output_mode == :stdout
      Outcome.pages.each { |page|
         page.lines.each { |line|
            puts line.text
         }
      }

      exit
   end

   # switch to alternate buffer
   print "\x1b[?1049h\x1b[H"

   reader = Term::Reader.new

   loop {
      draw_screen

      char = reader.read_keypress

      if char == "\u0018"
         exit
      end

      case char.to_s.gsub '\e', ""
         when "q"
            reset
            exit

         when "j", "[B"
            Data.scroll+=1
         when "k", "[A"
            Data.scroll-=1 unless Data.scroll == 0
      end
   }

   rescue e : Term::Reader::InputInterrupt
      reset
end

def clear_screen
   print "\x1b[H" + " " * Data.term_width * Data.term_height
end

def draw_screen
   clear_screen

   # display lines #
   print "\x1b[H"
   (0..Data.term_height-2).each { |i|
      if Data.scroll+i >= Outcome.pages[0].lines.size
         break
      end
      puts Outcome.pages[0].lines[Data.scroll + i].text
   }

   draw_bar
end

def draw_bar
   print "\x1b[#{Data.term_height};0H"
   print "\x1b[0;7m" \
      + " " * Data.term_width \
      + "\x1b[0m"
end

def reset
   # go back to regular buffer
   print "\x1b[?1049l"
end
