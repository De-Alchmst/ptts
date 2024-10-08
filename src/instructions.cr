require "./outcome.cr"
require "./data.cr"
require "./inst_parse.cr"

def extra_space
   if Outcome.curr_width != Data.term_width && Outcome.curr_width > 0 \
         && !Outcome.skip_space && !Outcome.pages.last.lines.last.empty
      Outcome.append " ", strip=false
      Outcome.skip_space = true
   end
end

def set_indent_level(arg : String, reset : Bool)
   val = arg.match /^\-?\d+$/

   unless val
      abort "not a whole number #{arg} " \
         + "in file: #{Data.filename} at line #{Data.file_line_count}"
   end

   if reset
      Data.indent_level = arg.to_i
   else
      Data.indent_level += arg.to_i
   end
   Data.indent_level = 0 if Data.indent_level < 0

   Outcome.indent = Data.indent_level * Data.indent_level_length \
      + Data.indent_extra

   Outcome.indent = 0 if Outcome.indent < 0

   if Outcome.indent >= Data.term_width
      abort "indent too large: #{val} " \
         + "in file: #{Data.filename} at line #{Data.file_line_count}"
   end
end

def set_indent_extra(arg : String, reset : Bool)
   val = arg.match /^\-?\d+$/

   unless val
      abort "not a whole number #{arg} " \
         + "in file: #{Data.filename} at line #{Data.file_line_count}"
   end

   if reset
      Data.indent_extra = arg.to_i
   else
      Data.indent_extra += arg.to_i
   end

   Outcome.indent = Data.indent_level * Data.indent_level_length \
      + Data.indent_extra

   Outcome.indent = 0 if Outcome.indent < 0

   if Outcome.indent >= Data.term_width
      abort "indent too large: #{val} " \
         + "in file: #{Data.filename} at line #{Data.file_line_count}"
   end
end

def get_color(arg : String)
   c = ""
   if Data.color_mode == :foreground
      c = Colors.fg[arg] if Colors.fg.has_key? arg
   else
      c = Colors.bg[arg] if Colors.bg.has_key? arg
   end

   if c.empty?
      abort "unknown color: #{arg} in file: #{Data.filename} " \
         + "at line #{Data.file_line_count}"
   end

   return c
end

def validate_rgb(arg : String)
   colors = arg.split ";"

   if colors.size != 3
      abort "needs three ';' separated arguments, but '#{arg}' given "\
         + "in file: #{Data.filename} at line #{Data.file_line_count}"
   end

   colors.each {|c|
      unless c.match(/^\d+$/) && c.to_i <= 255
         abort "needs positive number under 256, but '#{c}' given " \
            + "in file: #{Data.filename} at line #{Data.file_line_count}"
      end
   }
end

def hex2rgb(arg : String)
   unless arg.match /^[0-9a-fA-f]{6}$/
      abort "needs 6 hex digits, but '#{arg}' given " \
         + "in file: #{Data.filename} at line #{Data.file_line_count}"
   end

   return "#{arg[0..1].to_i 16};#{arg[2..3].to_i 16};#{arg[4..5].to_i 16}"
end

module Insts
   class_property no_arg, with_arg

   @@no_arg : Hash(String, Array(Proc(Nil)))
   @@with_arg : Hash(String, Array(Proc(String, Nil)))

   @@no_arg = {
      "@" => [                    # name
         -> {Outcome.append "@"}, # beginning of line
         -> {}                    # end of line
      ],

      "b" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[1m")
            Data.is_bold = true; nil
         },
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[22m")
            Data.is_bold = false; nil
         }
      ],

      "bb" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[1m")
            Data.is_bold = true; nil
         },
         -> {}
      ],

      "eb" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[22m")
            Data.is_bold = false; nil
         },
         -> {}
      ],

      "i" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[3m")
            Data.is_italic = true; nil
         },
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[23m")
            Data.is_italic = false; nil
         }
      ],

      "bi" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[3m")
            Data.is_italic = true; nil
         },
         -> {}
      ],

      "ei" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[23m")
            Data.is_italic = false; nil
         },
         -> {}
      ],

      "u" => [
         -> {
            return if Data.plaintext

            extra_space
            Outcome.insert("\x1b[4m")
            Data.is_underlined = true; nil
            
         },
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[24m")
            Data.is_underlined = false; nil
         }
      ],

      "bu" => [
         -> {
            return if Data.plaintext

            extra_space
            Outcome.insert("\x1b[4m")
            Data.is_underlined = true; nil
         },
         -> {}
      ],

      "eu" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[24m")
            Data.is_underlined = false; nil
         },
         -> {}
      ],

      "blink" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[5m")
            Data.is_blink = true; nil
         },
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[25m")
            Data.is_blink = false; nil
         }
      ],

      "bblink" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[5m")
            Data.is_blink = true; nil
         },
         -> {}
      ],

      "eblink" => [
         -> {
            return if Data.plaintext
            Outcome.insert("\x1b[25m")
            Data.is_blink = false; nil
         },
         -> {}
      ],

      "fg" => [
         -> {Data.color_mode = :foreground; nil},
         -> {}
      ],

      "bg" => [
         -> {Data.color_mode = :background; nil},
         -> {}
      ],

      "hardnl" => [
         -> {
            Data.hardnl = true
            Data.prev_hardnl = true
            Outcome.new_block
            nil
         },
         -> {}
      ],

      "softnl" => [
         -> {
            Data.hardnl = false
            Data.prev_hardnl = false
            Outcome.new_block
            nil
         },
         -> {}
      ],

      "bnum" => [
         -> {
            Data.line_number = 1
            Data.number_lines = true
            Outcome.new_block
         },
         -> {}
      ],

      "enum" => [
         -> {
            Data.number_lines = false
            Outcome.new_block
         },
         -> {}
      ],

      "line" => [
         -> {
            Outcome.append ""
            Outcome.append "-" # just add something to toggle @empty
            Outcome.pages.last.lines.last.number = ""
            Outcome.pages.last.lines.last.starts_with = ""
            Outcome.pages.last.lines.last.leading_whitespace = ""
            Outcome.pages.last.lines.last.text = "-" * Data.term_width
            Outcome.pages.last.lines.last.has_num = false
            Data.line_number -= 1
            Outcome.new_block
         },
         -> {}
      ],

      "startswithnothing" => [
         -> {
            Data.starts_with = ""
            Outcome.new_block
            nil
         },
         -> {}
      ],

      "pgbr" => [
         -> {Outcome.new_page; nil},
         -> {}
      ],

      "pgeven" => [
         -> {Outcome.new_page :even; nil},
         -> {}
      ],

      "pgodd" => [
         -> {Outcome.new_page :odd; nil},
         -> {}
      ],

      "wrap" => [
         -> {Data.wrap = true; nil},
         -> {}
      ],

      "nowrap" => [
         -> {Data.wrap = false; nil},
         -> {}
      ],

      "lft" => [
         -> {Outcome.alingment = Alingment::Left; nil},
         -> {}
      ],

      "cnt" => [
         -> {Outcome.alingment = Alingment::Center; nil},
         -> {}
      ],

      "rght" => [
         -> {Outcome.alingment = Alingment::Right; nil},
         -> {}
      ],

      "lftln" => [
         -> {
            Data.last_alignment = Outcome.alingment
            Outcome.alingment = Alingment::Left
            nil
         },
         -> {
            Outcome.alingment = Data.last_alignment
            nil
         }
      ],

      "cntln" => [
         -> {
            Data.last_alignment = Outcome.alingment
            Outcome.alingment = Alingment::Center
            nil
         },
         -> {
            Outcome.alingment = Data.last_alignment
            nil
         }
      ],

      "rghtln" => [
         -> {
            Data.last_alignment = Outcome.alingment
            Outcome.alingment = Alingment::Right
            nil
         },
         -> {
            Outcome.alingment = Data.last_alignment
            nil
         }
      ],

      "bart" => [
         -> {
            Data.strip = false;
            Data.hardnl = true
            Outcome.new_block
            nil
         },
         -> {}
      ],

      "eart" => [
         -> {
            Data.strip = true;
            Data.hardnl = Data.prev_hardnl
            Outcome.new_block
            nil
         },
         -> {}
      ],

      "ss" => [
         -> {
            Outcome.skip_space = true
            nil
         },
         -> {}
      ],
   }

   @@with_arg = {
      "cl" => [
         ->(arg : String) {
            return if Data.plaintext
            c = get_color arg

            extra_space
            Outcome.insert "\x1b[#{c}m"
            Data.prev_colors[Data.color_mode] = \
                             Data.active_colors[Data.color_mode]
            Data.active_colors[Data.color_mode] = c
            nil
         },
         ->(arg : String) {
            return if Data.plaintext
            Data.active_colors[Data.color_mode] = \
                               Data.prev_colors[Data.color_mode]
            Outcome.insert "\x1b[#{Data.active_colors[Data.color_mode]}m"
         }
      ],

      "rgb" => [
         ->(arg : String) {
            return if Data.plaintext
            validate_rgb arg

            extra_space
            if Data.color_mode == :foreground
               Outcome.insert "\x1b[38;2;#{arg}m"
               Data.prev_colors[:foreground] = Data.active_colors[:foreground]
               Data.active_colors[:foreground] = "38;2;#{arg}"
            else
               Outcome.insert "\x1b[48;2;#{arg}m"
               Data.prev_colors[:background] = Data.active_colors[:foreground]
               Data.active_colors[:background] = "48;2;#{arg}"
            end
            nil
         },
         ->(arg : String) {
            return if Data.plaintext
            Data.active_colors[Data.color_mode] = \
                               Data.prev_colors[Data.color_mode]
            Outcome.insert "\x1b[#{Data.active_colors[Data.color_mode]}m"
         }
      ],

      "hex" => [
         ->(arg : String) {
            return if Data.plaintext
            c = hex2rgb arg    

            extra_space
            if Data.color_mode == :foreground
               Outcome.insert "\x1b[38;2;#{c}m"
               Data.prev_colors[:foreground] = Data.active_colors[:foreground]
               Data.active_colors[:foreground] = "38;2;#{c}"
            else
               Outcome.insert "\x1b[48;2;#{c}m"
               Data.prev_colors[:background] = Data.active_colors[:foreground]
               Data.active_colors[:background] = "48;2;#{c}"
            end
            nil

         },
         ->(arg : String) {
            return if Data.plaintext
            Data.active_colors[Data.color_mode] = \
                               Data.prev_colors[Data.color_mode]
            Outcome.insert "\x1b[#{Data.active_colors[Data.color_mode]}m"
         }
      ],

      "bcl" => [
         ->(arg : String) {
            return if Data.plaintext

            c = get_color arg

            extra_space
            Outcome.insert "\x1b[#{c}m"
            Data.active_colors[Data.color_mode] = c
            nil
         },
         ->(arg : String) {}
      ],

      "brgb" => [
         ->(arg : String) {
            return if Data.plaintext
            validate_rgb arg

            extra_space
            if Data.color_mode == :foreground
               Outcome.insert "\x1b[38;2;#{arg}m"
               Data.active_colors[:foreground] = "38;2;#{arg}"
            else
               Outcome.insert "\x1b[48;2;#{arg}m"
               Data.active_colors[:background] = "48;2;#{arg}"
            end
            nil
         },
         ->(arg : String) {}
      ],

      "bhex" => [
         ->(arg : String) {
            return if Data.plaintext
            c = hex2rgb arg

            extra_space
            if Data.color_mode == :foreground
               Outcome.insert "\x1b[38;2;#{c}m"
               Data.active_colors[:foreground] = "38;2;#{c}"
            else
               Outcome.insert "\x1b[48;2;#{c}m"
               Data.active_colors[:background] = "48;2;#{c}"
            end
            nil
         },
         ->(arg : String) {}
      ],

      "setindl" => [
         ->(arg : String) {
            val = arg.match /^\d+$/

            unless val
               abort "not a whole positive number #{arg} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            Data.indent_level_length = arg.to_i

            Outcome.indent = Data.indent_level * Data.indent_level_length \
                           + Data.indent_extra

            Outcome.indent = 0 if Outcome.indent < 0

            if Outcome.indent >= Data.term_width
               abort "indent too large: #{val} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            Outcome.new_block
            nil
         },
         ->(arg : String) {}
      ],

      "bindl" => [
         ->(arg : String) {
            set_indent_level arg, false

            Outcome.new_block
            nil
         },
         ->(arg : String) {}
      ],

      "rindl" => [
         ->(arg : String) {
            set_indent_level arg, true

            Outcome.new_block
            nil
         },
         ->(arg : String) {}
      ],

      "softbindl" => [
         ->(arg : String) {
            set_indent_level arg, false
            nil
         },
         ->(arg : String) {}
      ],

      "indl" => [
         ->(arg : String) {
            prev_level = Data.indent_level

            set_indent_level arg, false

            Outcome.new_block

            Data.indent_level = prev_level
            Outcome.indent = Data.indent_level * Data.indent_level_length \
                           + Data.indent_extra
            nil
         },
         ->(arg : String) {}
      ],

      "bindn" => [
         ->(arg : String) {
            set_indent_extra arg, false

            Outcome.new_block
            nil
         },
         ->(arg : String) {}
      ],

      "rindn" => [
         ->(arg : String) {
            set_indent_extra arg, true

            Outcome.new_block
            nil
         },
         ->(arg : String) {}
      ],

      "softbindn" => [
         ->(arg : String) {
            set_indent_extra arg, false
            nil
         },
         ->(arg : String) {}
      ],

      "indn" => [
         ->(arg : String) {
            prev_extra = Data.indent_extra

            set_indent_extra arg, false

            Outcome.new_block

            Data.indent_extra = prev_extra
            Outcome.indent = Data.indent_level * Data.indent_level_length \
                           + Data.indent_extra
            nil
         },
         ->(arg : String) {}
      ],

      "set" => [
         ->(arg : String) {
            val = arg.partition ";"

            if val.size != 3
               abort "needs two ';' separated arguments, but '#{arg}' given " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            Data.vars[val[0]] = val[2]
            nil
         },
         ->(arg : String) {}
      ],

      "val" => [
         ->(arg : String) {
            unless Data.vars.has_key? arg
               abort "unset variable #{arg} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            Outcome.append Data.vars[arg]
         },
         ->(arg : String) {}
      ],

      "aval" => [
         ->(arg : String) {
         },
         ->(arg : String) {
            unless Data.vars.has_key? arg
               abort "unset variable #{arg} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            Outcome.append Data.vars[arg]
         }
      ],

      "x" => [
         ->(arg : String) {
            unless Data.vars.has_key? arg
               abort "unset variable #{arg} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            parse_insts "@#{Data.vars[arg]} "
            nil
         },
         ->(arg : String) {}
      ],

      "vtab" => [
         ->(arg : String) {
            val = arg.match /^\d+$/

            unless val
               abort "not a whole positive number #{arg} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            num = arg.to_i
            # num += 1 unless Outcome.pages.last.lines.last.empty

            Outcome.new_block

            num.times {
               Outcome.pages.last.lines.insert \
                  Outcome.pages.last.lines.size-1, \
                  Line.new("", 0, Outcome.alingment)
            }
         },
         ->(arg : String) {}
      ],

      "tab" => [
         ->(arg : String) {
            val = arg.match /^\d+$/

            unless val
               abort "not a whole positive number #{arg} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            num = arg.to_i
            if Outcome.pages.last.curr_width + num <= Data.term_width
               Outcome.pages.last.lines.last.text += " " * num
               Outcome.pages.last.curr_width += num
            else
               Outcome.new_block
            end
            nil
         },
         ->(arg : String) {}
      ],

      "startswith" => [
         ->(arg : String) {
            Data.starts_with = arg
            if Outcome.pages.last.default_width >= Data.term_width
               abort "starting width is too large " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end
            Outcome.new_block
         },
         ->(arg : String) {}
      ],

      "meta" => [
         ->(arg : String) {
            val = arg.split ";"

            val.each { |v|
               data = v.split ":"
               if data.size != 2
                  abort "needs two ':' separated arguments, but '#{arg}' given " \
                      + "in file: #{Data.filename} at line #{Data.file_line_count}"
               end

               Data.meta[data[0]] = data[1]
            }
         },
         ->(arg : String) {}
      ],

      "setfootnote" => [
         ->(arg : String) {
            Data.footnote_symbols = arg.split ";"
            Outcome.reset_footnote_count
            nil
         },
         ->(arg : String) {}
      ],

      "footnote" => [
         ->(arg : String) {},
         ->(arg : String) {
            Outcome.add_footnote arg
            nil
         }
      ],

      "link" => [
         ->(arg : String) {},
         ->(arg : String) {
            Outcome.add_footnote arg, :link
            nil
         }
      ],

      "img" => [
         ->(arg : String) {
            parts = arg.split ";"
            unless parts.size == 2
               abort "needs two ';' separated arguments, but '#{arg}' given " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            unless Data.output_mode == :pdf || Data.output_mode == :latex
               Outcome.new_block
               Outcome.append parts[1]
            end

            Outcome.add_footnote parts[0], :img

            unless Data.output_mode == :pdf || Data.output_mode == :latex
               Outcome.new_block
            end
         },
         ->(arg : String) {}
      ],

      "label" => [
         ->(arg : String) {},
         ->(arg : String) {
            Outcome.add_label arg
            nil
         }
      ],

      "reflabel" => [
         ->(arg : String) {},
         ->(arg : String) {
            Outcome.add_footnote arg, :label
            nil
         }
      ],

      "source" => [ # handled in file_handle
         ->(arg : String) {},
         ->(arg : String) {}
      ],

      "sourceclear" => [ # handled in file_handle
         ->(arg : String) {},
         ->(arg : String) {}
      ],
   }
end
