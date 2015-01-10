#!/bin/sh

# N.B. To use this utility you need to install metaflac and exiftool
#      and have libsamplerate installed
#
# Metaflac:- FLAC tagging utility
#
#    % sudo apt-get install flac
#
# SRC resample:- Does the resampling
#
#    http://www.mega-nerd.com/SRC/download.html
#    % sudo apt-get install samplerate-programs
#
# sndfile-resample -to 192000 -c 0 04\ Skyscraper.flac Skyscraper192Khz.flac
#
# Example Usage:-
#
# audio-jzr.tcl <BASE_DIR> <BASE_OUTPUT_DIR> <STARTING_DIR>
# audio-jzr.tcl "/media/award/New Volume/Music" "/media/award/New Volume/192" "/media/award/New Volume/Music/Artists/Rush" 96000
#
# The first directory (STARTINGDIR) is the starting place for the utility. It traverses the directory
# structure under this directory, creates an identical structure under the second directory
# (BASE_OUTPUT_DIR) and outputs the resampled file to the new directory.
#
# e.g. BASE_DIR where music collection is
#
# /media/award/New Volume/Music
#
# STARTING_DIR where you want to start tagging from (and all subdirectories)
#
# /media/award/New Volume/Music/Artists/Rush
#
# BASE_OUTPUT_DIR where new resample music is output
#
# /media/award/New Volume/192
#
# In this example, /media/award/New Volume/192/Artists/Rush would be created
#
# There is an option -m to do metadata only. If the destination file does not exist, it is ignored, otherwise
# the metadata only is copied.

# Next line is executed by /bin/sh only \
exec tclsh $0 ${1+"$@"}

global STARTING_DIR
global BASE_OUTPUT_DIR
global SAMPLERATE
global EXIT_ON_ERROR
global OUTPUT_TO_SAME_DIR
global FILE_APPEND
global METADATA_ONLY

# Find and remove -m option to indicate copying metadata only
puts "before argv: $argv"
set metadata_only [lsearch $argv -m]
if {$metadata_only != -1} {
	set METADATA_ONLY 1
	set argv [lreplace $argv $metadata_only $metadata_only]
} else {
	set METADATA_ONLY 0
}
puts "after argv: $argv"

set BASE_DIR        [lindex $argv 0]
set BASE_OUTPUT_DIR [lindex $argv 1]
set STARTING_DIR    [lindex $argv 2]
set SAMPLERATE      [lindex $argv 3]

set FILE_APPEND $SAMPLERATE
set EXIT_ON_ERROR  1

if {$SAMPLERATE == ""} {
	# Default
	set SAMPLERATE 96000
}

if {![file isdirectory $STARTING_DIR]} {
	puts "Starting directory not found $STARTING_DIR"
	exit
}

if {$BASE_DIR == $BASE_OUTPUT_DIR} {
	#puts "Output directory must be different to base directory"
	#exit
	set OUTPUT_TO_SAME_DIR Y
} else {
	set OUTPUT_TO_SAME_DIR N
}


# Automatically set to resample at level 0 (highest)
# This is set by flag -c
#
# SRC_SINC_BEST_QUALITY       = 0,
# SRC_SINC_MEDIUM_QUALITY     = 1,
# SRC_SINC_FASTEST            = 2,
# SRC_ZERO_ORDER_HOLD         = 3,
# SRC_LINEAR                  = 4
#
proc resample {file newfile} {
	global SAMPLERATE
	global EXIT_ON_ERROR

	# first write to .tmp and copy once done so incomplete conversions detected
	set tempfile "${newfile}.tmp"

	if {[file exists $tempfile]} {
		puts "Removing tempfile $tempfile"
		file delete $tempfile
	}

	puts "Resampling $file to $newfile ($SAMPLERATE)"

	if {[catch {
		set output [exec sndfile-resample -to $SAMPLERATE -c 0 $file $tempfile]

		puts "resample: $output"

		file rename $tempfile $newfile

		# TODO CHECK FOR Target samplerate and input samplerate are the same. Exiting.

	} msg]} {
		puts "resample ERROR ($msg)"
		if {$EXIT_ON_ERROR} {
			exit
		}
	}
}



# Copy the metadata (tags and image) using metaflac
#
proc copy_metadata {in_file out_file} {
	global EXIT_ON_ERROR

	# Create a temporary file name to store the pictures
	set tmpfile $::argv0.[pid]

	if {[catch {
		exec metaflac --remove-all-tags $out_file
		exec metaflac --no-utf8-convert --export-tags-to=- $in_file | metaflac --no-utf8-convert --import-tags-from=- $out_file
		exec metaflac --no-utf8-convert --export-picture-to=$tmpfile $in_file 
		exec sync
		if {[file exists $tmpfile]} {
			exec metaflac --no-utf8-convert --import-picture-from=$tmpfile $out_file
		}

		set output [exec exiftool $out_file]
		puts "copied metadata: $output"

	} msg]} {

		# Ignore errors - e.g. no picture in file
		# TODO: improve!
		puts "metaflac tagging error ($msg)"
	}

	# Don't error if the file is not there
	catch {[exec rm $tmpfile]} 
}



# Recursively navigate down the directory structure
# checking if flacs exist that don't have an equivalent
# file in the corresponding directory
#
proc navigate_dir {dir prev_dir depth} {

	global STARTING_DIR
	global BASE_OUTPUT_DIR
	global BASE_DIR
	global OUTPUT_TO_SAME_DIR
	global FILE_APPEND
	global METADATA_ONLY

	incr depth
	puts "Directory: $dir"

	# Safety check as recursive
	if {$depth > 10} {
		puts "Recursive directory limit reached. Exit"
		exit
	}

	# Keep track of last directory in tree
	if {[file isdirectory $dir]} {
		set prev_dir $dir
	}

	# List the directory
	if {[catch {
		set contents [glob -directory $dir *]
	} msg]} {
		return
	}

	foreach file_item $contents {

		if {[file isdirectory $file_item]} {
			# Continue drilldown
			navigate_dir $file_item $prev_dir $depth
		} else {
			# Can we operate on it (currently only handles FLACS)
			# N.B. resampler doesn't work on mp3
			set file_extension [file extension $file_item]

			if {$file_extension == ".flac"} {

				puts "Found FLAC file to operate on $file_item"

				#
				# Work out the new output directory/ filename
				#

				# get length of filename
				set len_fname [expr [string length $file_item] - [string length $prev_dir] - 1]

				# get length of file_item without filename
				set dir_length [expr [string length $file_item] - $len_fname]

				# get directory structure that needs to be created
				set output_dir_structure [string range $file_item [string length $BASE_DIR] $dir_length-1]

				# get filename
				set track_name [string range $file_item $dir_length end]

				puts "track_name=$track_name"

				if {$OUTPUT_TO_SAME_DIR} {
					set output_dir "$prev_dir/"

					# Calculate the new filename
					set output_filename "${output_dir}$track_name"
					set output_filename "[string range $output_filename 0 end-5]_${FILE_APPEND}.flac"

					puts "output_filename=$output_filename"

					if {[file exists $output_filename]} {
						puts "have file already ignore"
					}

					# check for converted file
					set converted_file [string range $file_item [expr [string length $file_item] -5 -[string length $FILE_APPEND]] [expr [string length $file_item]-5]]
					puts "converted_file $converted_file"

					if {$converted_file == $FILE_APPEND} {
						puts "ALREADY HAVE RESAMPLED FILE"
						continue
					}

				} else {
					# Append this to the new directory
					set output_dir "${BASE_OUTPUT_DIR}${output_dir_structure}"

					# Create if doesn't exist
					if {![file isdirectory $output_dir]} {
						puts "Making output directory $output_dir"
						file mkdir $output_dir
					}

					# Calculate the new filename
					set output_filename "${output_dir}$track_name"
					puts "output_filename=$output_filename"
				}

				# Check to see if it exists
				if {[file exists $output_filename]} {

					# If metadata only, then copy over
					if {$METADATA_ONLY} {
						# copy the tags and picture to the new file
						copy_metadata $file_item $output_filename
					}

					puts "File already exists, continue."

				} else {

					if {!$METADATA_ONLY} {
						# Use SRC to resample
						resample $file_item $output_filename
					}

					# copy the tags and picture to the new file
					copy_metadata $file_item $output_filename
				}

			}
		}
	}
}


# Start the navigation
navigate_dir $STARTING_DIR "" 0

