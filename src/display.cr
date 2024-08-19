require "./data.cr"
require "./outcome.cr"
require "./builtin_documents.cr"

require "term-reader"

########################################
# HANDLE RESIZING IN A SEPERATE THREAD #
########################################
# gives as pointers
def handle_resizing(normal_lines, meta_lines, manual_lines, index_lines, \
                    prev_name)
   spawn {
      x : Int32
      y : Int32
      loop {
         sleep 0.25
         x = `tput cols`.to_i
         y = `tput lines`.to_i

         if x != Data.term_width || y != Data.term_height
            Data.term_width = x
            Data.term_height = y

            Data.normal_footnotes.clear
            unless Data.manual_mode
               process_file prev_name
            else
               get_manual
            end
            Data.filename = prev_name

            lines = get_lines
            normal_lines.replace lines[0]
            meta_lines.replace lines[1]
            manual_lines.replace lines[2]

            case Data.current_lines_mode
            when :normal
               Data.current_lines = normal_lines
               Data.current_footnotes = Data.normal_footnotes
            when :meta
               Data.current_lines = meta_lines
               Data.current_footnotes = Data.meta_footnotes
            when :manual
               Data.current_lines = manual_lines
               Data.current_footnotes = Data.manual_footnotes
            when :index
               Data.current_lines = index_lines
               Data.current_footnotes = {} of Int32 => Array(Footnote)
            end

            Data.filename = prev_name

            Data.footnote_size = 0
            draw_screen
            draw_bar

            print "\x1b[HPRESS ANY KEY TO REFRESH"
         end
      }
   }
end

##############################
# GET LINES OF ALL DOCUMENTS #
##############################
def get_lines
   normal_lines = [] of String

   # get normal lines #
   Outcome.pages.size.times {|i|
      Outcome.pages[i].lines.each { |line|
         normal_lines << line.align

         # footnotes #
         unless line.footnotes.empty?
            Data.normal_footnotes[normal_lines.size - 1] = line.footnotes
         end

         unless line.labels.empty?
            line.labels.each { |label|
               Data.labels[label] = normal_lines.size - 1
            }
         end
      }

      # page breaks #
      unless i == Outcome.pages.size - 1
         new = "-" * ((Data.term_width - 6) / 2).floor.to_i \
            + "PG-END" + "-" * ((Data.term_width - 6) / 2).ceil.to_i

         normal_lines.pop if Outcome.pages[i].lines.last.empty
         if Data.plaintext
            normal_lines << new
         else
            normal_lines << "\x1b[0m" + new
         end

         ### IF STDOUT ###
         if Data.output_mode == :stdout
            Data.normal_footnotes.values.each {|ftnts|
               ftnts.each {|ftnt|
                  normal_lines << ftnt.text
               }
            }
            Data.normal_footnotes = {} of Int32 => Array(Footnote)
         end
         #################

         4.times {
            normal_lines << ""
         }
      end
   }

   # META #
   meta_lines = [] of String
   Data.meta_footnotes.clear
   get_meta.each { |line|
      meta_lines << line.align

      # footnotes #
      unless line.footnotes.empty?
         Data.meta_footnotes[meta_lines.size - 1] = line.footnotes
      end
   }

   # INDEX #
   index_lines = [] of String
   Data.labels.each { |k, v|
      new = "#{v + 1} : #{k}"
      # one label only on one line
      if new.size > Data.term_width - 2
         new = new[0, Data.term_width - 5] + "..."
      end

      index_lines << new
   }

   # INDEX FLAG #
   if Data.index_end
      normal_lines << (Data.plaintext ? "" : "\x1b[0m") \
         + "-" * ((Data.term_width - 5) / 2).floor.to_i \
         + "INDEX" + "-" * ((Data.term_width - 5) / 2).ceil.to_i
      normal_lines += index_lines
   end

   if Data.index_front
      ln = [] of String

      ln << (Data.plaintext ? "" : "\x1b[0m") \
         + "-" * ((Data.term_width - 5) / 2).floor.to_i \
         + "INDEX" + "-" * ((Data.term_width - 5) / 2).ceil.to_i

      ln += index_lines

      ln << (Data.plaintext ? "" : "\x1b[0m") \
         + "-" * ((Data.term_width - 8) / 2).floor.to_i \
         + "CONTENTS" + "-" * ((Data.term_width - 8) / 2).ceil.to_i

      shift_len = ln.size
      # fix footnotes
      nf = {} of Int32 => Array(Footnote)

      Data.normal_footnotes.each { |k, v|
         nf[k + shift_len] = v
      }
      Data.normal_footnotes = nf

      # fix labels
      Data.labels.each { |k, v|
         Data.labels[k] = v + shift_len
      }

      normal_lines = ln + normal_lines
   end

   # META FLAG #
   if Data.meta_end
      normal_lines << (Data.plaintext ? "" : "\x1b[0m") \
         + "-" * ((Data.term_width - 4) / 2).floor.to_i \
         + "META" + "-" * ((Data.term_width - 4) / 2).ceil.to_i
      normal_lines += meta_lines
   end

   if Data.meta_front
      ln = [] of String

      ln << (Data.plaintext ? "" : "\x1b[0m") \
         + "-" * ((Data.term_width - 4) / 2).floor.to_i \
         + "META" + "-" * ((Data.term_width - 4) / 2).ceil.to_i

      ln += meta_lines

      unless Data.index_front
         ln << (Data.plaintext ? "" : "\x1b[0m") \
            + "-" * ((Data.term_width - 8) / 2).floor.to_i \
            + "CONTENTS" + "-" * ((Data.term_width - 8) / 2).ceil.to_i
      end

      shift_len = ln.size
      # fix footnotes
      nf = {} of Int32 => Array(Footnote)

      Data.normal_footnotes.each { |k, v|
         nf[k + shift_len] = v
      }
      Data.normal_footnotes = nf

      # fix labels
      Data.labels.each { |k, v|
         Data.labels[k] = v + shift_len
      }

      normal_lines = ln + normal_lines
   end

   # MANUAL #
   manual_lines = [] of String
   Data.manual_footnotes.clear
   get_manual.each { |line|
      manual_lines << line.align

      # footnotes #
      unless line.footnotes.empty?
         Data.manual_footnotes[manual_lines.size - 1] = line.footnotes
      end
   }

   return normal_lines, meta_lines, manual_lines, index_lines
end

def display()
   #############
   # GET TEXTS #
   #############
   prev_name = Data.filename


   lines = get_lines
   normal_lines, meta_lines, manual_lines, index_lines = lines

   Data.filename = prev_name

   Data.current_lines = normal_lines
   Data.current_footnotes = Data.normal_footnotes

   meta_scroll = 0
   normal_scroll = 0
   manual_scroll = 0
   index_scroll = 0
   Data.current_lines_mode = :normal

   #######################
   # IF OUTPUT TO STDOUT #
   #######################

   if Data.output_mode == :stdout
      normal_lines.each {|line|
         puts line
      }

      puts "-" * Data.term_width
      Data.normal_footnotes.values.each {|ftnts|
         ftnts.each {|ftnt|
            puts ftnt.text
         }
      }
      exit
   end

   #########
   # SETUP #
   #########

   # switch to alternate buffer
   print "\x1b[?1049h\x1b[H"

   reader = Term::Reader.new

   prev_key = ""

   draw_screen
   draw_bar

   handle_resizing normal_lines, meta_lines, manual_lines, index_lines, \
                   prev_name

   ################
   # INPUT HANDLE #
   ################

   loop {
      char = reader.read_keypress(nonblock: true).to_s.gsub '\e', ""

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
            prev_footnote_size = -1

            # scroll to bottom until end right above footnote
            until prev_footnote_size == Data.footnote_size
               prev_footnote_size = Data.footnote_size
               Data.footnote_size = 0

               new = Data.current_lines.size - Data.term_height + 1 \
                   + prev_footnote_size
               Data.scroll = new if new > 0

               draw_screen
               # if top line is a footnote that keeps getting in and
               # out of the view
               break if prev_footnote_size <= Data.footnote_size
            end

         # search
         when "/", "\u0006"
            # get user input
            print "\x1b[#{Data.term_height};0H\x1b[0;7m" + " " * Data.term_width
            prompt = reader.read_line(
               prompt:"\x1b[#{Data.term_height};0H regex search: ")

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
            next if Data.search_list.size == 0
            Data.search_index += 1
            Data.search_index %= Data.search_list.size
            show_search
            next
         when "N"
            next if Data.search_list.size == 0
            Data.search_index -= 1
            if Data.search_index < 0
               Data.search_index = Data.search_list.size-1
            end
            show_search
            next

         # toggle meta
         when "m"
            unless Data.current_lines_mode == :meta 
               if Data.current_lines_mode == :normal
                  normal_scroll = Data.scroll
               elsif Data.current_lines_mode == :index
                  index_scroll = Data.scroll
               else
                  manual_scroll = Data.scroll
               end
               Data.current_lines_mode = :meta
               Data.scroll = meta_scroll
               Data.current_lines = meta_lines
               Data.filename = "meta"
               Data.current_footnotes = Data.meta_footnotes
            else
               Data.current_lines_mode = :normal
               meta_scroll = Data.scroll
               Data.scroll = normal_scroll
               Data.current_lines = normal_lines
               Data.filename = prev_name
               Data.current_footnotes = Data.normal_footnotes
            end

         # toggle manual
         # F1 registeres as "\eO" "P"
         when "h", "?", "P"
            if char == "P"
               next unless prev_key == "O"
            end

            unless Data.current_lines_mode == :manual 
               if Data.current_lines_mode == :normal
                  normal_scroll = Data.scroll
               elsif Data.current_lines_mode == :index
                  index_scroll = Data.scroll
               else
                  meta_scroll = Data.scroll
               end
               Data.current_lines_mode = :manual
               Data.scroll = manual_scroll
               Data.current_lines = manual_lines
               Data.filename = "manual"
               Data.current_footnotes = Data.manual_footnotes
            else
               Data.current_lines_mode = :normal
               manual_scroll = Data.scroll
               Data.scroll = normal_scroll
               Data.current_lines = normal_lines
               Data.filename = prev_name
               Data.current_footnotes = Data.normal_footnotes
            end

         when "O"
            prev_key = "O"

         # toggle index
         when "i"
            unless Data.current_lines_mode == :index 
               if Data.current_lines_mode == :normal
                  normal_scroll = Data.scroll
               elsif Data.current_lines_mode == :meta
                  meta_scroll = Data.scroll
               else
                  manual_scroll = Data.scroll
               end
               Data.current_lines_mode = :index
               Data.scroll = index_scroll
               Data.current_lines = index_lines
               Data.filename = "index"
               Data.current_footnotes = {} of Int32 => Array(Footnote)
            else
               Data.current_lines_mode = :normal
               index_scroll = Data.scroll
               Data.scroll = normal_scroll
               Data.current_lines = normal_lines
               Data.filename = prev_name
               Data.current_footnotes = Data.normal_footnotes
            end

         when "\r"
            if Data.current_lines_mode == :index \
            && Data.scroll < Data.labels.size
               Data.current_lines_mode = :normal
               index_scroll = Data.scroll
               Data.scroll = Data.labels.values[Data.scroll]
               Data.current_lines = normal_lines
               Data.filename = prev_name
               Data.current_footnotes = Data.normal_footnotes
            end
      end

      prev_key = "" unless char = "g" || char == "O"

      Data.footnote_size = 0

      draw_screen
      draw_bar
   }

   rescue e : Term::Reader::InputInterrupt
      reset
end

#################
# DISPLAY STUFF #
#################

def clear_screen
   print "\x1b[0m\x1b[H" + " " * Data.term_width * Data.term_height
end

def draw_screen
   clear_screen

   # display lines #
   print "\x1b[H"
   
   # reinvent forloop
   i = 0
   loop {
      break if i >= Data.term_height - 1 - Data.footnote_size

      # if no more lines
      break if Data.scroll+i >= Data.current_lines.size

      if i == 0 && Data.current_lines_mode == :index
         print "> "
      end
      puts Data.current_lines[Data.scroll + i]

      # footnotes
      if Data.current_footnotes.keys.includes? i+Data.scroll
         Data.current_footnotes[i+Data.scroll].each {|ftnt|
            add_footnote ftnt
         }
      end

      i += 1
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

def add_footnote(ftnt : Footnote)
   Data.footnote_size = 1 if Data.footnote_size == 0

   # save cursor position and go to beginning
   print "\x1b[s"

   # move cursor
   print "\x1b[#{Data.term_height - Data.footnote_size - ftnt.height};0H\x1b[0m"
   # print the footnote
   print "-" * Data.term_width + "\n" + ftnt.text

   Data.footnote_size += ftnt.height

   # restore cursor position
   print "\x1b[u"
end

def reset
   # go back to regular buffer
   print "\x1b[?1049l"
end

#############
# SEARCHING #
#############

def search(prompt)
   Data.search_index = 0
   Data.search_list = [] of SearchItem

   prom = Regex.new(prompt.gsub /\n/, "")

   #system
   return 0 if prom.source.empty?

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
   Data.footnote_size = 0
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
