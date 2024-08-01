#! /usr/bin/ruby

out = %{
module FontData
  class_property data
  @@data : Slice(UInt8) = UInt8.slice(}

File.open(ARGV[0], "rb") do |file|
  # Read the file byte by byte
  file.each_byte do |byte|
    # Process each byte (for demonstration, we'll just print it)
    out += "#{byte},"
  end
end

out += ")\nend"


File.open("font_data.cr", "w") do |file|
  file.write(out)
end
