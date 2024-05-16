enum Alingment
   Left
   Center
   Right
end

class Line
   property text, alingment, empty
   def initialize(@text : String, @alingment : Alingment)
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
            @curr_width = @indent
         end
         return ""
      end

      # add space and stuff
      unless @lines.last.empty || @skip_space || !strip
         text = " " + text
      end

      # insert #
      @lines.last.empty = false
      # if stuff goes nicely
      if @curr_width + text.size <= Data.term_width
         @lines.last.text += text
         @curr_width += text.size
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

            break if words.empty?
         end

         # if word is too long
         if @indent + words.first.size >= Data.term_width
            # if something on line
            unless @lines.last.empty
               @lines << Line.new(" " * @indent + \
                                  words[0][..Data.term_width - 1 - @indent], \
                                  @alingment)
            # if one word uver multiple lones
            else
               @lines.first.text += words[0][..Data.term_width - 1 - @indent] 
            end

            words[0] = words[0][Data.term_width..]
         end

         # call again with rest of words
         @curr_width = @indent
         @lines << Line.new(" " * @indent, @alingment)

         append words.join(" ")
      end

      @skip_space = false

      # for when multipe pages will be used
      return ""
   end

   # sneakely insert text (escape sequence) #
   # to line without any other consequences #
   def insert(text : String)
      @lines.last.text += text
   end
end
