# Anki Clipboard Monitor

This is a small collection of scripts to help create
[Anki](http://ankisrs.net/) flashcards from text copied to the
clipboard.

During study sessions, especially with incremental reading, it is
often useful to quickly extract raw material for cards from the
material being studied.  Copying text to a separate file or
spreadsheet interrupts the flow of thought.  These scripts should
facilitate simple extraction, and for formatting the data so that Anki
can easily import it.

The clipboard monitor works for things for which you can select the
underlying text: webpages, text files, PDFs, etc.  It doesn't work for
images.

_This is currently only tested on Mac OSX.  It may work for *nix.  It
will not work for Windows._

## Notes

These scripts are use while at the computer.  They are not an Anki
add-on, but a supplement.  Creating cards from extracted material is
something that is more easily done outside of Anki itself, in a
dedicated text editor.

The base study material can be managed in Anki itelf if needed (for
example, using an [Incremental Reading note
type](https://ankiweb.net/shared/info/746685063) or something
similar), or externally.

SuperMemo apparently has tools to extract cards from the studied
material, but I find Anki easier to use, and often prefer to deal with
plain text files when creating study material.

## Scripts

* `monitor.rb`: a script that monitors the clipboard during a
  reading/study session, saving copied data along with some metadata
  to a well-formatted .json file, for future processing to proper
  questions.  This script lets you add tags, sources, or notes to
  copied items on-the-fly which should simplify further card
  creation.
* `cards.rb`: a script to convert the .json created with `monitor.rb`
  to a tab-delimited text file, for importing into Anki.

## Example

You're doing incremental reading on a Wikipedia article, and it
contains information you want to extract for cards.

### Short version

You run `monitor.rb`, set the source and tag for all notes that should
be created, and then go to the webpage.  You then focus on finding and
copying useful information on the webpage that could become cards.
The monitor logs everything that you copy, along with any extra
metadata you set.  When done, return to the monitor and enter `q` to
quit:

```
$ ruby monitor.rb
Logging to /curr/dir/path/20160327_225947.json
Starting monitor.  Anything copied to the clipboard will be logged.
... [menu not shown] ...
> s
Enter the source: https://en.wikipedia.org/wiki/Incremental_reading
> t
Enter the tag: incremental_reading
> [monitor: copied "Incrementa ..."] [monitor: copied "an algorit ..."] q
Goodbye!
Logged to /curr/dir/path/20160327_225947.json
```

The file given contains everything that was copied, with additional metadata:

```
$ cat 20160327_225947.json
[
{
  "note": "",
  "content": "Incremental reading works by breaking up key points of articles into flashcards",
  "source": "https://en.wikipedia.org/wiki/Incremental_reading",
  "tag": "incremental_reading"
}
,
{
  "note": "",
  "content": "an algorithm organises the reading and calculates the ideal time to review each chunk",
  "source": "https://en.wikipedia.org/wiki/Incremental_reading",
  "tag": "incremental_reading"
}
]
```

You convert this into a tab-delimited file for import to Anki:

```
$ ruby cards.rb 20160327_225947.json
Tab-delimited file for import created at 20160327_225947.json.txt.
```


### Longer version

```
$ ruby monitor.rb 
Logging to /curr/dir/path/20160327_223343.json
Starting monitor.  Anything copied to the clipboard will be logged.
Available commands:
  h | help   : prints available commands
  n | note   : adds a note
  p | print  : prints current clipboard entry
  q | quit   : quits
  s | source : sets the source
  t | tag    : sets the tag

>
```

`>` is a prompt.  Set the "source" and "tag" to be used for anything
copied to the clipboard:

```
> s
Enter the source: https://en.wikipedia.org/wiki/Incremental_reading
> t
Enter the tag: memory
```

You copy a sentence on the webpage, and the monitor captures that.
You then add an extra note for context:

```
> [monitor: copied "All articl ..."] n
Enter a note: How are incremental reading notes processed?
```

View the content of the current item:

```
> p
{
  "note": "How are incremental reading notes processed?",
  "content": "All articles and extracts are processed according to the rules of spaced repetition.",
  "source": "https://en.wikipedia.org/wiki/Incremental_reading",
  "tag": "memory"
}
```

Copy another sentence on the same webpage, and then quit the
monitor:

```
> [monitor: copied "For increm ..."] q
Goodbye!
Logged to /curr/dir/path/20160327_223343.json
```

The file content is similar to that given in the short example above.
After editing (if needed), this file can be processed to a
tab-delimited file for import into Anki.  The "note" field is assumed
to be the front of the card, and the "content" the back.  If the note
is blank, "todo" is output.

## System Requirements

* Ruby
* Support for system call `pbpaste`.  This works on MacOSX, but not on
  Windows.

## Installation

Clone this repo, or download a zip.  There aren't any other
dependencies.

## Contributing

Contributions welcome if you can get this working on Windows etc.
There are no unit tests.  Fork it and make a PR.

## License

See LICENSE.txt.