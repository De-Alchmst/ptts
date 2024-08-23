module Data
   class_property term_width, term_height, plaintext, file_line_count,
      filename, color_mode, prev_colors, indent_level, indent_level_length,
      indent_extra, output_mode, scroll, is_bold, is_italic, is_underlined,
      is_blink, search_list, search_index, vars, instructions, hardnl,
      number_lines, line_number, num_width, starts_with, current_lines,
      footnote_symbols, current_footnotes, footnote_size, wrap, wrap_now,
      last_alignment, prev_hardnl, strip, escape_regex, escape_regex_end,
      active_colors, export_name, meta,
      export_darkmode, export_margin, export_last_fg, export_last_bg,
      r_font_name, b_font_name, i_font_name, bi_font_name, font_name,
      file_path, current_lines_mode, manual_mode, meta_footnotes,
      manual_footnotes, normal_footnotes, labels, meta_front, meta_end,
      index_front, index_end, max_width, actual_width
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
   @@current_footnotes = {} of Int32 => Array(Footnote)
   @@normal_footnotes = {} of Int32 => Array(Footnote)
   @@meta_footnotes = {} of Int32 => Array(Footnote)
   @@manual_footnotes = {} of Int32 => Array(Footnote)
   @@wrap = false
   @@wrap_now = false
   @@last_alignment = Alingment::Left
   @@prev_hardnl = false
   @@strip = true
   @@escape_regex = Regex.new("\x1b\\[.*?m")
   @@escape_regex_end = Regex.new("\x1b\\[[^m]*?m$")
   @@export_name = ""
   @@export_darkmode = false
   @@export_margin = 12
   @@export_last_fg = "\\textcolor{fgdefault}{"
   @@export_last_bg = "\\colorbox{bgdefault}{"
   @@font_name = "Hack"
   @@file_path = ""
   @@current_lines_mode = :normal
   @@manual_mode = false
   @@labels = {} of String => Int32
   @@meta_front = false
   @@meta_end = false
   @@index_front = false
   @@index_end = false
   @@max_width = 0
   @@actual_width = 80
end

enum Alingment
   Left
   Center
   Right
end

class Footnote
   property text, height, type, link, mark
   def initialize(@mark : String, txt : String, @type = :footnote)
      # format footnote text
      @text = @mark
      indent = @mark.size + 1
      width = @mark.size
      @height = 1

      txt = "label : " + txt if @type == :label

      words = txt.split " "
      until words.empty?
         word = words.shift

         # split if too long
         if word.size > Data.term_width - indent
            words.unshift  word[Data.term_width - indent..]
            word = word[0..Data.term_width - indent - 1]
            indent = 0 if @type != :footnote
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
            indent = 0 if @type != :footnote
         end
      end
      @text += " " * (Data.term_width - width)
   end

   def link
      @text.sub(@mark+" ", "").gsub('\n', "").strip
   end

   def label
      @text.sub(@mark+" label : ", "").gsub('\n', " ").strip
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

def get_reset_line
   contents = "@"
   if Data.is_bold
      contents += "bb;"
   else
      contents += "eb;"
   end
   if Data.is_italic
      contents += "bi;"
   else
      contents += "ei;"
   end
   if Data.is_underlined
      contents += "bu;"
   else
      contents += "eu;"
   end
   if Data.is_blink
      contents += "bblink;"
   else
      contents += "eblink;"
   end
   if Data.hardnl
      contents += "hardnl;"
   else
      contents += "softnl;"
   end
   if Data.wrap
      unless Data.strip
         contents += "bart;"
      else
         contents += "wrap;"
      end
   else
      unless Data.strip
         contents += "nowrap;"
      else
         contents += "eart;"
      end
   end
   if Outcome.alingment == Alingment::Left
      contents += "lft;"
   elsif Outcome.alingment == Alingment::Center
      contents += "cnt;"
   else
      contents += "rght;"
   end

   contents += "fg;#{esc2color Data.prev_colors[:foreground]};"
   contents += (esc2color Data.active_colors[:foreground]) + ";"
   contents += "bg;#{esc2color Data.prev_colors[:background]};"
   contents += (esc2color Data.active_colors[:background]) + ";"
   if Data.color_mode == :foreground
      contents += "fg;"
   else
      contents += "bg;"
   end

   contents += "enum;" unless Data.number_lines

   if Data.starts_with.empty?
      contents += "startswithnothing;"
   else
      contents += "startswith{#{Data.starts_with}};"
   end

   contents += "setindl{#{Data.indent_level_length}};"
   contents += "rindl{#{Data.indent_level}};"
   contents += "rindn{#{Data.indent_extra}}"
   return contents
end

def esc2color(clr : String)
   if clr.includes? ";"
      clrs = clr.split ";"
      return "brgb{#{clrs[2]};#{clrs[3]};#{clrs[4]}}"
   else
      Colors.fg.each { |k, v|
         return "bcl{#{k}}" if clr == v
      }
      Colors.bg.each { |k, v|
         return "bcl{#{k}}" if clr == v
      }
   end
   ""
end
