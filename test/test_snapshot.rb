
require_relative "init_test"
require "minitest/mock"


describe "ZSnap::Snapshot" do

  it "must create new snapshots" do
    v = ZSnap::Volume.new
    v.name = "pool"

    # New name format.
    t1  = Time.new(2009, 2, 1, 4, 5, 6, "+01:00")
    t10 = Time.new(2009, 2, 1, 4, 5, 0, "+01:00")
    t2  = Time.new(2005, 2, 1, 4, 5, 6, "+01:00")
    t20 = Time.new(2005, 2, 1, 4, 5, 0, "+01:00")
    t3  = Time.new(2007, 2, 1, 4, 5, 6, "+01:00")
    t30 = Time.new(2007, 2, 1, 4, 5, 0, "+01:00")
    t4  = Time.new(2006, 2, 1, 4, 5, 6, "-01:00")
    t40 = Time.new(2006, 2, 1, 4, 5, 0, "-01:00")
    Time.stub(:now, t1) do
      proc {ZSnap::Snapshot.new}.must_raise StandardError
      proc {ZSnap::Snapshot.new time: t2}.must_raise StandardError
      proc {ZSnap::Snapshot.new group: "foo"}.must_raise StandardError
      proc {ZSnap::Snapshot.new group: ""}.must_raise StandardError
      proc {ZSnap::Snapshot.new group: "foo_bar"}.must_raise StandardError

      s = ZSnap::Snapshot.new volume: v
      s.volume.must_equal v
      s.name.must_equal "#{v.name}@zsnap_2009-02-01_04:05_0100"
      s.time.must_equal t10
      s.group.must_be_nil

      s = ZSnap::Snapshot.new volume: v, time: t2
      s.volume.must_equal v
      s.name.must_equal "#{v.name}@zsnap_2005-02-01_04:05_0100"
      s.time.must_equal t20
      s.group.must_be_nil

      s = ZSnap::Snapshot.new volume: v, time: t4
      s.volume.must_equal v
      s.name.must_equal "#{v.name}@zsnap_2006-02-01_04:05_-0100"
      s.time.must_equal t40
      s.group.must_be_nil

      s = ZSnap::Snapshot.new volume: v, group: "foo"
      s.volume.must_equal v
      s.name.must_equal "#{v.name}@zsnap_foo_2009-02-01_04:05_0100"
      s.time.must_equal t10
      s.group.must_equal "foo"

      s = ZSnap::Snapshot.new volume: v, time: t2, group: "foo"
      s.volume.must_equal v
      s.name.must_equal "#{v.name}@zsnap_foo_2005-02-01_04:05_0100"
      s.time.must_equal t20
      s.group.must_equal "foo"

      s = ZSnap::Snapshot.new volume: v, time: t4, group: "foo"
      s.volume.must_equal v
      s.name.must_equal "#{v.name}@zsnap_foo_2006-02-01_04:05_-0100"
      s.time.must_equal t40
      s.group.must_equal "foo"

      ZSnap::Volume.stub(:all, [v]) do
        proc {ZSnap::Snapshot.new name: "#{v.name}@iamnotmadebyzsnap"}.must_raise StandardError
        proc {ZSnap::Snapshot.new name: "#{v.name}@zsnap_foo_2007-02-01_04:05:06_0100"}.must_raise StandardError
        proc {ZSnap::Snapshot.new name: "#{v.name}@zsnap_foo_2007-02-01_04:05:06_+0100"}.must_raise StandardError
        proc {ZSnap::Snapshot.new name: "#{v.name}@zsnap_foo_04:05:06_0100"}.must_raise StandardError

        n = "#{v.name}@zsnap_2007-02-01_04:05_0100"
        s = ZSnap::Snapshot.new name: n
        s.volume.must_equal v
        s.name.must_equal n
        s.time.must_equal t30
        s.group.must_be_nil

        n = "#{v.name}@zsnap_foo_2007-02-01_04:05_0100"
        s = ZSnap::Snapshot.new name: n
        s.volume.must_equal v
        s.name.must_equal n
        s.time.must_equal t30
        s.group.must_equal "foo"

        n = "#{v.name}@zsnap_2006-02-01_04:05_-0100"
        s = ZSnap::Snapshot.new name: n
        s.volume.must_equal v
        s.name.must_equal n
        s.time.must_equal t40
        s.group.must_be_nil

        n = "#{v.name}@zsnap_foo_2006-02-01_04:05_-0100"
        s = ZSnap::Snapshot.new name: n
        s.volume.must_equal v
        s.name.must_equal n
        s.time.must_equal t40
        s.group.must_equal "foo"
      end
    end

    # Old name format.
    t50 = Time.utc(2003, 2, 1, 4, 5, 0)
    Time.stub(:now, t1) do
      ZSnap::Volume.stub(:all, [v]) do
        n = "#{v.name}@zsnap_2003-02-01_04:05:06"
        s = ZSnap::Snapshot.new name: n
        s.volume.must_equal v
        s.name.must_equal n
        s.time.must_equal t50
        s.group.must_be_nil
      end
    end
  end

  it "must set and read the name attribute" do
    vs = []
    2.times{vs << ZSnap::Volume.new}
    vs[0].name = "pool"
    vs[1].name = "tank"

    t1  = Time.new(2009, 2, 1, 4, 5, 6, "+01:00")
    t10 = Time.new(2009, 2, 1, 4, 5, 0, "+01:00")
    t2  = Time.new(2008, 2, 1, 4, 5, 6, "+01:00")
    t20 = Time.new(2008, 2, 1, 4, 5, 0, "+01:00")
    t3  = Time.new(2007, 2, 1, 4, 5, 6, "-01:00")
    t30 = Time.new(2007, 2, 1, 4, 5, 0, "-01:00")
    t4  = Time.utc(2006, 2, 1, 4, 5, 6)
    t40 = Time.utc(2006, 2, 1, 4, 5, 0)
    Time.stub(:now, t1) do
      ZSnap::Volume.stub(:all, vs) do
        # New format.
        s = ZSnap::Snapshot.new volume: vs[0]
        s.volume.must_equal vs[0]
        s.time.must_equal t10
        s.name.must_equal "#{vs[0].name}@zsnap_2009-02-01_04:05_0100"
        s.group.must_be_nil
        s.name = "#{vs[1].name}@zsnap_2008-02-01_04:05_0100"
        s.volume.must_equal vs[1]
        s.time.must_equal t20
        s.name.must_equal "#{vs[1].name}@zsnap_2008-02-01_04:05_0100"
        s.group.must_be_nil

        s = ZSnap::Snapshot.new volume: vs[0]
        s.volume.must_equal vs[0]
        s.time.must_equal t10
        s.name.must_equal "#{vs[0].name}@zsnap_2009-02-01_04:05_0100"
        s.group.must_be_nil
        s.name = "#{vs[1].name}@zsnap_foo_2008-02-01_04:05_0100"
        s.volume.must_equal vs[1]
        s.time.must_equal t20
        s.name.must_equal "#{vs[1].name}@zsnap_foo_2008-02-01_04:05_0100"
        s.group.must_equal "foo"

        s = ZSnap::Snapshot.new volume: vs[0]
        s.volume.must_equal vs[0]
        s.time.must_equal t10
        s.name.must_equal "#{vs[0].name}@zsnap_2009-02-01_04:05_0100"
        s.group.must_be_nil
        s.name = "#{vs[1].name}@zsnap_foo_2007-02-01_04:05_-0100"
        s.volume.must_equal vs[1]
        s.time.must_equal t30
        s.name.must_equal "#{vs[1].name}@zsnap_foo_2007-02-01_04:05_-0100"
        s.group.must_equal "foo"

        # Old format.
        s = ZSnap::Snapshot.new volume: vs[0]
        s.volume.must_equal vs[0]
        s.time.must_equal t10
        s.name.must_equal "#{vs[0].name}@zsnap_2009-02-01_04:05_0100"
        s.group.must_be_nil
        s.name = "#{vs[1].name}@zsnap_2006-02-01_04:05:06"
        s.volume.must_equal vs[1]
        s.time.must_equal t40
        s.name.must_equal "#{vs[1].name}@zsnap_2006-02-01_04:05:06"
        s.group.must_be_nil
      end
    end
  end

  it "must destroy snapshots" do
    v = ZSnap::Volume.new
    v.name = "pool"
    t1 = Time.new(2003, 2, 1, 4, 5, 6, "+01:00")
    
    s = ZSnap::Snapshot.new volume: v, time: t1

    mock = MiniTest::Mock.new
    mock.expect :call, "", ["zfs", "destroy", s.name]
    ZSnap.stub(:execute, mock) do
      s.destroy
    end
    mock.verify
  end
end

