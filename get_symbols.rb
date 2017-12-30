#!/usr/bin/env ruby

require 'set'

LETTER = Set[]

while line = gets
  line = line.strip
  line.each_char { |c| LETTER.add(c) }
end

counter = 0
LETTER.to_a.sort.each do |c|
  print c, " ", counter, "\n"
  counter += 1
end
