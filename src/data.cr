module Data
   class_property term_width, term_height, plaintext, file_line_count, filename
   @@term_width : Int32 = `tput cols`.to_i
   @@term_height : Int32 = `tput lines`.to_i
   @@plaintext = false
   @@file_line_count = 0
end

module Colors
   class_property fg, bg
   @@fg = {
      "black"   => "30",
      "red"     => "31",
      "green"   => "32",
      "yellow"  => "33",
      "blue"    => "34",
      "magenta" => "35",
      "cyan"    => "36",
      "white"   => "37",

      "bright-black"   => "90",
      "bright-red"     => "91",
      "bright-green"   => "92",
      "bright-yellow"  => "93",
      "bright-blue"    => "94",
      "bright-magenta" => "95",
      "bright-cyan"    => "96",
      "bright-white"   => "97",

      "default" => "39",
   }

   @@bg = {
      "black"   => "40",
      "red"     => "41",
      "green"   => "42",
      "yellow"  => "43",
      "blue"    => "44",
      "magenta" => "45",
      "cyan"    => "46",
      "white"   => "47",

      "bright-black"   => "100",
      "bright-red"     => "101",
      "bright-green"   => "102",
      "bright-yellow"  => "103",
      "bright-blue"    => "104",
      "bright-magenta" => "105",
      "bright-cyan"    => "106",
      "bright-white"   => "107",

      "default" => "49",
   }
end
