
require_relative "init_test"
require "minitest/mock"


describe "ZSnap::Snapshot" do

  it "must create new snapshots" do
    t1  = Time.new 2003, 2, 1, 4, 5, 6, "+05:00"
    t10 = Time.new 2003, 2, 1, 4, 5, 0, "+05:00"
    t2  = Time.new 2004, 3, 2, 5, 6, 7, "-05:00"
    t20 = Time.new 2004, 3, 2, 5, 6, 0, "-05:00"
    t3  = Time.utc 2005, 4, 3, 6, 7, 8
    t30 = Time.utc 2005, 4, 3, 6, 7, 0
    v = ZSnap::Volume.new "tank"
    
    Time.stub(:now, t1) do
      s = ZSnap::Snapshot.new group: v.get_default_group
      s.group.must_equal v.get_default_group
      s.name.must_equal "tank@zsnap_2003-02-01_04:05_0500"
      s.time.must_equal t10

      s = ZSnap::Snapshot.new group: v.get_group("foo")
      s.group.must_equal v.get_group "foo"
      s.name.must_equal "tank@zsnap_foo_2003-02-01_04:05_0500"
      s.time.must_equal t10

      s = ZSnap::Snapshot.new group: v.get_default_group, name: "lala"
      s.group.must_equal v.get_default_group
      s.name.must_equal "lala"
      s.time.must_equal t10

      s = ZSnap::Snapshot.new group: v.get_group("foo"), name: "lala"
      s.group.must_equal v.get_group "foo"
      s.name.must_equal "lala"
      s.time.must_equal t10

      s = ZSnap::Snapshot.new group: v.get_default_group, name: "lala", time: t2
      s.group.must_equal v.get_default_group
      s.name.must_equal "lala"
      s.time.must_equal t20

      s = ZSnap::Snapshot.new group: v.get_group("foo"), name: "lala", time: t2
      s.group.must_equal v.get_group "foo"
      s.name.must_equal "lala"
      s.time.must_equal t20

      s = ZSnap::Snapshot.new group: v.get_default_group, time: t2
      s.group.must_equal v.get_default_group
      s.name.must_equal "tank@zsnap_2004-03-02_05:06_-0500"
      s.time.must_equal t20

      s = ZSnap::Snapshot.new group: v.get_group("foo"), time: t2
      s.group.must_equal v.get_group "foo"
      s.name.must_equal "tank@zsnap_foo_2004-03-02_05:06_-0500"
      s.time.must_equal t20

      s = ZSnap::Snapshot.new group: v.get_default_group, time: t3
      s.group.must_equal v.get_default_group
      s.name.must_equal "tank@zsnap_2005-04-03_06:07_0000"
      s.time.must_equal t30

      s = ZSnap::Snapshot.new group: v.get_group("foo"), time: t3
      s.group.must_equal v.get_group "foo"
      s.name.must_equal "tank@zsnap_foo_2005-04-03_06:07_0000"
      s.time.must_equal t30
    end
  end

  it "must destroy snapshots" do
    v = ZSnap::Volume.new "tank"
    s = ZSnap::Snapshot.new group: v.get_default_group

    mock = MiniTest::Mock.new
    mock.expect :call, "", ["zfs", "destroy", s.name]
    ZSnap.stub(:execute, mock) do
      s.destroy
    end
    mock.verify
  end

  it "must not destroy snapshots when simulating" do
    v = ZSnap::Volume.new "tank"
    s = ZSnap::Snapshot.new group: v.get_default_group

    # Replace ZSnap.execute with a stub which raises an exception.
    method_execute = ZSnap.method :execute
    def ZSnap.execute(*args); raise TestError, "Method must not be called."; end

    begin
      $simulate = true
      s.destroy
    ensure
      $simulate = false
      # Restore ZSnap.execute
      ZSnap.define_singleton_method :execute, method_execute
    end
  end
end

