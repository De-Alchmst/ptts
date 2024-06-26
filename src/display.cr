require "./data.cr"
require "./outcome.cr"
require "./meta_process.cr"

require "term-reader"

def display()
   # get texts #
   normal_lines = [] of String
   Outcome.pages.each { |page|
      page.lines.each { |line|
         normal_lines << line.text
      }
   }

   meta_lines = [] of String
   get_meta.each { |line|
      meta_lines << line.text
   }

   Data.current_lines = normal_lines

   meta_scroll = 0
   normal_scroll = 0
   current_lines = :normal

   # switch to alternate buffer
   print "\x1b[?1049h\x1b[H"

   reader = Term::Reader.new

   prev_key = ""

   draw_screen
   draw_bar

   loop {
      char = reader.read_keypress.to_s.gsub '\e', ""

      # ctrl-c
      exit if char == "\u0018" 

      case char
         # quit
         when "q"
            reset
            exit

         # normal scroll (somehow also works with mouse scroll?)
         when "k", "[A"
            Data.scroll -= 1 unless Data.scroll == 0
         when "j", "[B"
            Data.scroll += 1

         # pg up / down
         when "[5~", "\u0015"
            Data.scroll -= ((Data.term_height - 1) / 2).to_i
            Data.scroll = 0 if Data.scroll < 0
         when "[6~", "\u0004"
            Data.scroll += ((Data.term_height - 1) / 2).to_i

         # home/end 
         when "[1~"
            Data.scroll = 0
         when "g"
            if prev_key == "g"
               Data.scroll = 0
               prev_key = ""
            else
               prev_key = "g"
            end
         when "G", "[4~"
            new = Data.current_lines.size - Data.term_height + 1
            Data.scroll = new if new > 0

         # search
         when "/", "\u0006"
            # get user input
            prompt = reader.read_line(
               prompt: "\x1b[#{Data.term_height};0H\x1b[0;7m regex search: ")
            num = search prompt

            draw_screen

            # if no match
            if num == 0
               txt = " no matches found for #{prompt.strip}"

               if txt.size > Data.term_width
                  txt = " no matches found"
                  if txt.size > Data.term_width
                     txt = "no"
                  end
               end

               print "\x1b[#{Data.term_height};0H\x1b[0;7m" \
                   + txt + " " * (Data.term_width - txt.size) 
               next
            end

            # if some match
            show_search
            next

         when "n"
            Data.search_index += 1
            Data.search_index %= Data.search_list.size
            show_search
            next
         when "N"
            Data.search_index -= 1
            if Data.search_index < 0
               Data.search_index = Data.search_list.size-1
            end
            show_search
            next

         # toggle meta
         when "m"
            if current_lines == :normal
               current_lines = :meta
               normal_scroll = Data.scroll
               Data.scroll = meta_scroll
               Data.current_lines = meta_lines
            else
               current_lines = :normal
               meta_scroll = Data.scroll
               Data.scroll = normal_scroll
               Data.current_lines = normal_lines
            end
      end

      prev_key = "" unless char = "g"

      draw_screen
      draw_bar
   }

   rescue e : Term::Reader::InputInterrupt
      reset
end

def clear_screen
   print "\x1b[0m\x1b[H" + " " * Data.term_width * Data.term_height
end

def draw_screen
   clear_screen

   # display lines #
   print "\x1b[H"
   (0..Data.term_height-2).each { |i|
      if Data.scroll+i >= Data.current_lines.size
         break
      end
      puts Data.current_lines[Data.scroll + i]
   }
end

def draw_bar
   bar = ""

   scroll = "scroll: #{Data.scroll}"
   gap = Data.term_width - Data.filename.size - scroll.size - 2

   if gap < 0
      scroll = Data.scroll.to_s
      gap = Data.term_width - Data.filename.size - scroll.size - 2
   end

   if gap >= 0
      bar = " " + Data.filename + " " * gap + scroll + " "
   elsif scroll.size - 1 <= Data.term_width
      bar = " " + scroll + " " * (Data.term_width - scroll.size)
   else
      bar = " " * Data.term_width
   end

   print "\x1b[#{Data.term_height};0H\x1b[0;7m" + bar + "\x1b[0m"
end

def reset
   # go back to regular buffer
   print "\x1b[?1049l"
end

def search(prompt)
   Data.search_index = 0
   Data.search_list = [] of SearchItem

   prom = Regex.new(prompt.gsub /\n/, "")
   num = 0
   # go through lines #
   (0..Data.current_lines.size-1).each { |i|
      # line stripped of all escape sequences
      ln = Data.current_lines[i].gsub Regex.new("\x1b\\[.*?m"), ""

      offset = 0
      while m = prom.match(ln, offset)
         Data.search_list.push SearchItem.new(i, m.begin(0), m.end(0))
         offset = m.end 0
         num += 1
      end
   }

   return num
end

def show_search
   Data.scroll = Data.search_list[Data.search_index].position
   draw_screen

   # custom bar #
   bar = ""

   scroll = "scroll: #{Data.scroll}"
   srch = "search: #{Data.search_index+1}/#{Data.search_list.size}"

   gap = Data.term_width - srch.size - scroll.size - 2

   if gap < 0
      scroll = Data.scroll.to_s
      srch = "#{Data.search_index+1}/#{Data.search_list.size}"
      gap = Data.term_width - Data.filename.size - scroll.size - 2
   end

   if gap >= 0
      bar = " " + srch + " " * gap + scroll + " "
   elsif srch.size - 1 <= Data.term_width
      bar = " " + srch + " " * (Data.term_width - scroll.size)
   else
      bar = " " * Data.term_width
   end

   print "\x1b[#{Data.term_height};0H\x1b[0;7m" + bar + "\x1b[0m"

   # move cursor to position
   print "\x1b[0;#{Data.search_list[Data.search_index].match_start + 1}H"
end
