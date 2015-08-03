
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

