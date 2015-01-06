FROM ubuntu:14.04

RUN apt-get update
RUN apt-get -y install tcl8.6
RUN apt-get -y install flac samplerate-programs libimage-exiftool-perl

ADD bin/recode.tcl /usr/local/bin/recode.tcl

VOLUME [ "/data/audio-jzr" ]

