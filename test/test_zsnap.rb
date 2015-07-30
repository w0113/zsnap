
require_relative "init_test"
require "minitest/mock"


describe "ZSnap::Snapshot" do

  it "must create new snapshots" do
    v = ZSnap::Volume.new
    v.name = "pool"
    
    t1 = Time.utc(2003, 2, 1, 4, 5, 6)
    t2 = Time.utc(1337, 2, 1, 4, 5, 6)
    t3 = Time.utc(1970, 2, 1, 4, 5, 6)
    Time.stub(:now, t1) do
      proc {ZSnap::Snapshot.new}.must_raise StandardError
      proc {ZSnap::Snapshot.new time: t2}.must_raise StandardError

      s = ZSnap::Snapshot.new volume: v
      s.volume.must_equal v
      s.name.must_equal "#{v.name}@zsnap_2003-02-01_04:05:06"
      s.time.must_equal t1

      s = ZSnap::Snapshot.new volume: v, time: t2
      s.volume.must_equal v
      s.name.must_equal "#{v.name}@zsnap_1337-02-01_04:05:06"
      s.time.must_equal t2

      ZSnap::Volume.stub(:all, [v]) do
        name = "#{v.name}@zsnap_1970-02-01_04:05:06"

        s = ZSnap::Snapshot.new name: name
        s.volume.must_equal v
        s.name.must_equal name
        s.time.must_equal t3

        s = ZSnap::Snapshot.new name: name, time: t2
        s.volume.must_equal v
        s.name.must_equal name
        s.time.must_equal t3
      end
    end
  end

  it "must set and read the name attribute" do
    v = ZSnap::Volume.new
    v.name = "pool"
    
    name = "#{v.name}@zsnap_1970-02-01_04:05:06"

    t1 = Time.utc(2003, 2, 1, 4, 5, 6)
    Time.stub(:now, t1) do
      ZSnap::Volume.stub(:all, [v]) do
        s = ZSnap::Snapshot.new volume: v
        s.name.must_equal "#{v.name}@zsnap_2003-02-01_04:05:06"
        s.name = name
        s.name.must_equal name

        proc {s.name = "#{v.name}@green_orangutans"}.must_raise ArgumentError
        proc {s.name = "blue_goldfish"}.must_raise StandardError
      end
    end
  end

  it "must destroy snapshots" do
    v = ZSnap::Volume.new
    v.name = "pool"
    t1 = Time.utc(2003, 2, 1, 4, 5, 6)
    
    s = ZSnap::Snapshot.new volume: v, time: t1

    mock = MiniTest::Mock.new
    mock.expect :call, "", ["zfs", "destroy", s.name]
    ZSnap.stub(:execute, mock) do
      s.destroy
    end
    mock.verify
  end
end


describe "ZSnap::Volume" do

  it "must create a snapshot" do
    v = ZSnap::Volume.new
    v.name = "pool"

    t1 = Time.utc(2003, 2, 1, 4, 5, 6)

    mock = MiniTest::Mock.new
    mock.expect :call, "", ["zfs", "snapshot", ZSnap::Snapshot.new(volume: v, time: t1).name]
    ZSnap.stub(:execute, mock) do
      Time.stub(:now, t1) do
        s = v.create_snapshot
        s.volume.must_equal v
        s.time.must_equal t1
      end
    end
    mock.verify
  end

  it "must return all snapshots for a volume" do
    volumes = [ZSnap::Volume.new, ZSnap::Volume.new, ZSnap::Volume.new]
    volumes[0].name, volumes[1].name, volumes[2].name = "green", "red", "blue"

    time = []
    20.times{|i| time << Time.utc(2000, 6, 5 + i, 6, 10, 0)}

    exec_output = ""
    time.each do |t|
      volumes.each do |v|
        exec_output += "#{ZSnap::Snapshot.new(volume: v, time: t).name}\t0\t-\t249751872\t-\n"
      end
    end

    ["superman", "batman", "flash"].each do |s|
      volumes.each do |v|
        exec_output += "#{v.name}@#{s}\t0\t-\t249751872\t-\n"
      end
    end

    ZSnap::Volume.stub(:all, volumes) do
      ZSnap.stub(:execute, exec_output) do
        gs = volumes[0].snapshots
        gs.size.must_equal 20
        gs.each{|s| s.volume.must_equal volumes[0]; time.must_include s.time}
        rs = volumes[1].snapshots
        rs.size.must_equal 20
        rs.each{|s| s.volume.must_equal volumes[1]; time.must_include s.time}
        bs = volumes[2].snapshots
        bs.size.must_equal 20
        bs.each{|s| s.volume.must_equal volumes[2]; time.must_include s.time}
      end
    end
  end

  it "must return all volumes" do
    vn = ["quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"]

    exec_output = ""
    vn.each{|v| exec_output += "#{v}\t250591104\t5701016504448\t249751872\t/#{v}\n"}

    ZSnap.stub(:execute, exec_output) do
      volumes = ZSnap::Volume.all
      volumes.map{|v| v.name}.sort.must_equal vn.sort
    end
  end

  it "must find volumes by name" do
    vn = ["quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"]
    volumes = vn.map{|v_name| v = ZSnap::Volume.new; v.name = v_name; v}

    ZSnap::Volume.stub(:all, volumes) do
      vn.each{|v_name| ZSnap::Volume.find_by_names(v_name).first.name.must_equal v_name}
      ZSnap::Volume.find_by_names(*vn).sort{|a, b| a.name <=> b.name}.must_equal volumes.sort{|a, b| a.name <=> b.name}
      proc {ZSnap::Volume.find_by_names "idonotexist"}.must_raise StandardError
    end
  end
end


describe "ZSnap" do

  it "must calculate destroy date" do
    start_date = Time.utc 2010, 6, 15, 12, 30, 0
    Time.stub(:now, start_date) do
      ZSnap.calc_destroy_date(0, 0, 0, 0, 0).must_equal Time.utc(2010, 6, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(0, 0, 0, 0, 1).must_equal Time.utc(2010, 6, 15, 12, 29, 0)
      ZSnap.calc_destroy_date(0, 0, 0, 0, 121).must_equal Time.utc(2010, 6, 15, 10, 29, 0)
      ZSnap.calc_destroy_date(0, 0, 0, 1, 0).must_equal Time.utc(2010, 6, 15, 11, 30, 0)
      ZSnap.calc_destroy_date(0, 0, 0, 49, 0).must_equal Time.utc(2010, 6, 13, 11, 30, 0)
      ZSnap.calc_destroy_date(0, 0, 1, 0, 0).must_equal Time.utc(2010, 6, 14, 12, 30, 0)
      ZSnap.calc_destroy_date(0, 0, 15, 0, 0).must_equal Time.utc(2010, 5, 31, 12, 30, 0)
      ZSnap.calc_destroy_date(0, 1, 0, 0, 0).must_equal Time.utc(2010, 6, 8, 12, 30, 0)
      ZSnap.calc_destroy_date(0, 6, 0, 0, 0).must_equal Time.utc(2010, 5, 4, 12, 30, 0)
      ZSnap.calc_destroy_date(1, 0, 0, 0, 0).must_equal Time.utc(2010, 5, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(2, 0, 0, 0, 0).must_equal Time.utc(2010, 4, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(3, 0, 0, 0, 0).must_equal Time.utc(2010, 3, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(4, 0, 0, 0, 0).must_equal Time.utc(2010, 2, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(5, 0, 0, 0, 0).must_equal Time.utc(2010, 1, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(6, 0, 0, 0, 0).must_equal Time.utc(2009, 12, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(7, 0, 0, 0, 0).must_equal Time.utc(2009, 11, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(8, 0, 0, 0, 0).must_equal Time.utc(2009, 10, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(9, 0, 0, 0, 0).must_equal Time.utc(2009, 9, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(10, 0, 0, 0, 0).must_equal Time.utc(2009, 8, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(11, 0, 0, 0, 0).must_equal Time.utc(2009, 7, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(12, 0, 0, 0, 0).must_equal Time.utc(2009, 6, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(13, 0, 0, 0, 0).must_equal Time.utc(2009, 5, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(23, 0, 0, 0, 0).must_equal Time.utc(2008, 7, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(24, 0, 0, 0, 0).must_equal Time.utc(2008, 6, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(25, 0, 0, 0, 0).must_equal Time.utc(2008, 5, 15, 12, 30, 0)
      ZSnap.calc_destroy_date(1, 1, 1, 1, 1).must_equal Time.utc(2010, 5, 7, 11, 29, 0)
      ZSnap.calc_destroy_date(2, 3, 4, 5, 6).must_equal Time.utc(2010, 3, 21, 7, 24, 0)
      proc {ZSnap.calc_destroy_date(0, 0, 0, 0, -1)}.must_raise StandardError
      proc {ZSnap.calc_destroy_date(0, 0, 0, -1, 0)}.must_raise StandardError
      proc {ZSnap.calc_destroy_date(0, 0, -1, 0, 0)}.must_raise StandardError
      proc {ZSnap.calc_destroy_date(0, -1, 0, 0, 0)}.must_raise StandardError
      proc {ZSnap.calc_destroy_date(-1, 0, 0, 0, 0)}.must_raise StandardError
    end

    start_date = Time.utc 2010, 3, 31, 12, 30, 0
    Time.stub(:now, start_date) do
      ZSnap.calc_destroy_date(1, 0, 0, 0, 0).must_equal Time.utc(2010, 2, 28, 12, 30, 0)
      ZSnap.calc_destroy_date(2, 0, 0, 0, 0).must_equal Time.utc(2010, 1, 31, 12, 30, 0)
      ZSnap.calc_destroy_date(3, 0, 0, 0, 0).must_equal Time.utc(2009, 12, 31, 12, 30, 0)
      ZSnap.calc_destroy_date(4, 0, 0, 0, 0).must_equal Time.utc(2009, 11, 30, 12, 30, 0)
    end
  end

  it "must execute commands on the cmdline" do
    ZSnap.execute("echo", "Hello World!").strip.must_equal "Hello World!"
    proc {ZSnap.execute("iamnothere", "-a", "-b")}.must_raise StandardError
  end

  it "must parse command line arguments" do
    stdout_old = $stdout
    argv_old = ARGV
    begin
      # Redirect stdout to /dev/null for this test.
      $stdout = File.new "/dev/null", "w"
      
      ARGV.replace []
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-h"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-c"]
      ZSnap.get_options.must_equal({create: true, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []})
      ARGV.replace ["-M", "10"]
      ZSnap.get_options.must_equal({create: false, minutes: 10, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []})
      ARGV.replace ["-M", "-10"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-M", "abc"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-H", "10"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 10, days: 0, weeks: 0, months: 0, help: false, volumes: []})
      ARGV.replace ["-H", "-10"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-H", "abc"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-d", "10"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 10, weeks: 0, months: 0, help: false, volumes: []})
      ARGV.replace ["-d", "-10"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-d", "abc"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-w", "10"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 10, months: 0, help: false, volumes: []})
      ARGV.replace ["-w", "-10"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-w", "abc"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-m", "10"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 10, help: false, volumes: []})
      ARGV.replace ["-m", "-10"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-m", "abc"]
      ZSnap.get_options.must_equal({create: false, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: true, volumes: []})
      ARGV.replace ["-c", "-M", "1", "-H", "2", "-d", "3", "-w", "4", "-m", "5", "old", "mc", "donald"]
      ZSnap.get_options.must_equal({create: true, minutes: 1, hours: 2, days: 3, weeks: 4, months: 5, help: false, volumes: ["old", "mc", "donald"]})
    ensure
      # Restore stdout.
      $stdout.close
      $stdout = stdout_old

      # Restore ARGV
      ARGV.replace argv_old
    end
  end

  it "must process comandline arguments and take actions accordingly" do
    # Start date for testing.
    ct = Time.utc(2000, 10, 30, 1, 2, 0)

    # MiniTest::Mock got its instance_variable_set method deleted.
    # We need a smale replacement.
    class MiniTest::Mock
      def instance_variable_set(var, value)
        eval "#{var} = value", binding, __FILE__, __LINE__
      end
    end

    # Helper function to create test data.
    create_volumes = lambda do |*vs|
      return vs.map do |v|
        # Mock Volume object
        mv = MiniTest::Mock.new
        eval "def mv.name; return '#{v[:name]}'; end", binding, __FILE__, __LINE__
        def mv.nil?; return false; end
        mv.expect :create_snapshot, nil if v[:create]

        # Mock Snapshot objects for volume.
        ss = []
        20.times do |i|
          ms_time = Time.utc(ct.year, ct.month, ct.day - i, ct.hour, ct.min, ct.sec)
          ms = MiniTest::Mock.new
          ms.instance_variable_set :@volume, mv
          def ms.volume; return @volume; end
          ms.instance_variable_set :@time, ms_time
          def ms.time; return @time; end
          def ms.name; return "#{@volume.name}@#{@time.strftime ZSnap::Snapshot::DATE_FORMAT}"; end
          ms.expect :destroy, nil if not v[:destroy].nil? and ms_time < v[:destroy]
          ss << ms
        end
        mv.instance_variable_set :@snapshots, ss
        def mv.snapshots; return @snapshots; end
        mv
      end
    end

    # Helper function to test ZSnap.main:
    test_main = lambda do |opts, *vs_opts|
      Time.stub(:now, ct) do
        vs = create_volumes[*vs_opts]
        ZSnap::Volume.stub(:all, vs) do
          ZSnap.stub(:get_options, opts) do
            ZSnap.main
            vs.each do |v|
              v.verify
              v.snapshots.each{|s| s.verify}
            end
          end
        end
      end
    end

    # Test case: create snapshot for only specified volumes.
    test_main.call({create: true, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: ["blue", "green"]},
                   {name: "blue", create: true, destroy: nil}, 
                   {name: "red", create: false, destroy: nil},
                   {name: "green", create: true, destroy: nil})

    # Test case: create snapshot for all volumes.
    test_main.call({create: true, minutes: 0, hours: 0, days: 0, weeks: 0, months: 0, help: false, volumes: []},
                   {name: "blue", create: true, destroy: nil}, 
                   {name: "red", create: true, destroy: nil},
                   {name: "green", create: true, destroy: nil})

    # Test case: delete snapshots for only specified volumes.
    dt = ct - (2 * 7 * 24 * 60 * 60)
    test_main.call({create: false, minutes: 0, hours: 0, days: 0, weeks: 2, months: 0, help: false, volumes: ["blue", "green"]},
                   {name: "blue", create: false, destroy: dt}, 
                   {name: "red", create: false, destroy: nil},
                   {name: "green", create: false, destroy: dt})
    
    # Test case: delete snapshots for all volumes.
    dt = ct - (2 * 7 * 24 * 60 * 60)
    test_main.call({create: false, minutes: 0, hours: 0, days: 0, weeks: 2, months: 0, help: false, volumes: []},
                   {name: "blue", create: false, destroy: dt}, 
                   {name: "red", create: false, destroy: dt},
                   {name: "green", create: false, destroy: dt})

    # Test case: create snapshot and delete old snapshots for only specified volumes.
    dt = ct - (10 * 24 * 60 * 60)
    test_main.call({create: true, minutes: 0, hours: 0, days: 10, weeks: 0, months: 0, help: false, volumes: ["blue", "green"]},
                   {name: "blue", create: true, destroy: dt}, 
                   {name: "red", create: false, destroy: nil},
                   {name: "green", create: true, destroy: dt})
    
    # Test case: create snapshot and delete old snapshots for all volumes.
    dt = ct - (10 * 24 * 60 * 60)
    test_main.call({create: true, minutes: 0, hours: 0, days: 10, weeks: 0, months: 0, help: false, volumes: []},
                   {name: "blue", create: true, destroy: dt}, 
                   {name: "red", create: true, destroy: dt},
                   {name: "green", create: true, destroy: dt})

    # Test case: do nothing if help text was displayed.
    test_main.call({create: true, minutes: 0, hours: 0, days: 10, weeks: 0, months: 0, help: true, volumes: []},
                   {name: "blue", create: false, destroy: nil}, 
                   {name: "red", create: false, destroy: nil},
                   {name: "green", create: false, destroy: nil})
  end
end

