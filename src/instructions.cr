require "./outcome.cr"
require "./data.cr"

def extra_space
   if Outcome.curr_width != Data.term_width && Outcome.curr_width > 0 \
         && !Outcome.skip_space && !Outcome.pages.last.lines.last.empty
      Outcome.append " ", strip=false
      Outcome.skip_space = true
   end
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
         -> {Outcome.insert("\x1b[1m") unless Data.plaintext},
         -> {Outcome.insert("\x1b[22m") unless Data.plaintext}
      ],

      "bb" => [
         -> {Outcome.insert("\x1b[1m") unless Data.plaintext},
         -> {}
      ],

      "eb" => [
         -> {Outcome.insert("\x1b[22m") unless Data.plaintext},
         -> {}
      ],

      "i" => [
         -> {Outcome.insert("\x1b[3m") unless Data.plaintext},
         -> {Outcome.insert("\x1b[23m") unless Data.plaintext}
      ],

      "bi" => [
         -> {Outcome.insert("\x1b[3m") unless Data.plaintext},
         -> {}
      ],

      "ei" => [
         -> {Outcome.insert("\x1b[23m") unless Data.plaintext},
         -> {}
      ],

      "u" => [
         -> {
            return if Data.plaintext

            extra_space
            Outcome.insert("\x1b[4m")
         },
         -> {Outcome.insert("\x1b[24m") unless Data.plaintext}
      ],

      "bu" => [
         -> {
            return if Data.plaintext

            extra_space
            Outcome.insert("\x1b[4m")
         },
         -> {}
      ],

      "eu" => [
         -> {Outcome.insert("\x1b[24m") unless Data.plaintext},
         -> {}
      ],

      "blink" => [
         -> {Outcome.insert("\x1b[5m") unless Data.plaintext},
         -> {Outcome.insert("\x1b[25m") unless Data.plaintext}
      ],

      "bblink" => [
         -> {Outcome.insert("\x1b[5m") unless Data.plaintext},
         -> {}
      ],

      "eblink" => [
         -> {Outcome.insert("\x1b[25m") unless Data.plaintext},
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

   }

   @@with_arg = {
      "cl" => [
         ->(arg : String) {
            return if Data.plaintext

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

            extra_space
            Outcome.insert "\x1b[#{c}m"
         },
         ->(arg : String) {
            return if Data.plaintext
            Outcome.insert "\x1b[#{Data.prev_colors[Data.color_mode]}m"
         }
      ],

      "bcl" => [
         ->(arg : String) {
            return if Data.plaintext

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

            extra_space
            Outcome.insert "\x1b[#{c}m"
            Data.prev_colors[Data.color_mode] = c
            nil
         },
         ->(arg : String) { }
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

            Outcome.reset_indent
            nil
         },
         ->(arg : String) { }
      ],

      "bindl" => [
         ->(arg : String) {
            val = arg.match /^\-?\d+$/

            unless val
               abort "not a whole positive number #{arg} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            Data.indent_level += arg.to_i
            Data.indent_level = 0 if Data.indent_level < 0

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
         ->(arg : String) { }
      ],

      "indl" => [
         ->(arg : String) {
            val = arg.match /^\-?\d+$/

            unless val
               abort "not a whole positive number #{arg} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            delta = arg.to_i

            Data.indent_level += delta
            Data.indent_level = 0 if Data.indent_level < 0

            Outcome.indent = Data.indent_level * Data.indent_level_length \
                           + Data.indent_extra

            Outcome.indent = 0 if Outcome.indent < 0

            if Outcome.indent >= Data.term_width
               abort "indent too large: #{val} " \
                   + "in file: #{Data.filename} at line #{Data.file_line_count}"
            end

            Outcome.new_block

            Data.indent_level -= delta
            Outcome.indent = Data.indent_level * Data.indent_level_length \
                           + Data.indent_extra
            nil
         },
         ->(arg : String) { }
      ],

   }
end
