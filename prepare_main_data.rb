#!/usr/bin/env ruby

require 'set'

file_symbols = ""
file_counter = ""
file_fst = ""
file_output = ""
file_encoding = 'UTF-8'

MAP_SYMBOL = {}
MAP_COUNTER_CHAR = {}
MAP_STATE = []
FINAL = Set[]

if ARGV.length < 4
  STDERR.print "[LOG] Usage: ruby prepare_main_data.rb [symbol_map_file] [counter_char_map_file] [openfst_automata_text_file] [file_name_output]", "\n"
  STDERR.print "[LOG]  example: ruby prepare_main_data.rb data/symbols data/counter_char data/fst_text.fst data/binary", "\n"
  STDERR.puts "[ERR] Too few arguments"
  exit(-1)
else
  file_symbols = ARGV[0]
  file_counter = ARGV[1]
  file_fst = ARGV[2]
  file_output = ARGV[3]
end

File.open(file_symbols, 'r', encoding: file_encoding) do |infile|
  symbol_counter = 0
  while (line = infile.gets)
    line = line.strip
    if line_match = line.match(/^(.) ([0-9]+)$/)
      symbol, _ = line_match.captures
      MAP_SYMBOL[symbol] = symbol_counter
      symbol_counter += 1
    else
      STDERR.print "[ERR] Cannot parse line: '", line, "' in file ", file_symbols, "\n"
      exit(-2)
    end
  end
end

File.open(file_counter, 'r', encoding: file_encoding) do |infile|
  while (line = infile.gets)
    line = line.strip
    if line_match = line.match(/^([0-9]+)\t(.)$/)
      counter_int, counter_char = line_match.captures
      MAP_COUNTER_CHAR[counter_int] = counter_char
    else
      STDERR.print "[ERR] Cannot parse line: '", line, "' in file ", file_symbols, "\n"
      exit(-3)
    end
  end
end

state_last = 0
state_numbers = 0
File.open(file_fst, 'r', encoding: file_encoding) do |infile|
  while (line = infile.gets)
    line = line.strip
    if line_match = line.match(/^([0-9]+)\t([0-9]+)\t(.)\t(.)$/)
      state_numbers += 1
      state_begin, state_end, char_in, char_out = line_match.captures
      MAP_STATE << [state_begin, MAP_SYMBOL[char_in], state_end]
      if state_last < state_begin.to_i
        state_last = state_begin.to_i
      end
      if state_last < state_end.to_i
        state_last = state_end.to_i
      end
    elsif line_match = line.match(/^([0-9]+)$/)
      state_final = line_match.captures[0]
      FINAL.add(state_final)
    else
      STDERR.print "[ERR] Cannot parse line: '", line, "' in file ", file_symbols, "\n"
      exit(-4)
    end
  end
end

output = File.open(file_output, "w")

output << "<MAP_SYMBOL> " << MAP_SYMBOL.length << "\n"
MAP_SYMBOL.to_a.each do |key, value|
  output << key << " " << value << "\n"
end

output << "<MAP_COUNTER_CHAR> " << MAP_COUNTER_CHAR.length << "\n"
MAP_COUNTER_CHAR.to_a.each do |value_int, value_char|
  output << value_int << " " << value_char << "\n"
end

output << "<FINAL> " << FINAL.length << "\n"
FINAL.each do |value|
  output << value << "\n"
end

output << "<MAP_STATE> " << state_last + 1 << " " << MAP_SYMBOL.length << " " << state_numbers << "\n"
MAP_STATE.to_a.each do |state_begin, char_in_int, state_end|
  output << state_begin << " " << char_in_int << " " << state_end << "\n"
end

output.close()
