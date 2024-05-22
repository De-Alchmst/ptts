#!/usr/bin/ruby

require "io/console"

#############
# VARIABLES #
#############

filename = nil
$plaintext = false

$term_height, $term_width = IO.console.winsize
$file_line_count = 0

$outcome_lines = [""]
$outcome_line_count = 0

$alignment = :left
$current_width = 0
$skip_space = false

$color_mode = :foreground

$prev_colors = {
  :foreground => 39,
  :background => 49,
}

$indent_level = 0
$indent_level_length = 0
$indent_extra = 0
$indent = 0

$prev_indent_level = 0
$prev_indent_extra = 0

############
# ADD TEXT #
############
def text_append(txt)

  # handle empty lines
  if ["\n", "\n\r", "\r\n", "\r"].include? txt
    $outcome_lines << " " * $indent
    $outcome_line_count += 1
    $current_width = $indent
    return
  end

  # handle whitespace soroundings
  txt = txt.strip
  return if txt.length == 0
  unless $outcome_lines.last.match(/\w/) \
      or $current_width == $indent or $skip_space
    txt = " " + txt 
  end

  # insert #
  case $alignment
  when :left
    # if it fits
    if $current_width + txt.length <= $term_width
      $outcome_lines[$outcome_line_count] += txt
      $current_width += txt.length

    # if it doesn't
    else
      # get words
      words = txt.split ' '

      # add them as long as they fit
      while words[0].length + $current_width < $term_width
        # add space if not line beginnign
        w = words.shift
        w[0] = " " + w[0] unless $current_width == 0 or $skip_space
        $skip_space = false if $skip_space

        $outcome_lines[$outcome_line_count] += w
        $current_width += w.length

        break if words.length == 0
      end

      # if word too long
      if words[0].length >= $term_width
        # if something on line
        if $outcome_lines[$outcome_line_count].strip != ""
          $outcome_lines << " "*$indent + words[0][..$term_width-1-$indent]
          $outcome_line_count += 1

        # if single word split over multiple lines
        else
          $outcome_lines[$outcome_line_count]=words[0][..$term_width-1-$indent]
        end

        words[0] = words[0][$term_width..]
      end

      # call again with the rest
      $current_width = $indent
      $outcome_line_count += 1
      $outcome_lines << " " * $indent

      text_append words.join(' ')
    end
  when :center
  when :right
  end

  $skip_space = false if $skip_space
end

################
# HELPER stuff #
################

COLORS = {
  :foreground => {
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
  },

  :background => {
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
}

def new_block()
  if $outcome_lines.last.match /\w/
    $outcome_lines << " " * $indent
    $current_width = $indent
    $outcome_line_count += 1
  else
    $outcome_lines[$outcome_line_count] = \
      $outcome_lines[$outcome_line_count].strip + " " * $indent
  end
end

################
# INSTRUCTIONS #
################

insts_no_arg = {
  "@" => [                  # name
    lambda {add_text "@"},  # beginning of line
    lambda {},              # end of line
  ],

  "b" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[1m" unless $plaintext},
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[22m" unless $plaintext},
  ],

  "bb" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[1m" unless $plaintext},
    lambda {},
  ],

  "eb" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[22m" unless $plaintext},
    lambda {},
  ],

  "i" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[3m" unless $plaintext},
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[23m" unless $plaintext},
  ],

  "bi" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[3m" unless $plaintext},
    lambda {},
  ],

  "ei" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[23m" unless $plaintext},
    lambda {},
  ],

  "u" => [
    lambda {
      return if $plaintext
      if $current_width != $term_width
        $outcome_lines[$outcome_line_count] += " " # to not underline this space
        $skip_space = true
      end
      $outcome_lines[$outcome_line_count] += "\x1b[4m"
    },
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[24m" unless $plaintext},
  ],

  "bu" => [
    lambda {
      return if $plaintext

      if $current_width != $term_width
        $outcome_lines[$outcome_line_count] += " " # to not underline this space
        $skip_space = true
      end
      $outcome_lines[$outcome_line_count] += "\x1b[4m"
    },
    lambda {},
  ],

  "eu" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[24m" unless $plaintext},
    lambda {},
  ],

  "blink" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[5m" unless $plaintext},
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[25m" unless $plaintext},
  ],

  "bblink" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[5m" unless $plaintext},
    lambda {},
  ],

  "eblink" => [
    lambda {$outcome_lines[$outcome_line_count] += "\x1b[25m" unless $plaintext},
    lambda {},
  ],

  "fg" => [
    lambda { $color_mode = :foreground },
    lambda {},
  ],

  "bg" => [
    lambda { $color_mode = :background },
    lambda {},
  ],

}

insts_with_arg = {
  "cl" => [
    lambda { |arg|
      return if $plaintext

      c = COLORS[$color_mode][arg]
      unless c
        abort "unknown color: #{arg} in file: #{filename} " \
            + "at line #{$file_line_count}"
      end

      $outcome_lines[$outcome_line_count] += "\x1b[#{c}m"
    },
    lambda { |arg|
      return if $plaintext

      $outcome_lines[$outcome_line_count] \
      += "\x1b[#{$prev_colors[$color_mode]}m"
    },
  ],

  "bcl" => [
    lambda { |arg|
      return if $plaintext

      c = COLORS[$color_mode][arg]
      unless c
        abort "unknown color: #{arg} in file: #{filename} " \
            + "at line #{$file_line_count}"
      end

      $outcome_lines[$outcome_line_count] += "\x1b[#{c}m"

      $prev_colors[$color_mode] = c
   },
    lambda {|arg|},
  ],

  "setindl" => [
    lambda { |arg|
      val = arg.match /^\d+$/
      unless val 
        abort "not a whole positive number #{arg} " \
            + "in file: #{filename} at line #{$file_line_count}" \
      end

      $indent_level_length = val[0].to_i

      $indent = $indent_level * $indent_level_length + $indent_extra

      $indent = 0 if $indent < 0

      if $indent >= $term_width
        abort "indent too large: #{val} " \
            + "in file: #{filename} at line #{$file_line_count}"
      end
    },
    lambda {|arg|},
  ],

  "bindl" => [
    lambda { |arg|
      val = arg.match /^\-?\d+$/
      unless val 
        abort "not a whole number #{arg} " \
            + "in file: #{filename} at line #{$file_line_count}" \
      end

      $prev_indent_level += $indent_level

      $indent_level += val[0].to_i
      $indent_level = 0 if $indent_level < 0

      $indent = $indent_level * $indent_level_length + $indent_extra
      $indent = 0 if $indent < 0
      
      if $indent >= $term_width
        abort "indent too large: #{val} " \
            + "in file: #{filename} at line #{$file_line_count}"
      end

      new_block
    },
    lambda {|arg|},
  ],

  "indl" => [
    lambda { |arg|
      val = arg.match /^\-?\d+$/
      unless val 
        abort "not a whole number #{arg} " \
            + "in file: #{filename} at line #{$file_line_count}" \
      end

      $prev_indent_level = $indent_level

      $indent_level += val[0].to_i
      $indent_level = 0 if $indent_level < 0

      $indent = $indent_level * $indent_level_length + $indent_extra
      $indent = 0 if $indent < 0
      
      if $indent >= $term_width
        abort "indent too large: #{val} " \
            + "in file: #{filename} at line #{$file_line_count}"
      end

      new_block

    },
    lambda { |arg|
      $indent_level = $prev_indent_level

      $indent = $indent_level * $indent_level_length + $indent_extra
      $indent = 0 if $indent < 0
    },
  ],

}

###############
# HANDLE ARGS #
###############

def help
  abort "usage: ptts [flags] <filename>\n" \
      + "flags: \n" \
      + "       -h, --help        prints this help message\n" \
      + "       -p, --plaintext   do not add escape sequences\n" \
      + "       -w, --width <num> sets output width\n" \

end

while arg = ARGV.shift do
  if arg.start_with?("--")
    case arg[2..]
    when "help"
      help
    when "plaintext"
      $plaintext = true

    when "width"
      abort "missing argument for --width" if ARGV.length == 0

      $term_width = ARGV.shift.to_i
        abort "width must be positive numeric vlue" if $term_width < 1

    else
      puts "unknown flag: #{arg}"
      help
    end

  elsif arg.start_with?("-")
    arg[1..].chars.each { |flag|
      case flag
      when 'h'
        help
      when "p"
        $plaintext = true

      when "w"
        abort "missing argument for --width" if ARGV.length == 0

        $term_width = ARGV.shift.to_i
        abort "width must be positive numeric vlue" if $term_width < 1

      else
        puts "unknown flag: -#{flag}"
        help
      end
    }

  else
    if filename
      puts "unknown argument: #{arg}"
      help
    end

    filename = arg
  end
end

help unless filename

#############
# READ FILE #
#############

abort "file not found" unless File.exist? filename
abort "file not readable" unless File.readable? filename

f = File.open filename
lines = f.readlines
f.close

####################
# PROCESS CONTENTS #
####################

# go through lines #
for $file_line_count in 1..lines.length
  begin # to handle comments

    line = lines[$file_line_count-1]
    # no instruction
    unless line.start_with? "@" and line.length > 1
      text_append line

    # some instruction
    else
      # split into instructions, arguments and text body #
      instructions = []
      txt = ""
      enclose_level = 0
      prev = 0

      for i in 2..line.length-1
        case line[i]
        when "{"
          enclose_level += 1
        when "}"
          enclose_level -= 1
        when ";"
          if enclose_level == 0
            inst = line[prev+1..i-1] # get entire instruction

            arg = inst.match(/\{(.*)\}/) # get argument part
            arg = arg[1] if arg # specify only capture if found
            
            instructions << [inst.sub(/\{.*/, ""), arg] # pair together

            prev = i
          end
        when /\s/
          if enclose_level == 0
            inst = line[prev+1..i-1]

            arg = inst.match(/\{(.*)\}/)
            arg = arg[1] if arg
            
            instructions << [inst.sub(/\{.*/, ""), arg.strip]

            txt = line[i+1..]
            break
          end
        end
      end

      # call beginning of instructions #
      instructions.each { |inst|
        next line_loop if inst[0] == "cmnt"

        # handle innitial instruction calls and checks

        # insts without arguments
        if !insts_no_arg[inst[0]].nil?
          # check
          unless inst[1].nil?
            abort "extra argument given to: #{inst[0]} in file: #{filename} " \
                + "at line #{$file_line_count}"
          end

          # call
          insts_no_arg[inst[0]][0].call

        # insts with arguments
        elsif !insts_with_arg[inst[0]].nil?
          # check
          if inst[1].nil?
            abort "missing argument for: #{inst[0]} in file: #{filename} " \
                + "at line #{$file_line_count}"
          end
          
          # call
          insts_with_arg[inst[0]][0].call inst[1]

        else
          abort "unknown instruction: #{inst[0]} in file: #{filename} " \
              + "at line #{$file_line_count}"
        end
      }

      # add text
      text_append txt

      # call end of instructions #
      instructions.each { |inst|

        if inst[1].nil?
          insts_no_arg[inst[0]][1].call
        else
          insts_with_arg[inst[0]][1].call inst[1]
        end
      }

    end
  rescue
  end
end

# print outcome #
puts ""
puts $outcome_lines
print "\x1b[0m"
