
require_relative "init_test"
require "minitest/mock"


describe "ZSnap" do

  it "must calculate destroy date" do
    start_date = Time.new 2010, 6, 15, 12, 30, 10, "+01:00"
    Time.stub(:now, start_date) do
      ZSnap.calc_destroy_date(0, 0, 0, 0, 0).must_equal   Time.new 2010,  6, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(0, 0, 0, 0, 1).must_equal   Time.new 2010,  6, 15, 12, 29, 0, "+01:00"
      ZSnap.calc_destroy_date(0, 0, 0, 0, 121).must_equal Time.new 2010,  6, 15, 10, 29, 0, "+01:00"
      ZSnap.calc_destroy_date(0, 0, 0, 1, 0).must_equal   Time.new 2010,  6, 15, 11, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(0, 0, 0, 49, 0).must_equal  Time.new 2010,  6, 13, 11, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(0, 0, 1, 0, 0).must_equal   Time.new 2010,  6, 14, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(0, 0, 15, 0, 0).must_equal  Time.new 2010,  5, 31, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(0, 1, 0, 0, 0).must_equal   Time.new 2010,  6,  8, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(0, 6, 0, 0, 0).must_equal   Time.new 2010,  5,  4, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(1, 0, 0, 0, 0).must_equal   Time.new 2010,  5, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(2, 0, 0, 0, 0).must_equal   Time.new 2010,  4, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(3, 0, 0, 0, 0).must_equal   Time.new 2010,  3, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(4, 0, 0, 0, 0).must_equal   Time.new 2010,  2, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(5, 0, 0, 0, 0).must_equal   Time.new 2010,  1, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(6, 0, 0, 0, 0).must_equal   Time.new 2009, 12, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(7, 0, 0, 0, 0).must_equal   Time.new 2009, 11, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(8, 0, 0, 0, 0).must_equal   Time.new 2009, 10, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(9, 0, 0, 0, 0).must_equal   Time.new 2009,  9, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(10, 0, 0, 0, 0).must_equal  Time.new 2009,  8, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(11, 0, 0, 0, 0).must_equal  Time.new 2009,  7, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(12, 0, 0, 0, 0).must_equal  Time.new 2009,  6, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(13, 0, 0, 0, 0).must_equal  Time.new 2009,  5, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(23, 0, 0, 0, 0).must_equal  Time.new 2008,  7, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(24, 0, 0, 0, 0).must_equal  Time.new 2008,  6, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(25, 0, 0, 0, 0).must_equal  Time.new 2008,  5, 15, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(1, 1, 1, 1, 1).must_equal   Time.new 2010,  5,  7, 11, 29, 0, "+01:00"
      ZSnap.calc_destroy_date(2, 3, 4, 5, 6).must_equal   Time.new 2010,  3, 21,  7, 24, 0, "+01:00"
      proc {ZSnap.calc_destroy_date(0, 0, 0, 0, -1)}.must_raise StandardError
      proc {ZSnap.calc_destroy_date(0, 0, 0, -1, 0)}.must_raise StandardError
      proc {ZSnap.calc_destroy_date(0, 0, -1, 0, 0)}.must_raise StandardError
      proc {ZSnap.calc_destroy_date(0, -1, 0, 0, 0)}.must_raise StandardError
      proc {ZSnap.calc_destroy_date(-1, 0, 0, 0, 0)}.must_raise StandardError
    end

    start_date = Time.new 2010, 3, 31, 12, 30, 10, "+01:00"
    Time.stub(:now, start_date) do
      ZSnap.calc_destroy_date(1, 0, 0, 0, 0).must_equal Time.new 2010, 2, 28, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(2, 0, 0, 0, 0).must_equal Time.new 2010, 1, 31, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(3, 0, 0, 0, 0).must_equal Time.new 2009, 12, 31, 12, 30, 0, "+01:00"
      ZSnap.calc_destroy_date(4, 0, 0, 0, 0).must_equal Time.new 2009, 11, 30, 12, 30, 0, "+01:00"
    end
  end

  it "must execute commands on the cmdline" do
    ZSnap.execute("echo", "Hello World!").strip.must_equal "Hello World!"
    proc {ZSnap.execute("iamnothere", "-a", "-b")}.must_raise StandardError
  end

  it "must parse command line arguments" do
    stdout_old = $stdout
    argv_old = ARGV
    loglevel_old = LOG.level

    begin
      # Redirect stdout to /dev/null for this test.
      $stdout = File.new "/dev/null", "w"
      
      ARGV.replace []
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-h"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-c"]
      ZSnap.get_options.must_equal({create: true, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []})
      ARGV.replace ["-g", "foo"]
      ZSnap.get_options.must_equal({create: false, group: "foo", minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []})
      ARGV.replace ["-g", ""]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-g", "foo_bar"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-M", "10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 10, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []})
      ARGV.replace ["-M", "-10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-M", "abc"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-H", "10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 10, days: 0, weeks: 0, months: 0, help: false, volumes: []})
      ARGV.replace ["-H", "-10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-H", "abc"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-d", "10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 10, weeks: 0, months: 0, help: false, volumes: []})
      ARGV.replace ["-d", "-10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-d", "abc"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-w", "10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 10, months: 0, help: false, volumes: []})
      ARGV.replace ["-w", "-10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-w", "abc"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-m", "10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 10, help: false, volumes: []})
      ARGV.replace ["-m", "-10"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-m", "abc"]
      ZSnap.get_options.must_equal({create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-c", "-g", "bar", "-M", "1", "-H", "2", "-d", "3", "-w", "4", "-m", "5", "old", "mc", "donald"]
      ZSnap.get_options.must_equal({create: true, group: "bar", minutes: 1, hours: 2, days: 3, weeks: 4, months: 5, help: false, volumes: ["old", "mc", "donald"]})
      ARGV.replace ["-s"]
      ZSnap.get_options
      $simulate.must_equal true
      LOG.level.must_equal Logger::INFO
      $simulate = false
      LOG.level = Logger::UNKNOWN
      ARGV.replace ["-v"]
      ZSnap.get_options
      LOG.level.must_equal Logger::INFO
      LOG.level = Logger::UNKNOWN
      ARGV.replace ["--debug"]
      ZSnap.get_options
      LOG.level.must_equal Logger::DEBUG
      LOG.level = Logger::UNKNOWN
    ensure
      # Restore stdout.
      $stdout.close
      $stdout = stdout_old

      # Restore ARGV.
      ARGV.replace argv_old

      # Restore log level.
      LOG.level = loglevel_old
    end
  end

  it "must process comandline arguments and take actions accordingly" do
    # Start date for testing.
    ct = Time.new(2000, 10, 30, 1, 2, 0, "+05:00")

    # Helper function to create test data and run testcases.
    run_test = lambda do |opts, *vs|
      # opts = hash of options which should be returned by ZSnap.get_options.
      # vs is of the form:
      # [{vn: "Volume.name", groups: [{gn: "Group.name", create: bool, snap_count: n, destroy: time/nil}, ...]}, ...]
      
      # Hash to store the Group which #create_snapshot method must be called.
      # Key = Group, Value = bool (true if it was called, otherwise false).
      must_call_create = {}
      # Hash to store the Snapshot which #destroy method must be called.
      # Key = Snapshot, Value = bool (true if it was called, otherwise false).
      must_call_destroy = {}

      # Create v_info and s_info array to generate data structures.
      v_info = vs.map{|v| {name: v[:vn]}}
      s_info = []
      vs.each do |v|
        v[:groups].each do |g|
          1.upto(g[:snap_count]) do |i|
            t = (ct - (i * 24 * 60 * 60)).strftime("%Y-%m-%d_%H:%M_%z").gsub("+", "")
            s_name = g[:gn].nil? ? "#{v[:vn]}@zsnap_#{t}" : "#{v[:vn]}@zsnap_#{g[:gn]}_#{t}" 
            s_info << ZSnap::Volume.parse_snapshot_name(s_name)
          end
        end
      end

      # Replace ZSnap::Group#create_snapshot and ZSnap::Snapshot#destroy with stubs.
      ZSnap::Group.class_exec do
        alias orig_create_snapshot create_snapshot
        def create_snapshot
          raise TestError, "Method must not be called on '#{name}'."
        end
      end
      ZSnap::Snapshot.class_exec do
        alias orig_destroy destroy
        def destroy
          raise TestError, "Method must not be called for '#{name}'."
        end
      end

      begin
        # Create the data structures by using ZSnap.
        volumes = ZSnap::Volume.create_data(v_info, s_info)

        vs.each do |v|
          vol = volumes[v[:vn]]
          v[:groups].each do |g|
            gro = vol.get_group(g[:gn])

            # Stub every Group#create_snapshot which must be called.
            if g[:create]
              must_call_create[gro] = false
              gro.instance_variable_set :@must_call_create, must_call_create
              def gro.create_snapshot; @must_call_create[self] = true; end
            end

            # Stub every Snapshot#destroy wich must be called.
            unless g[:destroy].nil?
              gro.snapshots.select{|s| s.time < g[:destroy]}.each do |s|
                must_call_destroy[s] = false
                s.instance_variable_set :@must_call_destroy, must_call_destroy
                def s.destroy; @must_call_destroy[self] = true; end
              end
            end
          end
        end

        # Run the testcase with the created data structures.
        Time.stub(:new, ct) do
          ZSnap::Volume.stub(:all, volumes) do
            ZSnap.stub(:get_options, opts) do
              ZSnap.main
              must_call_create.values.reduce(:&).must_equal true unless must_call_create.empty?
              must_call_destroy.values.reduce(:&).must_equal true unless must_call_destroy.empty?
            end
          end
        end
      ensure
        # Restore old ZSnap::Group#create_snapshot and ZSnap::Snapshot#destroy methods.
        ZSnap::Group.class_exec do
          alias create_snapshot orig_create_snapshot
          remove_method :orig_create_snapshot
        end
        ZSnap::Snapshot.class_exec do
          alias destroy orig_destroy
          remove_method :orig_destroy
        end
      end
    end

    # Test case: create snapshot for only specified volumes.
    run_test[{create: true, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: ["red", "green"]},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: true,  destroy: nil},
                                    {gn: "orange", snap_count: 10, create: false, destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: true,  destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil}]}]

    # Test case: create snapshot for only specified volumes with group orange.
    run_test[{create: true, group: "orange", minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: ["red", "green"]},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count: 10, create: true,  destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count:  0, create: true,  destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil}]}]

    # Test case: create snapshot for all volumes.
    run_test[{create: true, group: nil, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: true,  destroy: nil},
                                    {gn: "orange", snap_count: 10, create: false, destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: true,  destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: true,  destroy: nil}]}]

    # Test case: create snapshot for all volumes with group orange.
    run_test[{create: true, group: "orange", minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count: 10, create: true,  destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count:  0, create: true,  destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil},
                                    {gn: "orange", snap_count:  0, create: true,  destroy: nil}]}]
    
    # Test case: delete snapshots for only specified volumes.
    dt = ct - (2 * 7 * 24 * 60 * 60)
    run_test[{create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 2, months: 0, help: false, volumes: ["red"]},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: dt},
                                    {gn: "orange", snap_count: 10, create: false, destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil}]}]

    # Test case: delete snapshots for only specified volumes with group orange.
    dt = ct - (1 * 7 * 24 * 60 * 60)
    run_test[{create: false, group: "orange", minutes: 0, hours: 0, days: 0, weeks: 1, months: 0, help: false, volumes: ["red"]},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count: 10, create: false, destroy: dt},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil}]}]
    
    # Test case: delete snapshots for all volumes.
    dt = ct - (2 * 7 * 24 * 60 * 60)
    run_test[{create: false, group: nil, minutes: 0, hours: 0, days: 0, weeks: 2, months: 0, help: false, volumes: []},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: dt},
                                    {gn: "orange", snap_count: 10, create: false, destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: dt}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil}]}]
    
    # Test case: delete snapshots for all volumes with group orange.
    dt = ct - (1 * 7 * 24 * 60 * 60)
    run_test[{create: false, group: "orange", minutes: 0, hours: 0, days: 0, weeks: 1, months: 0, help: false, volumes: []},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count: 10, create: false, destroy: dt},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil}]}]

    # Test case: create snapshot and delete old snapshots for only specified volumes.
    dt = ct - (2 * 7 * 24 * 60 * 60)
    run_test[{create: true, group: nil, minutes: 0, hours: 0, days: 0, weeks: 2, months: 0, help: false, volumes: ["red", "blue"]},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: true,  destroy: dt},
                                    {gn: "orange", snap_count: 10, create: false, destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: true,  destroy: nil}]}]

    # Test case: create snapshot and delete old snapshots for only specified volumes with group orange.
    dt = ct - (1 * 7 * 24 * 60 * 60)
    run_test[{create: true, group: "orange", minutes: 0, hours: 0, days: 0, weeks: 1, months: 0, help: false, volumes: ["red", "blue"]},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count: 10, create: true,  destroy: dt},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil},
                                    {gn: "orange", snap_count:  0, create: true,  destroy: nil}]}]

    # Test case: create snapshot and delete old snapshots for all volumes.
    dt = ct - (2 * 7 * 24 * 60 * 60)
    run_test[{create: true, group: nil, minutes: 0, hours: 0, days: 0, weeks: 2, months: 0, help: false, volumes: []},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: true,  destroy: dt},
                                    {gn: "orange", snap_count: 10, create: false, destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: true,  destroy: dt}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: true,  destroy: nil}]}]

    # Test case: create snapshot and delete old snapshots for all volumes with group orange.
    dt = ct - (1 * 7 * 24 * 60 * 60)
    run_test[{create: true, group: "orange", minutes: 0, hours: 0, days: 0, weeks: 1, months: 0, help: false, volumes: []},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count: 10, create: true,  destroy: dt},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count:  0, create: true,  destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil},
                                    {gn: "orange", snap_count:  0, create: true,  destroy: nil}]}]
    
    # Test case: do nothing if help text was displayed.
    run_test[{create: true, group: nil, minutes: 0, hours: 0, days: 0, weeks: 2, months: 0, help: true, volumes: []},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count: 10, create: false, destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil}]}]

    # Test case: do nothing if help text was displayed.
    run_test[{create: true, group: "orange", minutes: 0, hours: 0, days: 0, weeks: 2, months: 0, help: true, volumes: []},
             {vn: "red",   groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil},
                                    {gn: "orange", snap_count: 10, create: false, destroy: nil},
                                    {gn: "brown",  snap_count:  0, create: false, destroy: nil}]},
             {vn: "green", groups: [{gn: nil,      snap_count: 20, create: false, destroy: nil}]},
             {vn: "blue",  groups: [{gn: nil,      snap_count:  0, create: false, destroy: nil}]}]
  end
end

