audio-jz
========

The ultimate tool for audiophiles

### Copyright and License

Copyright (c) 2014 Andrew Ward, Martin Heath, Uditha Atukorala

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
[GNU General Public License](http://www.gnu.org/licenses/gpl.html)
for more details.


### Using Docker

You can use the ```audiojz/audio-jzr``` image from [docker index](http://index.docker.io/)
to easily resample your .flac files.

Before you can use the docker image you'll need to organise your input directory
structure to be something similar to following:

	/path/to/music
	  |
	  |- input
	  |    |
	  |    |- Artist
	  |    |    |
	  |    |    |- Album
	  |    |        |
	  |    |        - song.flac
	  |    |
	  |    - song-1.flac
	  |    - song-2.flac
	  |
	  |- output ( this directory should be empty )


Make sure the /path/to/music/output directory is empty and run the following docker command.

``` bash
$ docker run --rm -v /path/to/music:/data/audio-jz audiojz/audio-jzr
```
This will start processing all your music files from /path/to/music/input directory
and store them under /path/to/music/output.


