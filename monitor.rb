#!/bin/ruby

require 'json'
require 'time'

# Monitors the clipboard, and on change, writes copied data plus some
# metadata to an ostream.
class ClipboardMonitor

  def initialize(ostream)

    # 'source' metadata, set by self.source.
    @source = ''

    # 'tag' metadata, set by self.tag
    @tag = ''

    # flag this as an incremental reading extract
    @is_extract = false

    # 'note' metadata - any additional notes for the content copied to
    # the clipboard.
    @note = ''

    # Keep track of the first item printed, as this determines if a
    # comma delimiter is needed.
    @first_clipboard_item_has_been_printed = false

    # Item that was last copied to the clipboard since this instance
    # was instantiated.
    @last_copied_item = nil

    # Where to print data.  Must support "puts" method.
    @ostream = ostream

    @thread = Thread.new do
      # Start the JSON array.
      @ostream.puts '['
      begin
        monitor_clipboard()
      rescue e
        puts "FAILURE: #{e}"
      end
    end
  end

  attr_accessor :source, :tag, :note

  # pbpaste works on MacOSX, and may work on other *nix systems.
  def get_clipboard_content()
    `pbpaste`
  end

  # Data to write to @ostream.
  def build_output()
    h = {
      'note' => @note,
      'content' => @last_copied_item,
      'source' => @source,
      'tag' => [@tag, (@is_extract ? 'extract' : '')].join(' ').strip
    }
    JSON.pretty_generate(h)
  end

  def toggle_extract_tag()
    @is_extract = !@is_extract
    puts "Tagging as an extract is now #{@is_extract ? 'on' : 'off'}"
  end

  def write_old_item()
    return if (@last_copied_item || '').strip.size == 0
    @ostream.puts ',' if @first_clipboard_item_has_been_printed
    @ostream.puts build_output()
    @note = ''  # The note was only applicable to the old item.
    @first_clipboard_item_has_been_printed = true
  end
  
  # Infinite loop managed by @thread.
  def monitor_clipboard()
    # The clipboard content retrieved on entry into this function
    # already existed on the keyboard, and should not be written to
    # @ostream.
    old_content = get_clipboard_content()
    while true
      content = get_clipboard_content()
      # Only write changes in clipboard content.  Don't write out URLs
      # as clipboard items, as that is probably just a copy-paste of
      # the browser URL to set the @source of this monitor.
      if (content != old_content && content !~ /^http[s]:\/\//)
        print "[monitor: copied \"#{content[0, 10]} ...\"] "
        write_old_item()
        @last_copied_item = content
      end
      old_content = content
      sleep(1)
    end
  end
  
  def stop()
    write_old_item()
    # End the JSON array.
    @ostream.puts ']'
    @thread.kill
  end
  
end

class MenuItem
  attr_accessor :name, :abbrev, :description, :command
  def initialize(name, abbrev, description, command)
    @name = name
    @abbrev = abbrev
    @description = description
    @command = command
  end
end

# Filestream writer.
class FileOstream
  def initialize(filename)
    @filename = filename
  end

  attr_reader :filename

  def self.random_filename()
    f = DateTime.now.strftime("%Y%m%d_%H%M%S")
    File.join(Dir.pwd, "#{f}.json")
  end

  # Write data.  Opens on each call, rather than holding a
  # long-running file handle.
  def puts(s)
    File.open(filename, 'a+') { |f| f.puts s }
  end
end

#################

def print_help(menu)
  items = menu.map do |menu_item|
    [ "#{menu_item.abbrev} | #{menu_item.name}", menu_item.description ]
  end
  maxlen = items.map { |entry, desc| entry.length }.max
  puts "Available commands:"
  items.sort.each do |entry, desc|
    puts "  #{entry.ljust(maxlen + 1)}: #{desc}"
  end
  puts
end


# Monitor the clipboard, and output the collected information to the
# io object.
def main(io)
  cm = ClipboardMonitor.new(io)

  menu = [
    MenuItem.new('source', 's', 'sets the source', lambda { print "Enter the source: "; cm.source = gets.chomp }),
    MenuItem.new('tag', 't', 'sets the tag', lambda { print "Enter the tag: "; cm.tag = gets.chomp }),
    MenuItem.new('note', 'n', 'adds a note', lambda { print "Enter a note: "; cm.note = gets.chomp }),
    MenuItem.new('print', 'p', 'prints current clipboard entry', lambda { puts cm.build_output() }),
    MenuItem.new('extract', 'x', 'toggles the "extract" tag', lambda { cm.toggle_extract_tag() }),
    MenuItem.new('quit', 'q', 'quits', lambda { }),
    MenuItem.new('help', 'h', 'prints available commands', lambda { print_help(menu) })
  ]

  puts "Starting monitor.  Anything copied to the clipboard will be logged."
  print_help(menu)
  last_menu_selection = menu[0] # Arbitrary selection
  while last_menu_selection.name != "quit"
    print "> "
    entry = gets.chomp
    m = menu.select { |m| m.name == entry || m.abbrev == entry }
    if m.size == 0
      puts "Unknown command #{entry}"
      print_help(menu)
    else
      last_menu_selection = m[0]
      last_menu_selection.command.call
    end
  end

  puts "Goodbye!"
  cm.stop()
end


if __FILE__ == $0
  f = FileOstream.new(FileOstream.random_filename())
  puts "Logging to #{f.filename}"
  main(f)
  puts "Logged to #{f.filename}"
end
