mount "/mnt" do
  device   "/dev/xvdb"
  fstype   "ext4"
  options  "defaults,nobootwait"
  action   [:mount, :enable]
end

mount "/tmp" do
  pass     0
  fstype   "tmpfs"
  device   "/dev/shm"
  options  "nr_inodes=999k,mode=777,size=500m"
  action   [:mount, :enable]
end
