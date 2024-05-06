require "./data.cr"
require "./pages.cr"

def process_file(filename : String)
   #################
   # READ THE FILE #
   #################

   abort "file not found: #{filename}" unless File.exists? filename
   abort "file not readable: #{filename}" unless File.readable? filename

   lines = File.read(filename).split /\n/

   ##############
   # GO THROUGH #
   ##############

   lines.size.times { |i|
      line = lines[i]
      Data.file_line_count = i + 1


   }
end
