enum Alingment
   Left
   Center
   Right
end

class Line
   property text, alingment
   def initialize(@text : String, @alingment : Alingment)
   end
end

class Page
   def initialize(@alingment : Alingment)
      @lines = [Line.new("", @alingment)]
   end

   def alingment
      @alingment
   end
   def alingment=(@alingment : Alingment)
      @lines.last.alingment = @alingment
   end

   # insert text to line like normal
   def append(text : String)
   end

   # sneakely insert text (escape sequence)
   # to line without any other consequences
   def insert(text : String)
   end
end
