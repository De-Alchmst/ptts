enum Alingment
   Left
   Center
   Right
end

def get_num
   s = Data.line_number.to_s
   padding = Data.num_width - s.size
   if padding < 0
      abort "number while numbering to high"
   end
   " " * padding + s + " "
end

def num_w
   Data.number_lines ? Data.num_width + 1 : 0
end

class Line
   property text, alingment, empty
   def initialize(@text : String, @alingment : Alingment)
      unless Data.plaintext
         text_leading_whitespace = @text.sub /\S.*/, ""
         text_contents = @text.sub /^\s+/, ""
         @text = "\x1b[0m" + (Data.number_lines ? get_num : "") \
               + text_leading_whitespace \
               + "\x1b[#{Data.prev_colors[:foreground]}" \
               + ";#{Data.prev_colors[:background]}" \
               + (Data.is_bold ? ";1" : "") \
               + (Data.is_italic ? ";3" : "") \
               + (Data.is_underlined ? ";4" : "") \
               + (Data.is_blink ? ";5" : "") \
               + "m" + text_contents

         Data.line_number += 1
      end
      @empty = true
   end
end

class Page
   property indent, skip_space, lines, curr_width

   @curr_width = 0
   @skip_space = false

   def initialize(@alingment : Alingment, @indent : Int32)
      @lines = [Line.new("", @alingment)]
   end

   def alingment
      @alingment
   end
   def alingment=(@alingment : Alingment)
      @lines.last.alingment = @alingment
   end

   ###################################
   # insert text to line like normal #
   ###################################
   def append(text : String, strip=true)
      text = text.strip if strip

      # empty lines
      if text.empty?
         unless @lines.last.empty && @lines.size > 1
            @lines << Line.new(" " * @indent, @alingment)
            @curr_width = @indent + num_w
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
            w = " " + w unless @curr_width == @indent || @skip_space
            @skip_space = false

            @lines.last.text += w
            @curr_width += w.size
            @lines.last.empty = false

            break if words.empty?
         end

         # if word is too long
         if @indent + words.first.size >= Data.term_width
            # if something on line
            unless @lines.last.empty
               @lines << Line.new(" " * @indent + \
                                  words[0][..Data.term_width - 1 - @indent], \
                                  @alingment)
            # if one word uder multiple lines
            else
               @lines.last.text += words[0][..Data.term_width - 1 - @indent] 
            end

            words[0] = words[0][Data.term_width..]
         end

         # call again with rest of words
         @curr_width = @indent + num_w
         @lines << Line.new(" " * @indent, @alingment)

         append words.join(" ")
      end

      @skip_space = false

      if Data.hardnl
         @lines << Line.new(" " * @indent, @alingment)
         @curr_width = @indent + num_w
      end

      # for when multipe pages will be used
      return ""
   end

   # sneakely insert text (escape sequence) #
   # to line without any other consequences #
   def insert(text : String)
      @lines.last.text += text
   end

   def new_block
      if @lines.last.empty
         @lines.last.text = @lines.last.text.strip + " " * @indent
      else
         @lines << Line.new(" " * @indent, @alingment)
      end
      @curr_width = @indent + num_w

      false
   end

   def reset_indent
      if @lines.last.empty
         @lines.last.text = @lines.last.text.strip + " " * @indent
         @curr_width = @indent + num_w
      end
   end
end
