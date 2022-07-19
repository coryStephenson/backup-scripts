#!/usr/bin/env ruby

# This require method imports the ruby-progressbar class
require 'ruby-progressbar'

# This require method imports the date class from the Ruby standard library
require 'date'

# global constants are defined for the tgz root and the root of the directories to be tarred
$tgzdir = "/run/media/cory/1d0f499a-ec35-4244-9b73-567ed41a6aff/B/backups/tgz/"
$rsyncdir = "/home/cory/"

=begin
global array of directory/abbreviation pairs, each implemented as a 2 element array.
I didn't do it as a hash, in order to allow the backups tarballs to be created in a specific order. 
Personally, I like doing the shortest ones first. 
The program creates all the tarballs enumerated in the $tgzs array.
=end

$tgzs =	[
	["down", "Downloads/"],
	["corygit", "coryStephenson.github.io/"],
	["bash", "bash-scripts/"],
	["cpp", "C-plus-plus/"],
	]

class Logger

	attr_reader :logfname                 # getter method attr_reader encapsulating logfname symbol
	attr_accessor :logfile                # getter method attr_accessor encapsulating logfile symbol
	attr_accessor :stagename              # getter method attr_accessor encapsulating stagename symbol
	attr_accessor :errors                 # getter method attr_accessor encapsulating errors symbol
	def initialize(logfname)                                      # initializer for logfname setter method
		@logfname = logfname                                  # assigns logfname symbol to @logfname instance variable
		@errors = 0                                           # assigns 0 to @errors instance variable
		@logfile = File.new(@logfname, "w")                   # instantiates File class with value of instance variable @logfname in write-only mode, truncating existing file to zero length or creates new file
		@logfile.sync = true                                  # all output is immediately flushed to the underlying operating system and is not buffered internally  
	end

	def begins()
	        puts
		puts "Begin #{stagename}..."                         # prints to console using string interpolation
		@logfile.puts "Begin #{stagename}..."                # prints same string as above to log file
	end

	def success()
	        puts
		puts "#{stagename} completed successfully!"               # prints to console using string interpolation
		@logfile.puts "#{stagename} completed successfully!"      # prints same string as above to log file 
	end

	def failure(errmsg)
	        puts
		puts "#{stagename} failed: #{errmsg}"                     # prints to console using string interpolation
		@logfile.puts "#{stagename} failed: #{errmsg}"            # prints same string as above to log file
		errors += 1
	end

	def skipline(msg)
		puts                                                       # prints blank line to console
		@logfile.puts
		if (msg != nil) and (msg != "")                            # prints message to log file if a message exists and it isn't an empty string
			puts msg
			logfile.puts msg
		end
	end

end

def todaystring()                                                                        # concatenates 3 2-digit strings together into a single string that represents the current date
	d = Date.today()
	return zerofill(d.year - 2000) + zerofill(d.month) + zerofill(d.mday)
end


def zerofill(number)                                                                     # meant to parse the today() string
	number += 10000
	string = number.to_s
	twodigit = string[-2, 2]
	return twodigit
end

def tar_cre_string(abbrev, dir)

	command = "tar czvf #{$tgzdir}#{abbrev}#{$datestring}.tgz #{dir}"              # return tar command for the creation of an archive and filtering it through gzip
	return command
end

def tar_diff_string(abbrev, dir)

	command = "tar dzvf #{$tgzdir}#{abbrev}#{$datestring}.tgz"                    # return tar command that is meant to find the difference between the archive and the file system
	return command
end

def tar_md5_string(abbrev)
	command = "md5sum #{$tgzdir}#{abbrev}#{$datestring}.tgz > #{$tgzdir}#{abbrev}#{$datestring}.md5"       # generates an md5 checksum and redirects stdout to an .md5 file
	return command                                                                                         # returns this command string
end

def tar_lst_string(abbrev)
	command = "tar tzvf #{$tgzdir}#{abbrev}#{$datestring}.tgz "
	command = command + "| sed -e \"s/^.* //\" | "                                   # sed -e matches an expression consisting of 0 or more of any character from the previous string
	command = command + "sort > #{$tgzdir}#{abbrev}#{$datestring}.lst"               # sorts the contents of the output from the sed command and redirects stdout to a .lst file
	puts command                                                                     # prints the concatenated string to the console
	return command                                                                   # returns this concatenated string
end

def do1tgz_string_only(commands, abbrev, dir)                                            # Adds the 4 tar command methods to the commands array
	commands.push(tar_cre_string(abbrev, dir))
	commands.push(tar_diff_string(abbrev, dir))
	commands.push(tar_md5_string(abbrev))
	commands.push(tar_lst_string(abbrev))
end

def do1tgz(tgzlogger, tasklogger, abbrev, dir)
	this_tgz_errors = 0                                                              # Initializes this_tgz_errors variable to 0
	tgzlogger.stagename ="Directory #{dir} (#{abbrev}{$datestring}.tgz)"             # Instantiates Logger class symbol stagename for object tgzlogger 
	tgzlogger.skipline("")                                                           # Passes empty string symbol to skipline() method for tgzlogger object
	tgzlogger.begins()                                                               # Calls begins() method associated with tgzlogger object which is part of the Logger class
	
	tasklogger.skipline("Directory #{dir} as #{abbrev}{$datestring}.tgz")            # Passes string to skipline() method for tasklogger object
	tasklogger.stagename = ("Creating #{$tgzdir}#{abbrev}#{$datestring}.tgz")        # Instantiates Logger class symbol stagename for object tasklogger
	tasklogger.begins()                                                              # Calls begins() method associated with tasklogger object
	cre_return = system(tar_cre_string(abbrev, dir))                                 # Passes return value of tar_cre_string method to system method
	if cre_return then                                                               # if return value is true
		tasklogger.success()                                                     # call success() method associated with the object tasklogger
	else                                                                             # else
		tasklogger.failure("")                                                   # Passes empty string to Logger class' failure() method
		this_tgz_errors += 1                                                     # increments this_tgz_errors variable by 1 
	end

	tasklogger.stagename = ("Diffing #{$tgzdir}#{abbrev}#{$datestring}.tgz")         # Instantiates Logger class symbol stagename for object tasklogger 
	tasklogger.begins()                                                              # Calls begins() method associated with tasklogger object
	diff_return = system(tar_diff_string(abbrev, dir))                               # Passes return value of tar_diff_string method to system method
	if diff_return then                                                              # if return value is true
		tasklogger.success()                                                     # call success() method associated with the object tasklogger
	else                                                                             # else
		tasklogger.failure("")                                                   # Passes empty string to Logger class' failure() method
		this_tgz_errors += 2                                                     # increments this_tgz_errors variable by 2
	end

	
	tasklogger.stagename = ("Creating md5 #{$tgzdir}#{abbrev}#{$datestring}.md5")    # Instantiates Logger class symbol stagename for object tasklogger 
	tasklogger.begins()                                                              # Calls begins() method associated with tasklogger object
	md5_return = system(tar_md5_string(abbrev))                                      # Passes return value of tar_md5_string method to system method
	if md5_return then                                                               # if return value is true
		tasklogger.success()                                                     # call success() method associated with the object tasklogger
	else                                                                             # else
		tasklogger.failure("")                                                   # Passes empty string to Logger class' failure() method
		this_tgz_errors += 4                                                     # increments this_tgz_errors variable by 4
	end

	tasklogger.stagename = ("Creating lst #{$tgzdir}#{abbrev}#{$datestring}.lst")    # Instantiates Logger class symbol stagename for object tasklogger
	tasklogger.begins()                                                              # Calls begins() method associated with tasklogger object
	lst_return = system(tar_lst_string(abbrev))                                      # Passes return value of tar_md5_string method to system method
	if lst_return then                                                               # if return value is true
		tasklogger.success()                                                     # call success() method associated with the object tasklogger
	else                                                                             # else
		tasklogger.failure("")                                                   # Passes empty string to Logger class' failure() method
		this_tgz_errors += 8                                                     # increments this_tgz_errors variable by 8
	end

	if this_tgz_errors == 0 then                                                     # if this_tgz_errors variable equals 0
		tgzlogger.success()                                                      # call success() method associated with the object tgzlogger
	else                                                                             # else
		errmsg = "failed on step(s) "                                            # assigns string to errmsg variable
		if this_tgz_errors % 1 == 1 then                                         # if this_tgz_errors equals 1, 1 % 1 == 1 is indeed true, and the create task is to blame for the error 
			errmsg += "(CREATE) "                                            # This string is concatenated to the errmsg string variable
		end                                                                      # if this_tgz_errors equals a 2, 4, or an 8, the condition is false, and this if statement is skipped

		this_tgz_errors /= 2                                                     # Divides the this_tgz_errors variable by 2

		if this_tgz_errors % 1 == 1 then                                         # if this_tgz_errors was previously assigned a value of 2, subsequently divided by 2 once, then the diff task is to blame for the error
			errmsg += "(DIFF) "                                              # This string is concatenated to the errmsg string variable
		end                                                                      # if this_tgz_errors equals a 4 or an 8, the condition is false, and this if statement is skipped

		this_tgz_errors /= 2                                                     # Divides the this_tgz_errors variable by 2

		if this_tgz_errors % 1 == 1 then                                         # if this_tgz_errors was previously assigned a value of 4, subsequently divided by 2 twice, then the md5 task is to blame for the error
			errmsg += "(MD5) "                                               # This string is concatenated to the errmsg string variable
		end                                                                      # if this_tgz_errors equals an 8, the condition is false, and this if statement is skipped

		this_tgz_errors /= 2                                                     # Divides the this_tgz_errors variable by 2

		if this_tgz_errors % 1 == 1 then                                         # if this_tgz_errors was previously assigned a value of 8, subsequently divided by 2 three times, then the lst task is to blame for the error
			errmsg += "(LST) "                                               # This string is concatenated to the errmsg string variable
		end

		tgzlogger.failure(errmsg)                                                # calls failure() method associated with the object tgzlogger, passing errmsg as an argument
	end

end



def main()
	$datestring = todaystring()                                                                 # Assigns return value of todaystring() method to global variable $datestring
	Dir.chdir($rsyncdir)                                                                        # Passes global $rsyncdir constant to chdir method (kernel system call)
	system("pwd")                                                                               # Runs external command pwd
	system("sleep 1")                                                                           # Runs external command sleep 1
	tasklogger = Logger.new(ENV['HOME'] +"/maketgz_task.log")                                   # Assigns instantiation of Logger class to tasklogger object
	tgzlogger = Logger.new(ENV['HOME'] + "/maketgz_tgz.log")                                    # Assigns instantiation of Logger class to tgzlogger object
	 
	$tgzs.each do |tgz|                                                     # tgz is a named argument that is used to iterate over the data in the global array of directory/abbreviation pairs, defined earlier
		do1tgz(tgzlogger, 
		       tasklogger, 
		       tgz[0], 
		       tgz[1]
		      )
		
            
        end
end
	


main()
