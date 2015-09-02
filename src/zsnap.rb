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
require "observer"
require "set"
require "time"

# The logger which is used throughout this project.
LOG = Logger.new STDOUT
# Default log level.
LOG.level = Logger::WARN

# Global flag to signal if the current excution of the script is for simulation purposes only.
$simulate = false

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

    include Observable

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
    # The name of the snapshot which is used by ZFS.
    # Returns a String object.
    attr_reader :name
    # The time at wich this snapshot was created.
    # Returns a Time object.
    attr_reader :time

    #
    # === Description
    #
    # Create a new instance.
    #
    # === Args
    #
    # [+opts+]
    #   Option hash.
    #
    # +opts+ accepts the following symbols to initialize a Snapshot object:
    #
    # [+:group+]
    #   The group to which this snapshot belongs.
    # [+:name+]
    #   The name of the snapshot, as it is used by ZFS (default = nil = create an apropriate name).
    # [+:time+]
    #   The time (as Time object) when this snapshot was created (default = Time.now).
    #
    def initialize(opts = {})
      # Default arguments:
      opts = {name: nil, group: nil, time: Time.now}.merge opts

      # Set attributes.
      @group = opts[:group] if opts[:group].is_a? Group
      @time = opts[:time] if opts[:time].is_a? Time
      raise StandardError, "Undefined group." if @group.nil?
      raise StandardError, "Undefined time." if @time.nil?

      # Set seconds of @time to zero:
      if @time.utc?
        @time = Time.utc @time.year, @time.month, @time.day, @time.hour, @time.min, 0
      else
        @time = Time.new @time.year, @time.month, @time.day, @time.hour, @time.min, 0, @time.utc_offset
      end

      # Set snapshot name.
      if opts[:name].nil?
        t = @time.strftime("%Y-%m-%d_%H:%M_%z").gsub("+", "")
        sp = "#{@group.volume.name}@zsnap_"
        @name = @group.name.nil? ? "#{sp}#{t}" : "#{sp}#{@group.name}_#{t}"
      else
        @name = opts[:name]
      end
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
      if $simulate
        LOG.info "Would have destroyed snapshot '#{name}'."
      else
        ZSnap.execute "zfs", "destroy", name
        LOG.info "Destroyed snapshot '#{name}'."
      end

      # Notify observers.
      changed
      notify_observers :destroy, self
    end
  end # Snapshot

  #
  # == Description
  #
  # This class represents a group of snapshots.
  #
  class Group

    # The name of this group.
    attr_reader :name
    # The volume to which this group belongs.
    attr_reader :volume

    #
    # === Description
    #
    # Create a new instance.
    #
    # === Args
    #
    # [+name+]
    #   The name of this group.
    # [+volume+]
    #   The volume to which this group belongs.
    #
    def initialize(name, volume)
      if name.nil? or name =~ Snapshot::GROUP_FORMAT
        @name = name
      else
        raise StandardError, "The group name must only contain alphabetic, numeric or the minus character."
      end
      
      if volume.is_a? ZSnap::Volume
        @volume = volume
      else
        raise StandardError, "Invalid volume."
      end

      @snapshots = Set.new
    end 

    # 
    # === Description
    #
    # Add a new snapshot to this group without creating it on the ZFS filesystem.
    #
    # === Args
    #
    # [+s+]
    #   The Snapshot which should be added to this group. The snapshot is not created on the filesystem.
    #
    def add_snapshot(s)
      if s.is_a? ZSnap::Snapshot
        s.add_observer self
        @snapshots << s
        LOG.debug do
          "Added Snapshot '#{s.name}' to #{@name.nil? ? "default Group" : "Group '#{@name}'"} " +
            "for Volume '#{@volume.name}'."
        end
      else
        raise StandardError, "Argument is not a Snapshot."
      end
    end

    #
    # === Description
    #
    # Create a new snapshot for this group. This also creates the snapshot for the ZFS volume.
    # 
    # This method returns the newly created snapshot.
    #
    def create_snapshot
      s = Snapshot.new group: self
      add_snapshot s
      if $simulate
        LOG.info "Would have created snapshot '#{s.name}'."
      else
        ZSnap.execute "zfs", "snapshot", s.name
        LOG.info "Created snapshot '#{s.name}'."
      end
      return s
    end

    #
    # === Description
    #
    # Return all snapshots of this group in an array.
    #
    def snapshots
      return @snapshots.to_a
    end

    #
    # === Description
    #
    # This method gets called if an observed object changes.
    #
    # === Args
    #
    # [+action+]
    #   A symbol which describes what happened (currently only :destroy).
    # [+snapshot+]
    #   The object which changed.
    #
    def update(action, snapshot)
      if action == :destroy
        snapshot.delete_observer self
        @snapshots.delete snapshot
        LOG.debug "Removed snapshot '#{snapshot.name}' from group '#{name}'."
      end
    end
  end # Group

  #
  # == Description
  #
  # This class represents a ZFS Volume.
  #
  class Volume

    # The name of the Volume as string.
    attr_reader :name

    #
    # === Description
    #
    # Create a new instance.
    #
    # === Args
    #
    # [+name+]
    #   The name of this Volume.
    #
    def initialize(name)
      raise StandardError, "Volume name must not be empty or nil." if name.nil? or name.empty?
      @name = name
      @groups = {}
      # Create default Group.
      @groups[nil] = Group.new nil, self
    end

    #
    # === Description
    #
    # Return the default Group for this Volume.
    #
    def get_default_group
      return get_group(nil)
    end

    #
    # === Description
    #
    # Get a specific Group by its name.
    #
    # This method returns the Group with the specified name. If the Group does not exist, it will be created.
    #
    # === Args
    #
    # [+name+]
    #   The name of the Group.
    #
    def get_group(g_name)
      unless @groups.has_key?(g_name)
        @groups[g_name] = Group.new(g_name, self)
        LOG.debug{"Added group '#{g_name}' to Volume '#{@name}'."}
      end
      return @groups[g_name]
    end

    #
    # === Description
    #
    # Return all Groups for this Volume.
    #
    def groups
      return @groups.values
    end

    #
    # === Description
    #
    # Return all Volume objects in a hash (key = Volume name; value = Volume object).
    #
    def self.all
      # Only parse the commandline once.
      @@all = create_data(read_volumes, read_snapshots) if not defined?(@@all) or @@all.nil?
      # Return @@all if already defined.
      return @@all
    end

    #
    # === Description
    #
    # Create all data objects.
    #
    # This method creates all data objects (Volume, Group, Snapshot), by using the information from #read_volumes and
    # #read_snapshots. The returned value is an hash containing all Volume names (key) and Volumes objects (values),
    # all other objects are referenced by the returned Volumes.
    #
    # === Args
    #
    # [+v_info+]
    #   An array of hashes containing the Volume information, returned by the method #read_volumes.
    # [+s_info+]
    #   An array of hashes containing the Snapshot information, returned by the method #read_snapshots.
    #
    def self.create_data(v_info, s_info)
      # Create all Volumes
      volumes = {}
      v_info.each{|i| volumes[i[:name]] = ZSnap::Volume.new i[:name]}

      volumes.each do |k, v|
        # All snapshot information for Volume v.
        sv = s_info.select{|i| i[:volume_name] == v.name}

        # Create all Snapshots for each Group.
        sv.each do |i|
          g = i[:group_name].nil? ? v.get_default_group : v.get_group(i[:group_name])
          n = i[:name]
          t = i[:snapshot_time]
          g.add_snapshot ZSnap::Snapshot.new(group: g, name: n, time: t)
        end
      end
      return volumes
    end

    #
    # === Description
    #
    # Parse the snapshot name and return the details inside a hash. The returned hash contains the following values:
    #
    # [+:name+]
    #   The name of the Snapshot, as it is referenced by ZFS.
    # [+:volume_name+]
    #   The name of the Volume.
    # [+:group_name+]
    #   The name of the Group this snapshot is in, or nil if this Snapshot is in no Group (or default Group).
    # [+:snapshot_time+]
    #   The time when this Snapshot was taken.
    #
    def self.parse_snapshot_name(sname)
      # Helper function to check the snapshot name against a mask/template.
      check_format = proc do |mask, s_parts|
        (mask.size == s_parts.size) ? mask.zip(s_parts).map{|m, s| !!m.match(s)}.reduce(:&) : false
      end

      result = {name: sname, volume_name: nil, group_name: nil, snapshot_time: nil}

      # Extract the volume name from the snapshot name.
      v_name = sname.split("@").first
      result[:volume_name] = v_name

      # Extract the snapshot details from the snapshot name.
      s_parts = sname.split("@")[1].split("_")
      if check_format[Snapshot::MASK_OLD_1, s_parts]
        # The old snapshot name format (UTC time): "zsnap_%Y-%m-%d_%H:%M:%S"
        tt = Time.strptime "#{s_parts[1]}_#{s_parts[2]}", "%Y-%m-%d_%H:%M:%S"
        result[:snapshot_time] = Time.utc(tt.year, tt.month, tt.day, tt.hour, tt.min)
      elsif check_format[Snapshot::MASK_V_1, s_parts]
        # The new snapshot name format, without group name (local time): "zsnap_%Y-%m-%d_%H:%M_%z"
        # There is one catch; the "+" character may occur in the "%z" flag, but ZFS does not allow this character
        # inside snapshot names, therfore we have to add it if necessary.
        s_parts[3] = "+#{s_parts[3]}" if s_parts[3] =~ /^\d{4}$/
        result[:snapshot_time] = Time.strptime "#{s_parts[1]}_#{s_parts[2]}_#{s_parts[3]}", "%Y-%m-%d_%H:%M_%z"
      elsif check_format[Snapshot::MASK_V_2, s_parts]
        # The new snapshot name format, with group name (local time): "zsnap_<GROUP>_%Y-%m-%d_%H:%M_%z"
        result[:group_name] = s_parts[1]
        # There is one catch; the "+" character may occur in the "%z" flag, but ZFS does not allow this character
        # inside snapshot names, therfore we have to add it if necessary.
        s_parts[4] = "+#{s_parts[4]}" if s_parts[4] =~ /^\d{4}$/
        result[:snapshot_time] = Time.strptime "#{s_parts[2]}_#{s_parts[3]}_#{s_parts[4]}", "%Y-%m-%d_%H:%M_%z"
      else
        raise StandardError, "Invalid snapshot name format."
      end
      return result
    end

    #
    # === Description
    #
    # Read all ZSnap Snapshot informtion from ZFS and return them as hashes inside an array.
    # 
    # For information of the returned hashes see method #parse_snapshot_name
    #
    def self.read_snapshots
      # Parse Groups/Snapshots.
      result = []
      # Get all snapshot information from ZFS.
      eout = ZSnap.execute("zfs", "list", "-Hpt", "snapshot").lines
      #   1.9.3: String#lines -> Enumerator
      # >=2.0.0: String#lines -> Array
      eout = eout.to_a if eout.is_a? Enumerator
      # Only keep snapshots created by ZSnap.
      eout.select!{|ss| ss =~ /^[^@]+@zsnap/}
      # Parse all snapshot names and store the snapshot metainformation inside the array result.
      eout.each do |line|
        name = line.split("\t").first
        begin
          result << Volume.parse_snapshot_name(name)
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
    # Read all Volume information from ZFS and return them as hashes inside an array. Each hash has the following
    # values:
    #
    # [+:name+]
    #   The name of the Volume.
    #
    def self.read_volumes
      result = []
      ZSnap.execute("zfs", "list", "-Hp").lines.map{|l| l.split("\t").first}.each do |line|
        info = {}
        info[:name] = line
        result << info
      end
      LOG.debug "Found the following volumes: #{result.map{|v| v[:name]}.join(", ")}"
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
  # [+group+]
  #   The name of the group as string on which all create/destroy operations
  #   should be done or nil if no group was specified.
  # [+keep+]
  #   The value of the "-k" flag. This is always an integer >= 0 (default = 0).
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
    options = {create: false, group: nil, keep: 0, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []}

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
      opts.separator "Options:"
      opts.separator ""
      opts.on("-c", "--create", "Create a snapshot for all specified", "VOLUME(s)."){|v| options[:create] = v}
      opts.on("-g", "--group [NAME]", String, "Specify the group on which all operations",
              "(delete/destroy) should be performed. The", "group will be created if it does not",
              "already exist.") do |s|
        if s =~ Snapshot::GROUP_FORMAT
          options[:group] = s
        else
          raise OptionParser::InvalidArgument, "- Must only contain alphanumeric characters and the minus sign."
        end
      end
      opts.separator ""
      opts.on("-k", "--keep [NUMBER]", Integer, "Keep NUMBER of newest snapshots and",
              "destroy older snapshots, for all specified", "VOLUME(s).", &handler_int.curry[:keep])
      opts.separator ""
      opts.on("-M", "--minutes [NUMBER]", Integer, "Destroy every snapshot which is older",
              "than NUMBER of minutes, for all specified", "VOLUME(s).", &handler_int.curry[:minutes])
      opts.on("-H", "--hours [NUMBER]", Integer, "Destroy every snapshot which is older",
              "than NUMBER of hours, for all specified", "VOLUME(s).", &handler_int.curry[:hours])
      opts.on("-d", "--days [NUMBER]", Integer, "Destroy every snapshot which is older",
              "than NUMBER of days, for all specified", "VOLUME(s).", &handler_int.curry[:days])
      opts.on("-w", "--weeks [NUMBER]", Integer, "Destroy every snapshot which is older",
              "than NUMBER of weeks, for all specified", "VOLUME(s).", &handler_int.curry[:weeks])
      opts.on("-m", "--months [NUMBER]", Integer, "Destroy every snapshot which is older",
              "than NUMBER of months, for all specified", "VOLUME(s).", &handler_int.curry[:months])
      opts.separator ""
      opts.on("-s", "--simulate", "Do not create/destroy snapshots, instead",
              "print what would have happened.") do |v|
        if v
          LOG.level = Logger::INFO unless LOG.debug?
          $simulate = true
        end
      end
      opts.separator ""
      opts.on("--debug", "Show debug messages."){|v| LOG.level = Logger::DEBUG if v}
      opts.on("-h", "--help", "Show this message."){|v| options[:help] = v; puts opts.help}
      opts.on("-v", "Be verbose."){|v| LOG.level = Logger::INFO if v and not LOG.debug?}
      opts.separator ""
      opts.separator "All create/destroy operations are only applied to the specified group for"
      opts.separator "all specified volumes. Each volume must be ZFS a volume and if no volumes"
      opts.separator "are specified, the operation is done on ALL available volumes."
      opts.separator ""
      opts.separator "A group is a way to organize snapshots on each volume. If no group is"
      opts.separator "specified, the default group is used. The default group has no name. It is"
      opts.separator "important to note that omitting the group does NOT apply the choosen operations"
      opts.separator "on all groups, but the default group. By using groups it is possible to"
      opts.separator "use multiple create/destroy schedules on each volume (e. g. hourly, daily,"
      opts.separator "weekly, ...)."
      opts.separator ""
      opts.separator "All created snapshots are named in the following manner:"
      opts.separator "    VOLUME@zsnap_GROUP_yyyy-mm-dd_HH:MM_tz"
      opts.separator "e. g."
      opts.separator "    tank@zsnap_daily_2000-12-25_14:35_0500"
      opts.separator ""
      opts.separator "The options -M, -H, -d, -w or -m are used to specify which snapshots should"
      opts.separator "be destroyed by elapsed time. It is possible to combine those options,"
      opts.separator "e. g. '-w 2 -H 12' would delete all snapshots which are older than two weeks"
      opts.separator "and twelve hours. If none of those options are used, no snapshot will be"
      opts.separator "destroyed. Furthermore only snapshots created by this script will be deleted,"
      opts.separator "all other snapshots remain untouched."
      opts.separator ""
      opts.separator "The option -k is used to specify how many snapshots for each group should be"
      opts.separator "kept. All remaining older snapshots are destroyed. The option -k is mutual"
      opts.separator "exclusive to -M, -H, -d, -w and -m."
      opts.separator ""
      opts.separator "Note: This script is intended to be used in a cronjob. E. g. to make a"
      opts.separator "snapshot every full hour and keep the snapshots of the last two weeks,"
      opts.separator "add this line to your '/etc/crontab' file:"
      opts.separator "    0 * * * *  root  #{$0} -c -w 2"
      opts.separator ""
      opts.separator "Examples:"
      opts.separator ""
      opts.separator " - #{$0} -c"
      opts.separator "   Create a new snapshot for all volumes."
      opts.separator ""
      opts.separator " - #{$0} -c -w 8 -g daily tank"
      opts.separator "   Create a new snapshot and destroy all snapshots which are older than eight"
      opts.separator "   weeks, for group 'daily' on volume 'tank'."
      opts.separator ""
      opts.separator " - #{$0} -m 1 -w 2"
      opts.separator "   Destroy all snapshots which are older than one month and two weeks."
      opts.separator ""
      opts.separator " - #{$0} -g daily -k 24"
      opts.separator "   Destroy all snapshots except the last 24 on the group 'daily' for all"
      opts.separator "   volumes."
      opts.separator ""
    end

    unless ARGV.empty?
      begin
        # Parse cmdline arguments.
        op.parse!(ARGV)
        options[:volumes] = ARGV.dup

        if options[:keep] > 0 and [:minutes, :hours, :days, :weeks, :months].map{|v| options[v]}.reduce(:+) > 0
          [:keep, :minutes, :hours, :days, :weeks, :months].each{|v| options[v] = 0}
          em = "- The option -k is mutual exclusive to the options -M, -H, -d, -w and -m." 
          raise OptionParser::InvalidArgument, em 
        end
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
        # Check if all Volumes are existing.
        uv = options[:volumes] - Volume.all.keys
        raise StandardError, "Unknown volumes: #{uv.map{|v| "'#{v}'"}.join(", ")}" unless uv.empty?

        # Get the selected volumes or all volumes, if no volume was specified.
        volumes = (options[:volumes].empty?) ? Volume.all : Volume.all.select{|k, v| options[:volumes].include?(v.name)}
        LOG.debug "Using the following volumes: #{volumes.keys.join(", ")}"

        # Get the specific group for each volume.
        groups = options[:group].nil? ? volumes.values.map{|v| v.get_default_group} :
          volumes.values.map{|v| v.get_group(options[:group])}

        # Create a snapshot for each group.
        groups.each{|g| g.create_snapshot} if options[:create]

        destroy_values = [options[:months], options[:weeks], options[:days], options[:hours], options[:minutes]]
        if destroy_values.reduce(:+) > 0
          # Destroy snapshots which are older as a specific date.
          destroy_before = calc_destroy_date *destroy_values
          # Delete all snapshots, for all specified volumes which are older than "destroy_before".
          groups.each{|g| g.snapshots.select{|s| s.time < destroy_before}.each{|s| s.destroy}}
        elsif options[:keep] > 0
          # Keep only the specified number of snapshots for each group and delete the rest.
          groups.each{|g| g.snapshots.sort_by{|s| s.time}.reverse.drop(options[:keep]).each{|s| s.destroy}}
        end
      end
    rescue StandardError => e
      LOG.error e.message
      LOG.debug e.backtrace.join "\n"
      raise if $test_running # Let this exception raise. This is needed for testing.
    end
  end
end


# Call ZSnap.main if this script was called directly.
ZSnap.main if __FILE__ == $0

