#!/usr/bin/ruby

require "io/console"

#############
# VARIABLES #
#############

filename = nil
$plaintext = false

$term_height, $term_width = IO.console.winsize

$outcome_lines = [""]
$line_count = 0

$alignment = :left
$current_width = 0
$skip_space = false

############
# ADD TEXT #
############
def text_append(txt)

  # handle empty lines
  if ["\n", "\n\r", "\r"].include? txt
    $outcome_lines << ""
    $line_count += 1
    $current_width = 0
    return
  end

  # handle whitespace soroundings
  txt = txt.strip
  return if txt.length == 0
  txt = " " + txt unless $current_width == 0 or $skip_space
  $skip_space = false if $skip_space

  # insert #
  case $alignment
  when :left
    # if it fits
    if $current_width + txt.length <= $term_width
      $outcome_lines[$line_count] += txt
      $current_width += txt.length

    # if it doesn't
    else
      # get words
      words = txt.split ' '

      # add them as long as they fit
      while words[0].length + $current_width < $term_width
        $outcome_lines[$line_count] += " " + words.shift
        $current_width = $outcome_lines[$line_count].length

        break if words.length == 0
      end

      # if word too long
      if words[0].length > $term_width
        $outcome_lines << words[0][..$term_width-1]
        $line_count += 1

        words[0] = words[0][$term_width..]
      end

      # call again with the rest
      $current_width = 0
      $line_count += 1
      $outcome_lines << ""

      text_append words.join(' ')
    end
  when :center
  when :right
  end
end


################
# INSTRUCTIONS #
################

insts = {
  "@" => [                  # name
    lambda {add_text "@"},  # beginning of line
    lambda {},              # end of line
  ],

  "b" => [
    lambda {$outcome_lines[$line_count] += "\x1b[1m" unless $plaintext},
    lambda {$outcome_lines[$line_count] += "\x1b[22m" unless $plaintext},
  ],

  "bb" => [
    lambda {$outcome_lines[$line_count] += "\x1b[1m" unless $plaintext},
    lambda {},
  ],

  "eb" => [
    lambda {$outcome_lines[$line_count] += "\x1b[22m" unless $plaintext},
    lambda {},
  ],

  "i" => [
    lambda {$outcome_lines[$line_count] += "\x1b[3m" unless $plaintext},
    lambda {$outcome_lines[$line_count] += "\x1b[23m" unless $plaintext},
  ],

  "bi" => [
    lambda {$outcome_lines[$line_count] += "\x1b[3m" unless $plaintext},
    lambda {},
  ],

  "ei" => [
    lambda {$outcome_lines[$line_count] += "\x1b[23m" unless $plaintext},
    lambda {},
  ],

  "u" => [
    lambda {
      return if $plaintext
      if $current_width != $term_width
        $outcome_lines[$line_count] += " " # to not underline this space
        $skip_space = true
      end
      $outcome_lines[$line_count] += "\x1b[4m"
    },
    lambda {$outcome_lines[$line_count] += "\x1b[24m" unless $plaintext},
  ],

  "bu" => [
    lambda {
      return if $plaintext

      if $current_width != $term_width
        $outcome_lines[$line_count] += " " # to not underline this space
        $skip_space = true
      end
      $outcome_lines[$line_count] += "\x1b[4m"
    },
    lambda {},
  ],

  "eu" => [
    lambda {$outcome_lines[$line_count] += "\x1b[24m" unless $plaintext},
    lambda {},
  ],

  "blink" => [
    lambda {$outcome_lines[$line_count] += "\x1b[5m" unless $plaintext},
    lambda {$outcome_lines[$line_count] += "\x1b[25m" unless $plaintext},
  ],

  "bblink" => [
    lambda {$outcome_lines[$line_count] += "\x1b[5m" unless $plaintext},
    lambda {},
  ],

  "eblink" => [
    lambda {$outcome_lines[$line_count] += "\x1b[25m" unless $plaintext},
    lambda {},
  ],
}

###############
# HANDLE ARGS #
###############

def help
  abort "usage: ptts [flags] <filename>\n" \
      + "flags: \n" \
      + "       -h, --help        prints this help message\n"
      + "       -p, --plaintext   do not add escape sequences\n"
end

ARGV.each { |arg|
  if arg.start_with?("--")
    case arg[2..]
    when "help"
      help
    when "plaintext"
      $plaintext = true
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
}

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
lines.each { |line|
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
          
          instructions << [inst.sub(/\{.*/, ""), arg]

          txt = line[i+1..]
          break
        end
      end
    end

    # call beginning of instructions #
    instructions.each { |inst|
      abort "unknown instruction: #{inst[0]}" if insts[inst[0]].nil?

      if inst[1].nil?
        insts[inst[0]][0].call
      else
        insts[inst[0]][0].call inst[1]
      end
    }

    # add text
    text_append txt

    # call end of instructions #
    instructions.each { |inst|
      if inst[1].nil?
        insts[inst[0]][1].call
      else
        insts[inst[0]][1].call inst[1]
      end
    }

  end
}

# print outcome #
puts ""
puts $outcome_lines, "\n\x1b[0m"
