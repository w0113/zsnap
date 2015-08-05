
require_relative "init_test"
require "minitest/mock"


describe "ZSnap::Volume" do

  it "must create a snapshot" do
    v = ZSnap::Volume.new
    v.name = "pool"

    mock = MiniTest::Mock.new
    mock.expect :call, "", ["zfs", "snapshot", ZSnap::Snapshot.new(volume: v).name]
    ZSnap.stub(:execute, mock) do
        s = v.create_snapshot
    end
    mock.verify
  end

  it "must return all snapshots for a volume" do
    volumes = [ZSnap::Volume.new, ZSnap::Volume.new, ZSnap::Volume.new]
    volumes[0].name, volumes[1].name, volumes[2].name = "green", "red", "blue"

    time = []
    20.times{|i| time << Time.new(2000, 6, 5 + i, 6, 10, 0, "+01:00")}

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

