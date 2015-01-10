FROM ubuntu:14.04

RUN apt-get update
RUN apt-get -y install tcl8.6
RUN apt-get -y install flac samplerate-programs

ADD bin/audio-jzr.tcl /usr/local/bin/audio-jzr

VOLUME [ "/data/audio-jz" ]

ENTRYPOINT [                        \
	"/usr/bin/tclsh8.6",            \
	"/usr/local/bin/audio-jzr",     \
	"/data/audio-jz",               \
	"/data/audio-jz/output",        \
	"/data/audio-jz/input",         \
	"96000"                         \
]

