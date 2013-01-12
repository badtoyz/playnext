# playnext

`playnext` is a small shell script that helps you watch series, listen to podcasts, or basically do anything to a series of files sequentially.

The basic operation is as follows: if `/some/directory` contains media files, type

    playnext /some/directory

and it will play the first media file in the directory and its subdirectories, using `mplayer`. The next time you run it, it plays the second one, and so on.

After you've once typed `/some/directory` in full, you can afterwards get by with just a substring of the final directory component, e.g. `directory`, `dir` or even `d`:

    playnext dir

As long as this uniquely identifies a previously used directory, it will work.

Instead of `mplayer`, you can of course use any media player or other tool of your choice, using the `-c` option.

Caveats:

* All files in the directory are assumed to be media files. If you stumble into the occasional unplayable file, just try again to get the next one.
* Alphabetical ordering, both of files and of directories, is assumed to be the correct one.

`playnext`'s memory lives in `~/.playnextrc`, which is a simple plain text file containing, on each line, the file name of the last episode played.

Several options can be specified to ask `playnext` to do specific things. Run `playnext -h` for more information.
