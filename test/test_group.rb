
require_relative "init_test"
require "minitest/mock"


describe "ZSnap::Group" do

  it "must create new groups" do
    v = ZSnap::Volume.new "tank"

    g = ZSnap::Group.new nil, v
    g.name.must_be_nil
    g.volume.must_equal v

    g = ZSnap::Group.new "foo", v
    g.name.must_equal "foo"
    g.volume.must_equal v

    proc {ZSnap::Group.new "foo:bar", v}.must_raise StandardError
    proc {ZSnap::Group.new "foo", nil}.must_raise StandardError
  end

  it "must add a snapshot" do
    v = ZSnap::Volume.new "tank"
    g = ZSnap::Group.new "foo", v
    s = ZSnap::Snapshot.new group: g

    g.add_snapshot s
    g.snapshots.must_include s

    proc {g.add_snapshot nil}.must_raise StandardError
  end

  it "must create new snapshots" do
    v = ZSnap::Volume.new "tank"
    g1 = v.get_default_group
    g2 = v.get_group "foo"
    t1 = Time.new(2003, 2, 1, 4, 5, 6, "+05:00") 
    
    mock = MiniTest::Mock.new
    mock.expect :call, "", ["zfs", "snapshot", "tank@zsnap_2003-02-01_04:05_0500"]
    ZSnap.stub(:execute, mock) do
      Time.stub(:now, t1) do
        g1.create_snapshot
      end
    end

    mock = MiniTest::Mock.new
    mock.expect :call, "", ["zfs", "snapshot", "tank@zsnap_foo_2003-02-01_04:05_0500"]
    ZSnap.stub(:execute, mock) do
      Time.stub(:now, t1) do
        g2.create_snapshot
      end
    end
  end

  it "must return all snapshots" do
    v = ZSnap::Volume.new "tank"
    g = v.get_default_group
    s1 = ZSnap::Snapshot.new group: g, time: Time.new(2010, 2, 1, 4, 5, 6, "+05:00")
    s2 = ZSnap::Snapshot.new group: g, time: Time.new(2010, 2, 2, 4, 5, 6, "+05:00")
    s3 = ZSnap::Snapshot.new group: g, time: Time.new(2010, 2, 3, 4, 5, 6, "+05:00")
    g.add_snapshot s1
    g.add_snapshot s2
    g.add_snapshot s3
    
    g.snapshots.sort{|a, b| a.time <=> b.time}.must_equal [s1, s2, s3].sort{|a, b| a.time <=> b.time}
  end
end

