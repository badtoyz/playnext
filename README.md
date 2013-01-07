# playnext

`playnext` is a small shell script that helps you watch series, listen to podcasts, or basically do anything to a series of files sequentially.

The basic operation is as follows: `cd` to a directory that contains some media files, and type:

    mplayer "`playnext`"

Instead of `mplayer`, you can of course use any media player or other tool of your choice. The `playnext` script will have remembered the filename of the last episode you played (if any), and output the next one. The backticks make the shell substitute this filename in that place.

Caveats:

* All files in the directory are assumed to be media files. If you stumble into the occasional unplayable file, just try again to get the next one.
* Alphabetical ordering, both of files and of directories, is assumed to be the correct one.

`playnext`'s memory lives in `~/.playnextrc`, which is a simple plain text file containing, on each line, the file name of the last episode played.

Several options can be specified to ask `playnext` to do specific things. Run `playnext -h` for more information.
