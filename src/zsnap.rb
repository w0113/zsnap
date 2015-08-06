#!/usr/bin/env ruby
# zsnap.rb - automatic and simple snapshot tool for ZFS on Linux.
# Copyright (C) 2015 Wolfgang Holoch <wolfgang.holoch@gmail.com>
# See LICENSE.md file for licensing information.
#
# This script creates ZFS snapshots and deletes snapshots older than a user
# defined period. This script was only tested with ZFS on Linux. For further
# information, please read the file README.md.

require "logger"
require "optparse"
require "time"

# The logger which is used throughout this project.
LOG = Logger.new STDOUT
# Default log level.
LOG.level = Logger::WARN

#
# == Description
#
# The ZSnap module contains all classes and methods of this project.
#
module ZSnap
  
  #
  # == Description
  #
  # This class represents a ZFS snapshot.
  #
  class Snapshot

    # The allowed group name format as part of the snapshot name.
    GROUP_FORMAT = /^[-a-zA-Z0-9]+$/
    # The allowed date format as part of the snapshot name.
    DATE_FORMAT = /^\d{4}-\d{2}-\d{2}$/
    # The allowed hour format as part of the snapshot name.
    HOUR_FORMAT = /^\d{2}:\d{2}$/
    # The allowed timezone format as part of the snapshot name.
    ZONE_FORMAT = /^-?\d{4}$/

    # The old snapshot name format. The name separates each item of the array with an underscore.
    MASK_OLD_1 = ["zsnap", DATE_FORMAT, /^\d{2}:\d{2}:\d{2}$/]
    # The new snapshot name format, without group. The name separates each item of the array with an underscore.
    MASK_V_1   = ["zsnap", DATE_FORMAT, HOUR_FORMAT, ZONE_FORMAT]
    # The new snapshot name format, with group. The name separates each item of the array with an underscore.
    MASK_V_2   = ["zsnap", GROUP_FORMAT, DATE_FORMAT, HOUR_FORMAT, ZONE_FORMAT]

    # The group name of snapshots, this snapshot belongs to.
    # Returns a String object.
    attr_reader :group
    # The time at wich this snapshot was created.
    # Returns a Time object.
    attr_reader :time
    # The corresponding Volume of this snapshot.
    # Returns a Volume object.
    attr_reader :volume

    #
    # === Description
    #
    # Create an instance.
    #
    # === Args
    #
    # [+opts+]
    #   Option hash.
    #
    # +opts+ accepts the following symbols to initialize a Snapshot object:
    #
    # [+:name+]
    #   The name of the snapshot. See documentation of the method #name= for further information.
    # [+:volume+]
    #   The Volume object to which this snapshots belongs.
    # [+:group+]
    #   The group name of this snapshot as a String object (default = nil = default group).
    # [+:time+]
    #   The time (as Time object) when this snapshot was created (default = Time.now).
    #
    # A new instance can be created by supplying either volume, group and time, or the name parameter.
    #
    def initialize(opts = {})
      # Default arguments:
      opts = {volume: nil, name: nil, group: nil, time: Time.now}.merge opts

      # Set group to given parameter if it consists only of the allowed characters.
      if opts[:group].nil? or opts[:group] =~ GROUP_FORMAT
        @group = opts[:group]
      else
        raise StandardError, "The group name must only contain alphabetic, numeric or the minus character."
      end

      if opts[:name]
        # Set the attributes by the given name.
        self.name = opts[:name]
      elsif opts[:volume]
        # Set the attributes by the given parameters.
        @volume = opts[:volume]
        # Set the time and make sure that it is in the local timezone.
        @time = opts[:time].utc? ? opts[:time].localtime : opts[:time]
        # Zero out the seconds of time.
        @time = Time.new @time.year, @time.month, @time.day, @time.hour, @time.min, 0, @time.utc_offset

        # Set the name of this snapshot.
        t = @time.strftime("%Y-%m-%d_%H:%M_%z").gsub("+", "")
        if @group.nil?
          @name = "#{@volume.name}@zsnap_#{t}"
        else
          @name = "#{@volume.name}@zsnap_#{@group}_#{t}"
        end
      end

      # Check for all necessary attributes.
      raise StandardError, "Undefined volume." if @volume.nil?
      raise StandardError, "Undefined time." if @time.nil?
      raise StandardError, "Undefined name." if @name.nil?
    end

    #
    # === Description
    #
    # Return the name of this Snapshot. The name is in the form:
    # "<VOLUME_NAME>@zsnap_%Y-%m-%d_%H:%M:%S_%z" or "<VOLUME_NAME>@zsnap_<GROUP>_%Y-%m-%d_%H:%M:%S_%z", whether the
    # group name is set or not.
    #
    # *Note:* The "+" character from the timezone information is removed, due to the fact that ZFS does not allow the
    # "+" character inside the snapshot name.
    #
    def name
      return @name
    end

    #
    # === Description
    #
    # Set the state of the snapshot by supplying a name. This method changes also the other attributes of the snapshot
    # instance to match the values from the snapshot name.
    #
    # === Args
    #
    # [+value+]
    #   The name of the Snapshot as string, in the form:
    #   * "<VOLUME_NAME>@zsnap_%Y-%m-%d_%H:%M:%S" (old format, UTC time)
    #   * "<VOLUME_NAME>@zsnap_%Y-%m-%d_%H:%M_%z" (new format, local time, timezone without "+" character)
    #   * "<VOLUME_NAME>@zsnap_<GROUP>_%Y-%m-%d_%H:%M_%z" (new format with group name, local time, timezone
    #     without "+" character)
    #
    def name=(value)
      # Helper function to check the snapshot name against a mask/template.
      check_format = proc do |mask, s_parts|
        (mask.size == s_parts.size) ? mask.zip(s_parts).map{|m, s| !!m.match(s)}.reduce(:&) : false
      end

      # Extract the Volume from the snapshot name.
      v_name = value.split("@").first
      @volume = Volume.all.find{|v| v.name == v_name}
      raise StandardError, "No matching volume found." if @volume.nil?
      
      # Extract the snapshot details from the snapshot name.
      s_parts = value.split("@")[1].split("_")
      if check_format[MASK_OLD_1, s_parts]
        # The old snapshot name format (UTC time): "zsnap_%Y-%m-%d_%H:%M:%S"
        tt = Time.strptime "#{s_parts[1]}_#{s_parts[2]}", "%Y-%m-%d_%H:%M:%S"
        @time = Time.utc(tt.year, tt.month, tt.day, tt.hour, tt.min)
      elsif check_format[MASK_V_1, s_parts]
        # The new snapshot name format, without group name (local time): "zsnap_%Y-%m-%d_%H:%M_%z"
        # There is one catch; the "+" character may occur in the "%z" flag, but ZFS does not allow this character
        # inside snapshot names, therfore we have to add it if necessary.
        s_parts[3] = "+#{s_parts[3]}" if s_parts[3] =~ /^\d{4}$/
        @time = Time.strptime "#{s_parts[1]}_#{s_parts[2]}_#{s_parts[3]}", "%Y-%m-%d_%H:%M_%z"
      elsif check_format[MASK_V_2, s_parts]
        # The new snapshot name format, with group name (local time): "zsnap_<GROUP>_%Y-%m-%d_%H:%M_%z"
        @group = s_parts[1]
        # There is one catch; the "+" character may occur in the "%z" flag, but ZFS does not allow this character
        # inside snapshot names, therfore we have to add it if necessary.
        s_parts[4] = "+#{s_parts[4]}" if s_parts[4] =~ /^\d{4}$/
        @time = Time.strptime "#{s_parts[2]}_#{s_parts[3]}_#{s_parts[4]}", "%Y-%m-%d_%H:%M_%z"
      else
        raise StandardError, "Invalid snapshot name format."
      end
      
      # If we reach this line, everything should have worked correct.
      @name = value
    end

    #
    # === Description
    #
    # Destroy this Snapshot.
    #
    # *ATTENTION*: This method deletes the snapshot from disk. This is
    # irreversible!
    #
    def destroy
      ZSnap.execute "zfs", "destroy", name
      LOG.info "Destroyed snapshot '#{name}'."
    end
  end # Snapshot

  #
  # == Description
  #
  # This class represents a ZFS Volume.
  #
  class Volume

    # The name of the Volume as string.
    attr_accessor :name

    #
    # === Description
    #
    # Create a new Snapshot on this Volume.
    #
    def create_snapshot
      ss = Snapshot.new volume: self
      ZSnap.execute "zfs", "snapshot", ss.name
      LOG.info "Created snapshot '#{ss.name}'."
      return ss
    end

    #
    # === Description
    #
    # Returns all Snapshots for this Volume in an Array. Only Snapshots created
    # by this script will be returned, all other snapshots will be ignored.
    #
    def snapshots
      result = []
      # Get all snapshots
      snapshots = ZSnap.execute("zfs", "list", "-Hpt", "snapshot").lines
      #   1.9.3: String#lines -> Enumerator
      # >=2.0.0: String#lines -> Array
      snapshots = snapshots.to_a if snapshots.is_a? Enumerator
      # Only keep snapshots of this volume.
      snapshots.select!{|ss| ss.start_with? "#{@name}@"}
      # Create Snapshot object for each line.
      snapshots.each do |line|
        name = line.split("\t").first
        begin
          result << Snapshot.new(name: name)
        rescue StandardError => e
          LOG.debug "Ignoring snapshot '#{name}'."
          next
        end
      end
      return result
    end

    #
    # === Description
    #
    # Return all Volume objects in an Array.
    #
    def self.all
      if not defined?(@@all) or @@all.nil?
        @@all = []
        ZSnap.execute("zfs", "list", "-Hp").lines.map{|l| l.split("\t").first}.each do |line|
          ds = Volume.new
          ds.name = line
          @@all << ds
        end
        LOG.debug "Found the following volumes: #{@@all.map{|v| v.name}.join(", ")}"
      end
      return @@all
    end

    #
    # === Description
    #
    # Find Volume objects by name.
    #
    # Returns an array of all Volumes object, which match the specified names.
    #
    # === Args
    #
    # [+names+]
    #   The names (as string) of the Volumes which should be found.
    #
    def self.find_by_names(*names)
      result = []
      names.each do |vs|
        volume = Volume.all.find{|v| v.name == vs}
        raise StandardError, "Volume '#{vs}' not found." if volume.nil?
        result << volume
      end
      return result
    end
  end # Volume

  #
  # === Description
  #
  # Calculate the date for which all older snapshots should be deleted.
  #
  # This method takes all arguments and calculates the date in the past, for
  # which all older snapshots should be deleted.
  #
  # The calculated date is returned as Time object.
  #
  # === Args
  #
  # [+months+]
  #   The number of months (must be >= 0).
  # [+weeks+]
  #   The number of weeks (must be >= 0).
  # [+days+]
  #   The number of days (must be >= 0).
  # [+hours+]
  #   The number of hours (must be >= 0).
  # [+minutes+]
  #   The number of minutes (must be >= 0).
  #
  def self.calc_destroy_date(months, weeks, days, hours, minutes)
    # Check all arguments >= 0
    method(__method__).parameters.map{|arg| [arg[1].to_s, (eval arg[1].to_s)]}.each do |var, val|
      raise StandardError, "Argument '#{var}' must be greater than zero." if val < 0
    end

    # Calculate destroy date, start with the current date but set seconds to zero. 
    result = Time.now
    result = Time.new result.year, result.month, result.day, result.hour, result.min, 0, result.utc_offset
    # Subtract number of months.
    if months > 0
      # Calculate new month.
      nm = (result.month - months - 1) % 12 + 1
      # Calculate new year.
      ny = result.year + ((result.month - months - 1) / 12)
      
      # In some cases it is possible that the calculated date is not valid,
      # e. g. when subtracting one month from 2015-03-31, which would result in
      # the date 2015-02-31. Furthermore Time.new accepts those values but
      # creates the date 2015-03-03. To comprehend this effect it is necessary
      # to reduce the days until we are at the last day of this month.
      nd = result.day
      nd -= 1 until (tmp = Time.new(ny, nm, nd, result.hour, result.min, result.sec, result.utc_offset)).month == nm
      result = tmp
    end
      
    # Subtract weeks, days, hours and minutes.
    result -= weeks * 7 * 24 * 60 * 60
    result -= days * 24 * 60 * 60
    result -= hours * 60 * 60
    result -= minutes * 60
    return result
  end

  #
  # === Description
  #
  # Execute a command in a shell.
  #
  # This method executes the given command in a shell and returns the shell
  # output as string.
  #
  # === Args
  #
  # [+args+]
  #   The command and all arguments which should be execute in a shell.
  #
  # === Example
  #
  #   ZSnap.execute("echo", "Hello World.")
  #
  def self.execute(*args)
    output = ""
    begin
      IO.popen(args){|p| output = p.read}
      success = $?.success?
    rescue StandardError => e
      success = false
      output = e.message
    end

    unless success
      raise StandardError, "Unable to execute command '#{args.join " "}':\n#{output}"
    end
    return output
  end

  #
  # === Description
  #
  # Parse commandline arguments.
  #
  # Returns a hash with the following values:
  #
  # [+create+]
  #   This value is true if the "-c" flag was specified on the commandline,
  #   otherwise false.
  # [+minutes+]
  #   The value of the "-M" flag. This is always an integer >= 0 (default = 0).
  # [+hours+]
  #   The value of the "-H" flag. This is always an integer >= 0 (default = 0).
  # [+days+]
  #   The value of the "-d" flag. This is always an integer >= 0 (default = 0).
  # [+weeks+]
  #   The value of the "-w" flag. This is always an integer >= 0 (default = 0).
  # [+months+]
  #   The value of the "-m" flag. This is always an integer >= 0 (default = 0).
  # [+help+]
  #   This value is true if the help text was printed while parsing the
  #   commandline arguments, either because the "-h" flag was used or because
  #   an error occurred.
  # [+volumes+]
  #   An array of the names of all specified Volumes (default = []).
  #
  def self.get_options
    # Default values for command line arguments:
    options = {create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []}

    # Parser for command line and help text.
    op = OptionParser.new do |opts|
      # Block to handle options which need an Integer as argument.
      handler_int = proc do |opt_name, n|
        if not n.nil? and n > 0
          options[opt_name] = n
        else
          raise OptionParser::InvalidArgument, "- Argument must be a positive integer."
        end
      end
      
      opts.banner = "Usage: #{$0} [OPTION]... [VOLUME]..."
      opts.separator "Automatically create and destroy snapshots for ZFS VOLUME(s)."
      opts.separator ""
      opts.separator "The options -M, -H, -d, -w or -m are used to specify which snapshots should"
      opts.separator "be destroyed. It is possible to combine those options, e. g. '-w 2 -H 12'"
      opts.separator "would delete all snapshots which are older than two weeks and twelve hours. If"
      opts.separator "none of those options are used, no snapshot will be destroyed. Furthermore"
      opts.separator "only snapshots created by this script will be deleted, all other snapshots"
      opts.separator "remain untouched."
      opts.separator ""
      opts.separator "All choosen operations are only applied to the specified volumes. Those"
      opts.separator "volumes must be ZFS volumes and if no volumes are specified, the operation is"
      opts.separator "done on ALL available volumes."
      opts.separator ""
      opts.separator "Note: This script is intended to be used in a cronjob. E. g. to make a snapshot"
      opts.separator "every full hour and keep the snapshots of the last two weeks, add this line to"
      opts.separator "your '/etc/crontab' file:"
      opts.separator "    0 * * * *  root  #{$0} -c -w 2"
      opts.separator ""
      opts.separator "Options:"
      opts.separator ""
      opts.on("-c", "--create", "Create a snapshot for all specified VOLUME(s)."){|v| options[:create] = v}
      opts.on("-M", "--minutes [NUMBER]", Integer, "Destroy every snapshot which is older than NUMBER of minutes,",
              "for all specified VOLUME(s).", &handler_int.curry[:minutes])
      opts.on("-H", "--hours [NUMBER]", Integer, "Destroy every snapshot which is older than NUMBER of hours,",
              "for all specified VOLUME(s).", &handler_int.curry[:hours])
      opts.on("-d", "--days [NUMBER]", Integer, "Destroy every snapshot which is older than NUMBER of days,",
              "for all specified VOLUME(s).", &handler_int.curry[:days])
      opts.on("-w", "--weeks [NUMBER]", Integer, "Destroy every snapshot which is older than NUMBER of weeks,",
              "for all specified VOLUME(s).", &handler_int.curry[:weeks])
      opts.on("-m", "--months [NUMBER]", Integer, "Destroy every snapshot which is older than NUMBER of months,",
              "for all specified VOLUME(s).", &handler_int.curry[:months])
      opts.on("-h", "--help", "Show this message."){|v| options[:help] = v; puts opts.help}
      opts.on("-v", "Be verbose."){|v| LOG.level = Logger::DEBUG if v}
      opts.separator ""
      opts.separator "Examples:"
      opts.separator ""
      opts.separator " - #{$0} -c"
      opts.separator "   Create a new snapshot for all volumes."
      opts.separator ""
      opts.separator " - #{$0} -c -w 8 tank"
      opts.separator "   Create a new snapshot and destroy all snapshots which are older than eight"
      opts.separator "   weeks, for volume 'tank'."
      opts.separator ""
      opts.separator " - #{$0} -m 1 -w 2"
      opts.separator "   Destroy all snapshots which are older than one month and two weeks."
      opts.separator ""
    end

    unless ARGV.empty?
      begin
        # Parse cmdline arguments.
        op.parse!(ARGV)
        options[:volumes] = ARGV.dup
      rescue OptionParser::InvalidArgument => e
        # This happens if a wrong cmdline argument was specified.
        options[:help] = true
        puts op.help
        LOG.error e.message
      end
    else
      # If no cmdline arguments are used, print the help message.
      options[:help] = true
      puts op.help
    end
    
    return options
  end

  #
  # === Description
  #
  # The entrypoint of this script.
  #
  def self.main
    begin
      # Get cmdline options.
      options = ZSnap.get_options

      # If the help dialog was printed, it is assumed that no further action should be performed.
      unless options[:help]
        # Get the select volumes or all volumes, if no volume was specified.
        volumes = (options[:volumes].empty?) ? Volume.all : Volume.find_by_names(*options[:volumes])
        LOG.debug "Using the following volumes: #{volumes.map{|v| v.name}.join(", ")}"

        # Create a snapshot for each volume.
        volumes.each{|v| v.create_snapshot} if options[:create]

        # Destroy snapshots which are older as a specific date.
        destroy_values = [options[:months], options[:weeks], options[:days], options[:hours], options[:minutes]]
        if destroy_values.reduce(:+) > 0
          destroy_before = calc_destroy_date *destroy_values
          # Delete all snapshots, for all specified volumes which are older than "destroy_before".
          volumes.each{|v| v.snapshots.select{|s| s.time < destroy_before}.each{|s| s.destroy}}
        end
      end
    rescue StandardError => e
      LOG.error e.message
      LOG.debug e.backtrace.join "\n"
    end
  end
end


# Call ZSnap.main if this script was called directly.
ZSnap.main if __FILE__ == $0

