
require_relative "init_test"
require "minitest/mock"


describe "ZSnap::Volume" do

  it "must create new volumes" do
    v = ZSnap::Volume.new "tank"
    v.name.must_equal "tank"
    proc {ZSnap::Volume.new nil}.must_raise StandardError
    proc {ZSnap::Volume.new ""}.must_raise StandardError
  end

  it "must return the default group" do
    v = ZSnap::Volume.new "tank"
    v.get_group "foo"
    v.get_default_group.must_be_instance_of ZSnap::Group
    v.get_default_group.name.must_be_nil

    v = ZSnap::Volume.new "lala"
    v.get_default_group.must_be_instance_of ZSnap::Group
    v.get_default_group.name.must_be_nil
  end

  it "must return all groups" do
    v = ZSnap::Volume.new "tank"
    v.get_group "foo"
    v.get_group "bar"
    v.get_group "lala"
    v.get_group "lulu"
    v.groups.map{|g| g.name}.compact.sort.must_equal ["foo", "bar", "lala", "lulu"].sort
  end

  it "must return groups by name and create them if necessary" do
    v = ZSnap::Volume.new "tank"
    v.get_group("foo").must_be_instance_of ZSnap::Group

    gb = v.get_group("blue")
    v.get_group("blue").must_be_same_as gb
  end

  it "must read Volume information from ZFS" do
    vn = ["quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"]

    exec_output = ""
    vn.each{|v| exec_output += "#{v}\t250591104\t5701016504448\t249751872\t/#{v}\n"}

    ZSnap.stub(:execute, exec_output) do
      v_info = ZSnap::Volume.read_volumes
      v_info.map{|v| v[:name]}.sort.must_equal vn.sort
    end
  end

  it "must parse snapshot names" do
    # New name format.
    s_name = "tank@zsnap_2009-02-01_04:05_0100"
    s = ZSnap::Volume.parse_snapshot_name s_name
    s[:name].must_equal s_name
    s[:volume_name].must_equal "tank"
    s[:group_name].must_be_nil
    s[:snapshot_time].must_equal Time.new(2009, 2, 1, 4, 5, 0, "+01:00")

    s_name = "tank@zsnap_2009-02-01_04:05_-0100"
    s = ZSnap::Volume.parse_snapshot_name s_name
    s[:name].must_equal s_name
    s[:volume_name].must_equal "tank"
    s[:group_name].must_be_nil
    s[:snapshot_time].must_equal Time.new(2009, 2, 1, 4, 5, 0, "-01:00")

    s_name = "tank@zsnap_foo_2009-02-01_04:05_0100"
    s = ZSnap::Volume.parse_snapshot_name s_name
    s[:name].must_equal s_name
    s[:volume_name].must_equal "tank"
    s[:group_name].must_equal "foo"
    s[:snapshot_time].must_equal Time.new(2009, 2, 1, 4, 5, 0, "+01:00")

    s_name = "tank@zsnap_foo_2009-02-01_04:05_-0100"
    s = ZSnap::Volume.parse_snapshot_name s_name
    s[:name].must_equal s_name
    s[:volume_name].must_equal "tank"
    s[:group_name].must_equal "foo"
    s[:snapshot_time].must_equal Time.new(2009, 2, 1, 4, 5, 0, "-01:00")

    # Old name format.
    s_name = "tank@zsnap_2009-02-01_04:05:06"
    s = ZSnap::Volume.parse_snapshot_name s_name
    s[:name].must_equal s_name
    s[:volume_name].must_equal "tank"
    s[:group_name].must_be_nil
    s[:snapshot_time].must_equal Time.utc(2009, 2, 1, 4, 5, 0)

    proc {ZSnap::Volume.parse_snapshot_name "tank@foobar"}.must_raise StandardError
    proc {ZSnap::Volume.parse_snapshot_name "tank@zsnap_2009-02-01_04:05:06_0100"}.must_raise StandardError
    proc {ZSnap::Volume.parse_snapshot_name "tank@zsnap_foo_2009-02-01_04:05:06"}.must_raise StandardError
    proc {ZSnap::Volume.parse_snapshot_name "tank@zsnap_foo_2009-02-01_04:05:06_0100"}.must_raise StandardError
  end

  it "must read Snapshot information from ZFS" do
    exec_output = ""
    exec_output += "red@zsnap_2010-05-01_06:07:08\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_2010-05-01_06:07:08\t0\t-\t249751872\t-\n"
    exec_output += "blue@zsnap_2010-05-01_06:07:08\t0\t-\t249751872\t-\n"
    exec_output += "red@zsnap_2010-05-02_06:07:08\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_2010-05-02_06:07:08\t0\t-\t249751872\t-\n"
    exec_output += "blue@zsnap_2010-05-02_06:07:08\t0\t-\t249751872\t-\n"
    exec_output += "red@zsnap_2010-05-03_06:07:08\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_2010-05-03_06:07:08\t0\t-\t249751872\t-\n"
    exec_output += "blue@zsnap_2010-05-03_06:07:08\t0\t-\t249751872\t-\n"
    exec_output += "red@zsnap_2010-05-04_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_2010-05-04_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "blue@zsnap_2010-05-04_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "red@zsnap_2010-05-05_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_2010-05-05_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "blue@zsnap_2010-05-05_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "red@zsnap_2010-05-06_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_2010-05-06_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "blue@zsnap_2010-05-06_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "red@zsnap_foo_2010-05-07_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_foo_2010-05-07_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "blue@zsnap_foo_2010-05-07_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "red@zsnap_foo_2010-05-08_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_foo_2010-05-08_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "blue@zsnap_foo_2010-05-08_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "red@zsnap_foo_2010-05-09_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_foo_2010-05-09_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "blue@zsnap_foo_2010-05-09_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "red@zsnap_foo_2010-05-10_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "green@zsnap_foo_2010-05-10_06:07_0100\t0\t-\t249751872\t-\n"
    exec_output += "red@superman\t0\t-\t249751872\t-\n"
    exec_output += "green@superman\t0\t-\t249751872\t-\n"
    exec_output += "blue@superman\t0\t-\t249751872\t-\n"
    exec_output += "red@batman\t0\t-\t249751872\t-\n"
    exec_output += "green@batman\t0\t-\t249751872\t-\n"
    exec_output += "blue@batman\t0\t-\t249751872\t-\n"

    ZSnap.stub(:execute, exec_output) do
      s_info = ZSnap::Volume.read_snapshots
      s_info.size.must_equal 29
      s_info.select{|s| s[:volume_name] == "red"}.size.must_equal 10
      s_info.select{|s| s[:volume_name] == "green"}.size.must_equal 10
      s_info.select{|s| s[:volume_name] == "blue"}.size.must_equal 9
      s_info.select{|s| s[:snapshot_time] >= Time.new(2010, 5, 7)}.each{|s| s[:group_name].must_equal "foo"}
      s_info.map{|s| s[:snapshot_time]}.each do |t|
        t.year.must_equal 2010
        t.month.must_equal 5
        t.day.must_be :>=, 1
        t.day.must_be :<=, 10
        t.hour.must_equal 6
        t.min.must_equal 7
        t.sec.must_equal 0
      end
    end
  end

  it "must create Volumes, Groups and Snapshots" do
    v_info = [{name: "tank"},
              {name: "pool"},
              {name: "unused"}]

    s_info = ["tank@zsnap_2010-02-01_04:05_0500",
              "tank@zsnap_2010-02-02_04:05_0500",
              "tank@zsnap_2010-02-03_04:05_0500",
              "tank@zsnap_2010-02-04_04:05_0500",
              "tank@zsnap_2010-02-05_04:05_0500",
              "tank@zsnap_daily_2010-02-06_04:05_0500",
              "tank@zsnap_daily_2010-02-07_04:05_0500",
              "tank@zsnap_daily_2010-02-08_04:05_0500",
              "tank@zsnap_daily_2010-02-09_04:05_0500",
              "tank@zsnap_daily_2010-02-10_04:05_0500",
              "tank@zsnap_moo_2010-02-11_04:05_0500",
              "tank@zsnap_moo_2010-02-12_04:05_0500",
              "tank@zsnap_moo_2010-02-13_04:05_0500",
              "tank@zsnap_cow_2010-02-11_04:05_0500",
              "tank@zsnap_cow_2010-02-12_04:05_0500",
              "tank@zsnap_cow_2010-02-13_04:05_0500",
              "pool@zsnap_2010-02-01_04:05_0500",
              "pool@zsnap_2010-02-02_04:05_0500",
              "pool@zsnap_2010-02-03_04:05_0500"]
    s_info.map!{|s| ZSnap::Volume.parse_snapshot_name(s)}

    ZSnap::Volume.stub(:read_volumes, v_info) do
      ZSnap::Volume.stub(:read_snapshots, s_info) do
        vs = ZSnap::Volume.all
        v_tank = vs["tank"]
        v_pool = vs["pool"]
        v_unused = vs["unused"]

        v_tank.groups.size.must_equal 4
        v_pool.groups.size.must_equal 1
        v_unused.groups.size.must_equal 1

        v_tank.groups.map{|g| g.snapshots.size}.reduce(:+).must_equal 16
        v_pool.groups.map{|g| g.snapshots.size}.reduce(:+).must_equal 3
        v_unused.groups.map{|g| g.snapshots.size}.reduce(:+).must_equal 0

        s = v_tank.get_default_group.snapshots.sort{|a, b| a.time <=> b.time}
        s[0].name.must_equal "tank@zsnap_2010-02-01_04:05_0500"
        s[0].group.must_equal v_tank.get_default_group
        s[0].time.must_equal Time.new(2010, 2, 1, 4, 5, 0, "+05:00")
        s[1].name.must_equal "tank@zsnap_2010-02-02_04:05_0500"
        s[1].group.must_equal v_tank.get_default_group
        s[1].time.must_equal Time.new(2010, 2, 2, 4, 5, 0, "+05:00")
        s[2].name.must_equal "tank@zsnap_2010-02-03_04:05_0500"
        s[2].group.must_equal v_tank.get_default_group
        s[2].time.must_equal Time.new(2010, 2, 3, 4, 5, 0, "+05:00")
        s[3].name.must_equal "tank@zsnap_2010-02-04_04:05_0500"
        s[3].group.must_equal v_tank.get_default_group
        s[3].time.must_equal Time.new(2010, 2, 4, 4, 5, 0, "+05:00")
        s[4].name.must_equal "tank@zsnap_2010-02-05_04:05_0500"
        s[4].group.must_equal v_tank.get_default_group
        s[4].time.must_equal Time.new(2010, 2, 5, 4, 5, 0, "+05:00")

        s = v_tank.get_group("daily").snapshots.sort{|a, b| a.time <=> b.time}
        s[0].name.must_equal "tank@zsnap_daily_2010-02-06_04:05_0500"
        s[0].group.must_equal v_tank.get_group("daily")
        s[0].time.must_equal Time.new(2010, 2, 6, 4, 5, 0, "+05:00")
        s[1].name.must_equal "tank@zsnap_daily_2010-02-07_04:05_0500"
        s[1].group.must_equal v_tank.get_group("daily")
        s[1].time.must_equal Time.new(2010, 2, 7, 4, 5, 0, "+05:00")
        s[2].name.must_equal "tank@zsnap_daily_2010-02-08_04:05_0500"
        s[2].group.must_equal v_tank.get_group("daily")
        s[2].time.must_equal Time.new(2010, 2, 8, 4, 5, 0, "+05:00")
        s[3].name.must_equal "tank@zsnap_daily_2010-02-09_04:05_0500"
        s[3].group.must_equal v_tank.get_group("daily")
        s[3].time.must_equal Time.new(2010, 2, 9, 4, 5, 0, "+05:00")
        s[4].name.must_equal "tank@zsnap_daily_2010-02-10_04:05_0500"
        s[4].group.must_equal v_tank.get_group("daily")
        s[4].time.must_equal Time.new(2010, 2, 10, 4, 5, 0, "+05:00")

        s = v_tank.get_group("moo").snapshots.sort{|a, b| a.time <=> b.time}
        s[0].name.must_equal "tank@zsnap_moo_2010-02-11_04:05_0500"
        s[0].group.must_equal v_tank.get_group("moo")
        s[0].time.must_equal Time.new(2010, 2, 11, 4, 5, 0, "+05:00")
        s[1].name.must_equal "tank@zsnap_moo_2010-02-12_04:05_0500"
        s[1].group.must_equal v_tank.get_group("moo")
        s[1].time.must_equal Time.new(2010, 2, 12, 4, 5, 0, "+05:00")
        s[2].name.must_equal "tank@zsnap_moo_2010-02-13_04:05_0500"
        s[2].group.must_equal v_tank.get_group("moo")
        s[2].time.must_equal Time.new(2010, 2, 13, 4, 5, 0, "+05:00")

        s = v_tank.get_group("cow").snapshots.sort{|a, b| a.time <=> b.time}
        s[0].name.must_equal "tank@zsnap_cow_2010-02-11_04:05_0500"
        s[0].group.must_equal v_tank.get_group("cow")
        s[0].time.must_equal Time.new(2010, 2, 11, 4, 5, 0, "+05:00")
        s[1].name.must_equal "tank@zsnap_cow_2010-02-12_04:05_0500"
        s[1].group.must_equal v_tank.get_group("cow")
        s[1].time.must_equal Time.new(2010, 2, 12, 4, 5, 0, "+05:00")
        s[2].name.must_equal "tank@zsnap_cow_2010-02-13_04:05_0500"
        s[2].group.must_equal v_tank.get_group("cow")
        s[2].time.must_equal Time.new(2010, 2, 13, 4, 5, 0, "+05:00")

        s = v_pool.get_default_group.snapshots.sort{|a, b| a.time <=> b.time}
        s[0].name.must_equal "pool@zsnap_2010-02-01_04:05_0500"
        s[0].group.must_equal v_pool.get_default_group
        s[0].time.must_equal Time.new(2010, 2, 1, 4, 5, 0, "+05:00")
        s[1].name.must_equal "pool@zsnap_2010-02-02_04:05_0500"
        s[1].group.must_equal v_pool.get_default_group
        s[1].time.must_equal Time.new(2010, 2, 2, 4, 5, 0, "+05:00")
        s[2].name.must_equal "pool@zsnap_2010-02-03_04:05_0500"
        s[2].group.must_equal v_pool.get_default_group
        s[2].time.must_equal Time.new(2010, 2, 3, 4, 5, 0, "+05:00")
      end
    end
  end
end

