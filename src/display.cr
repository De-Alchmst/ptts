require "./data.cr"
require "./outcome.cr"

def display()
   Outcome.pages.each { |page|
      page.lines.each { |line|
         puts line.text
      }
   }
end
