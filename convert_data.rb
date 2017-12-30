#!/usr/bin/env ruby

file_encoding = "UTF-8"
file_counter = ""
flag_debug = false
flag_ignore_wit_prefix = false

while ! ARGV.empty?
  arg = ARGV.shift
  case arg
  when "--debug"
    flag_debug = true
  when "--ignore-with-prefix"
    flag_ignore_wit_prefix = true
  else
    file_counter = arg
  end
end

if file_counter.empty?
  STDERR.print "[ERR] Counter char file name was not given!", "\n"
  STDERR.print "[LOG] Usage: ruby convert_data.rb [counter_char_map_file] < [PoliMorf_data]", "\n"
  STDERR.print "[LOG]  example: ruby convert_data.rb data/counter_char < data/PoliMorf.tab", "\n"
  exit(-1)
end

MAP_COUNTER = {}
File.open(file_counter, 'r', encoding: file_encoding) do |infile|
  while (line = infile.gets)
    line = line.strip
    if line_match = line.match(/^([0-9]+)\t(.)$/)
      counter_int, counter_char = line_match.captures
      MAP_COUNTER[counter_int.to_i] = counter_char
    else
      STDERR.print "[ERR] Cannot parse line: '", line, "' in file ", file_symbols, "\n"
      exit(-2)
    end
  end
end
if MAP_COUNTER.length < 48
  STDERR.print "[ERR] Too few element in counter char file \n"
  exit(-3)
end

count_ignored = 0

while line=gets
  line = line.strip
  words = line.split
  word_source = words[0]
  word_target = words[1]
  len_source = word_source.length
  len_target = word_target.length
  output = word_source + '+'
  if word_source =~ /[+]/ || word_target =~ /[+]/ || (len_source == 1 && len_target > 1)
    if flag_debug
      count_ignored += 1
      print "[LOG] Ignore line: ", line, "\n"
    end
  else
    if flag_ignore_wit_prefix && word_source =~ /^(naj|nie)/ && word_source[0] != word_target[0]
      if flag_debug
        count_ignored += 1
        print "[LOG] Ignore line with prefix 'naj' orz 'nie': ", line, "\n"
      end
      next
    end
    if len_source > len_target
      (0..len_source-1).each do |i|
        if i < len_target
          if word_source[i] != word_target[i]
            output += MAP_COUNTER[len_source-i] + word_target[i, len_target-i]
            break
          end
        else
          output += MAP_COUNTER[len_source-i]
          break
        end
      end
    elsif len_source < len_target
      (0..len_target-1).each do |i|
        if i < len_source
          if word_source[i] != word_target[i]
            output += MAP_COUNTER[len_source-i] + word_target[i, len_target-i]
            break
          end
        else
          output += MAP_COUNTER[len_source-i] + word_target[i, len_target-i]
          break
        end
      end
    else
      (0..len_source-1).each do |i|
        if word_source[i] != word_target[i]
          output += MAP_COUNTER[len_target-i] + word_target[i, len_target-i]
          break
        end
      end
      if output[-1] == '+'
        output += '0'
      end
    end
    if flag_debug
      print "[LOG] Converting: ", word_source, ' -> ', word_target, ' -> ', output, "\n"
    end
    puts output
  end
end
