module Data
   class_property term_width, term_height, plaintext, file_line_count,
      filename, color_mode, prev_colors, indent_level, indent_level_length,
      indent_extra, output_mode, scroll, is_bold, is_italic, is_underlined,
      is_blink, search_list, search_index, vars, instructions, hardnl,
      number_lines, line_number, num_width, starts_with, meta, current_lines,
      footnote_symbols, footnotes, footnote_size, wrap, wrap_now,
      last_alignment, prev_hardnl, strip, escape_regex, escape_regex_end,
      concat_metadata, pdf_name, font_height, pdf_v_margin, pdf_h_margin,
      font_gap, pdf_width, pdf_height, pdf_darkmode, pdf_default_color,
      pdf_prev_color, active_colors, curr_font
   @@term_width : Int32 = 80 # `tput cols`.to_i (not when to pdf)
   @@term_height : Int32 = 24 #`tput lines`.to_i
   @@plaintext = false
   @@file_line_count = 0
   @@filename = ""
   @@color_mode = :foreground
   @@prev_colors = {:foreground => "39", :background => "49"}
   @@active_colors = {:foreground => "39", :background => "49"}
   @@indent_level = 0
   @@indent_level_length = 1
   @@indent_extra = 0 # extralevel independent indent
   @@output_mode = :tui
   @@scroll = 0
   @@is_bold = false
   @@is_italic = false
   @@is_underlined = false
   @@is_blink = false
   @@search_list = Array(SearchItem).new
   @@search_index = 0
   @@vars = {} of String => String
   @@instructions = [] of Array(String)
   @@hardnl = false
   @@number_lines = false
   @@line_number = 1
   @@num_width = 3
   @@starts_with = ""
   @@meta = {} of String => String
   @@current_lines = [] of String
   @@footnote_symbols = ["*"]
   @@footnote_size = 0
   @@footnotes = {} of Int32 => Array(Footnote)
   @@wrap = false
   @@wrap_now = false
   @@last_alignment = Alingment::Left
   @@prev_hardnl = false
   @@strip = true
   @@escape_regex = Regex.new("\x1b\\[.*?m")
   @@escape_regex_end = Regex.new("\x1b\\[[^m]*?m$")
   @@concat_metadata = false
   @@pdf_name = "out.pdf"
   @@font_height = 12
   @@font_gap = 3
   @@pdf_v_margin = 20
   @@pdf_h_margin = 10
   @@pdf_width = 612
   @@pdf_height = 792
   @@pdf_darkmode = false
   @@pdf_default_color = "0 0 0 rg\n"
   @@pdf_prev_color = ""
   @@curr_font = "/F1"
end

enum Alingment
   Left
   Center
   Right
end

class Footnote
   property text, height
   def initialize(mark : String, txt : String)
      # format footnote text
      @text = mark
      indent = mark.size + 1
      width = mark.size
      @height = 1

      words = txt.split " "
      until words.empty?
         word = words.shift

         # split if too long
         if word.size > Data.term_width - indent
            words.unshift  word[Data.term_width - indent..]
            word = word[0..Data.term_width - indent - 1]
         end

         # fits on line
         if word.size + width < Data.term_width
            @text += " " + word
            width += word.size + 1
            # does not fit no line
         else
            @text += " " * (Data.term_width - width) \
               + "\n" + " " * (indent) + word
            @height += 1
            width = word.size + indent
         end
      end
      @text += " " * (Data.term_width - width)
   end
end

def reset_data
   Data.color_mode = :foreground
   Data.active_colors = {:foreground => "39", :background => "49"}
   Data.indent_level = 0
   Data.indent_level_length = 1
   Data.indent_extra = 0 # extralevel independent indent
   Data.is_bold = false
   Data.is_italic = false
   Data.is_underlined = false
   Data.is_blink = false
   Data.hardnl = false
   Data.number_lines = false
   Data.starts_with = ""
end

class SearchItem
   property position, match_start, match_end

   def initialize(@position : Int32, @match_start : Int32, @match_end : Int32)
   end
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
