#!/bin/ruby

# Makes a file for input from a JSON file.  The expected format of the
# input data is:
#
#   [{"content":"...","note":"optional","source":"...","tag":"..."},
#   ...]
#

require 'json'

def string_or_nil(s)
  (s == '') ? nil : s
end

def make_line(hsh)
  back_text = hsh['content'].gsub("\n",'<br>').gsub("\r",'<br>').gsub("\t", '&nbsp' * 4) || ''
  src = string_or_nil(hsh['source'])
  note = string_or_nil(hsh['note'])
  back = [ back_text, src ].compact.join('<br><br>source: ') || ''
  front = string_or_nil(hsh['note']) || 'todo'
  [ front, back, hsh['tag'] ].join("\t")
end

def create_card_file(json_input_file, output_file)
  raise "missing file #{filename}" unless File.exist?(json_input_file)
  j = JSON.parse(File.read(json_input_file))
  File.open(output_file, 'w') do |f|
    j.select { |hsh| hsh['content'] != '' }.each { |hsh| f.puts make_line(hsh) }
  end
end

if __FILE__ == $0
  filename = ARGV[0]
  raise "filename required" if filename.nil?
  outfile = "#{filename}.txt"
  create_card_file(filename, outfile)
  puts "Tab-delimited file for import created at #{outfile}."
end
