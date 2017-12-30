#!/usr/bin/env ruby

FST_START = 0
FST_END = 1

counter = 2

while line = gets
  line = line.strip
  len_line = line.length
  if len_line > 0
    max_index_line = len_line - 1
    (0..len_line-1).each do |i|
      if i == 0
        print FST_START
      else
        print counter
        counter += 1
      end
      print ' '
      if i == max_index_line
        print FST_END
      else
        print counter
      end
      print ' ', line[i], ' ', line[i], "\n"
    end
  end
end

puts FST_END
