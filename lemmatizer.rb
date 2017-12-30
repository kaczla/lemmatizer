#!/usr/bin/env ruby

require 'set'

file_data = ''
file_encoding = 'UTF-8'
$flag_only_output = false
$flag_ignore_unknown = false

MAP_SYMBOL = {}
MAP_SYMBOL_REVERSED = {}
MAP_COUNTER_CHAR = {}
MAP_STATE = {}
FINAL = Set[]

def print_err_parse_line(line, file_name, file_mode, line_num)
  STDERR.print "[ERR] Cannot parse line: '", line, "' in file ", file_name, "(mode=", file_mode, ", line=", line_num, ")", "\n"
end


while ! ARGV.empty?
  arg = ARGV.shift
  case arg
  when "--help"
    STDERR.print "Lemmatizer - base on PoliMorf",
                 "Usage:\n",
                 "\tlemmatizer",
                 "[--data <data_file_path>] ",
                 "[--only-output] [--ignore-unknown]\n",
                 "Options:\n",
                 "\t --data <data_file_path> - main data path, default path is 'data/main_data'\n",
                 "\t --only-output - print only output (where <unk> is unknown word - not found in PoliMorf), defualt printing fomat is:\n",
                 "\t\t '> input_word -> founded_words_separated_byt_comma' - when found word in PoliMorf\n",
                 "\t\t '- input_word' - when word was not found\n",
                 "\t --ignore-unknown - ignore unknown word - not found in PoliMorf (use with --only-output)\n"
    exit(0)
  when "--only-output"
    $flag_only_output = true
  when "--ignore-unknown"
    $flag_ignore_unknown = true
  when "--data"
    file_data = ARGV.shift
  else
    STDERR.print "[WRN] Invalid argument: \"", arg, "\", ignored\n"
  end
end

if file_data.empty?
  file_data = 'data/main_data'
end

File.open(file_data, 'r', encoding: file_encoding) do |infile|
  file_mode = 0
  file_counter = 0
  file_line_counter = 0
  while (line = infile.gets)
    line = line.strip
    file_counter += 1
    if file_line_counter <= 0
      file_mode = 0
    end
    case file_mode
    # SYMBOL MAP
    when 1
      file_line_counter -= 1
      if line_match = line.match(/^(.) ([0-9]+)$/)
        symbol, symbol_counter = line_match.captures
        MAP_SYMBOL[symbol] = symbol_counter.to_i
        MAP_SYMBOL_REVERSED[symbol_counter.to_i] = symbol
      else
        print_err_parse_line(line, file_data, file_mode, file_counter)
        exit(-1)
      end
    # COUTNER CHAR MAP
    when 2
      file_line_counter -= 1
      if line_match = line.match(/^([0-9]+) (.)$/)
        counter_int, counter_char = line_match.captures
        MAP_COUNTER_CHAR[counter_char] = counter_int.to_i
      else
        print_err_parse_line(line, file_data, file_mode, file_counter)
        exit(-2)
      end
    # FINAL STATES
    when 3
      file_line_counter -= 1
      if line_match = line.match(/^([0-9]+)$/)
        state_final = line_match.captures[0]
        FINAL.add(state_final.to_i)
      else
        print_err_parse_line(line, file_data, file_mode, file_counter)
        exit(-3)
      end
    # ALL STATES
    when 4
      file_line_counter -= 1
      if line_match = line.match(/^([0-9]+) ([0-9]+) ([0-9]+)$/)
        state_begin, char_in, state_end = line_match.captures
        if !MAP_STATE.key?(state_begin.to_i)
          MAP_STATE[state_begin.to_i] = {}
        end
        MAP_STATE[state_begin.to_i][char_in.to_i] = state_end.to_i
      else
        print_err_parse_line(line, file_data, file_mode, file_counter)
        exit(-4)
      end
    else
      if line_match = line.match(/^[<]MAP_SYMBOL[>] ([0-9]+)$/)
        file_mode = 1
        file_line_counter = line_match.captures[0].to_i
      elsif line_match = line.match(/^[<]MAP_COUNTER_CHAR[>] ([0-9]+)$/)
        file_mode = 2
        file_line_counter = line_match.captures[0].to_i
      elsif line_match = line.match(/^[<]FINAL[>] ([0-9]+)$/)
        file_mode = 3
        file_line_counter = line_match.captures[0].to_i
      elsif line_match = line.match(/^[<]MAP_STATE[>] ([0-9]+) ([0-9]+) ([0-9]+)$/)
        file_mode = 4
        file_line_counter = line_match.captures[2].to_i
      else
        print_err_parse_line(line, file_data, 0, file_counter)
        exit(-5)
      end
    end
  end
end

$state_plus = MAP_SYMBOL['+']

def check_next_letters(state_begin)
  words = []
  for key, value in MAP_STATE[state_begin]
    letters = MAP_SYMBOL_REVERSED[key]
    if FINAL.include?(value)
      words.push(letters)
    end
    if MAP_STATE.key?(value)
      check_next_letters(value).each do |found_letters|
        words.push(letters + found_letters)
      end
    end
  end
  return words
end

def check_word(word)
  if word.empty?
    return ""
  end
  base = ""
  word_len = word.length
  state_begin = 0
  found = true
  (0..word_len-1).each do |i|
    if MAP_STATE.key?(state_begin)
      if MAP_SYMBOL.key?(word[i])
        state_symbol = MAP_SYMBOL[word[i]]
        if MAP_STATE[state_begin].key?(state_symbol)
          state_begin = MAP_STATE[state_begin][state_symbol]
        else
          found = false
          break
        end
      else
        found = false
        break
      end
    else
      found = false
      break
    end
  end
  if found
    if MAP_STATE[state_begin].key?($state_plus)
      state_begin = MAP_STATE[state_begin][$state_plus]
      check_next_letters(state_begin).each do |letters|
        to_remove = MAP_COUNTER_CHAR[letters[0]]
        if letters.length > 1
          letters = letters[1,letters.length-1]
        else
          letters = ''
        end
        if word_len != to_remove
          letters = word[0,word_len-to_remove] + letters
        end
        if base.empty?
          base = letters
        else
          base += ', ' + letters
        end
      end
    else
      found = false
    end
  end
  output = ''
  if $flag_only_output
    if found
      output = base
    else
      if $flag_ignore_unknown
        return
      else
        output = "<unk>"
      end
    end
  else
    if found
      output = "> " + word + " -> " + base
    else
      output = "- " + word
    end
  end
  return output
end

STDERR.puts "Give some word:"

while line = gets
  line = line.gsub(/\s+/m, ' ').strip.split(' ').each do |word|
    output = check_word(word)
    if !output.to_s.empty?
      puts output
    end
  end
end
