require "./data.cr"

# get number part if line numbering active
def get_num
   s = Data.line_number.to_s
   padding = Data.num_width - s.size
   if padding < 0
      abort "number while numbering to high"
   end
   
   if !Data.wrap || Data.wrap_now
      " " * padding + s + " "
   else
      " " * (num_w) 
   end
end

# get width of number part if numbering
def num_w
   Data.number_lines ? Data.num_width + 1 : 0
end

class Line
   property text, alingment, empty, footnotes, num, indent, strip
   @footnotes = [] of Footnote
   @num = false
   @strip : Bool

   def initialize(@text : String, @indent : Int32, @alingment : Alingment)
      # if formatting #
      if !Data.plaintext
         # split to indent and contents
         leading_whitespace = ""
         if @indent > 0
            leading_whitespace = @text[0..@indent - 1]
         else
            leading_whitespace = ""
         end
         text_contents = @text[@indent..]

         # reset formatting and add line number
            # add the indent
            # set colors
            # set additional formatting
            # close escape and starting str + contents
         @text = "\x1b[0m" + (Data.number_lines ? get_num : "") \
               + (@alingment == Alingment::Center ? "" : leading_whitespace) \
               + "\x1b[#{Data.prev_colors[:foreground]}" \
               + ";#{Data.prev_colors[:background]}" \
               + (Data.is_bold ? ";1" : "") \
               + (Data.is_italic ? ";3" : "") \
               + (Data.is_underlined ? ";4" : "") \
               + (Data.is_blink ? ";5" : "") \
               + "m" + Data.starts_with + text_contents

      # else just numbers #
      elsif Data.number_lines
         @text = get_num + @text
      end
      @num = true if Data.number_lines

      @strip = Data.strip

      Data.line_number += 1 if !Data.wrap || Data.wrap_now
      Data.wrap_now = false
      @empty = true
   end

   # APPLY ALINGMENT #
   def align
      return @text if @alingment == Alingment::Left

      escapes_start = ""
      escapes_middle = ""
      txt = @text.gsub Data.escape_regex_end, ""
      txt = txt.rstrip if @strip
      number = ""

      puts txt.gsub "\x1b", "\\x1b"

      # split #

      unless Data.plaintext
         escapes_start = "\x1b[0m"
         txt = txt.sub escapes_start, ""
      end

      if @num
         mtch = txt.match(/^ *\d+ /)
         if mtch
            number = mtch[0]
         else
            number = " " * (Data.num_width + 1)
         end
         txt = txt[number.size..]
      end

      unless Data.plaintext
         mtch = txt.match(Data.escape_regex)
         if mtch
            escapes_middle = mtch[0]
            txt = txt.sub escapes_middle, ""
         end
      end


      unless @indent == 0
         leading_whitespace = txt[0..@indent - 1]
      else
         leading_whitespace = ""
      end
      text_contents = ""
      text_contents = txt[@indent..] unless txt.empty?
      txt_size = text_contents.gsub(Data.escape_regex, "").size

      # join back

      if @alingment == Alingment::Right
         puts "---------------"
         puts @num
         puts number.size
         puts "|#{@text}|"
         puts "|#{text_contents.gsub "\x1b", "\\x1b"}|"
         puts txt_size
         puts @indent
         return escapes_start + number + " " * (Data.term_width - number.size \
                                                - txt_size \
                                                - @indent) \
                       + escapes_middle + text_contents + \
                       (Data.plaintext ? "" : "\x1b[0m") \
                       + leading_whitespace
      end

      escapes_start + number + " " * ((Data.term_width - number.size \
                                                       - txt_size) / 2).to_i \
                    + escapes_middle + text_contents
   end
end

class Page
   property indent, skip_space, lines, curr_width, default_width, page_type,
      footnote_repeat, footnote_index

   @footnote_repeat = 0
   @footnote_index = 0
   @curr_width = 0
   @skip_space = false

   def initialize(@alingment : Alingment, @indent : Int32, @page_type : Symbol)
      @lines = [Line.new(" " * indent, @indent, @alingment)]
   end

   def alingment
      @alingment
   end
   def alingment=(@alingment : Alingment)
      new_block
   end

   def indent
      unless lines.empty? || lines.last.alingment == Alingment::Center
         @indent
      else
         0
      end
   end

   # gets width of empty line
   def default_width
      indent + num_w + Data.starts_with.size
   end

   ###################################
   # insert text to line like normal #
   ###################################
   def append(text : String, strip=true)
      if strip && Data.strip
         text = text.strip
      end

      # empty lines
      if text.empty?
         unless @lines.last.empty
            Data.wrap_now = true
            @lines << Line.new(" " * indent, @indent, @alingment)
            @curr_width = default_width
         end
         return ""
      end

      # add space and stuff
      unless @lines.last.empty || @skip_space || !strip
         text = " " + text
      end

      # insert #
      # if stuff goes nicely
      if @curr_width + text.size <= Data.term_width
         @lines.last.text += text
         @curr_width += text.size
         @lines.last.empty = false
      #if it does not
      else
         # split into words
         words = text.split

         # insert as many words on current line
         while words.first.size + @curr_width < Data.term_width
            w = words.shift
            w = " " + w unless @curr_width == indent + num_w || @skip_space
            @skip_space = false

            @lines.last.text += w
            @curr_width += w.size
            @lines.last.empty = false

            break if words.empty?
         end

         # if word is too long
         if !words.empty? && default_width + words.first.size >= Data.term_width
            # if something on line
            unless @lines.last.empty
               @lines << Line.new(" " * indent + \
                                  words[0][..Data.term_width - 1 - indent \
                                           - num_w], \
                                           @indent, @alingment)
            # if one word uder multiple lines
            else
               @lines.last.text += words[0][..Data.term_width - 1 - indent \
                                            - num_w] 
            end

            words[0] = words[0][Data.term_width..]
         end

         # call again with rest of words
         @curr_width = default_width
         @lines << Line.new(" " * indent, @indent, @alingment)

         append words.join(" ")
      end

      @skip_space = false

      if Data.hardnl
         Data.wrap_now = true
         @lines << Line.new(" " * indent, @indent, @alingment)
         @curr_width = default_width
      end

      # for when multipe pages will be used
      return ""
   end

   # sneakely insert text (escape sequence) #
   # to line without any other consequences #
   def insert(text : String)
      @lines.last.text += text
   end

   # make sure last line is empty #
   def new_block
      if @lines.last.empty
         @lines.pop
         Data.line_number -= 1
      end

      Data.wrap_now = true

      @lines << Line.new(" " * indent, @indent, @alingment)
      @curr_width = default_width

      nil
   end

   def reset_indent
      if @lines.last.empty
         if Data.number_lines
            num = @lines.last.text.match(/(..\d )/).as(Regex::MatchData)[1]
            rest = @lines.last.text.match(/..\d (.*)/).as(Regex::MatchData)[1]

            @lines.last.text = num + rest.strip + " " * indent
         else
            @lines.last.text = @lines.last.text.strip + " " * indent
         end
         @curr_width = default_width
      end
   end
end
