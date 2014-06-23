execute 'mkfs ephemeral disk' do
  command <<-EOT
sudo umount /dev/xvdb
mkfs -t ext4 /dev/xvdb
EOT
  not_if  "grep -qs /var/tmp /proc/mounts"
end

execute 'mkfs ephemeral disk' do
  command <<-EOT
sudo umount /dev/xvdc
mkfs -t ext4 /dev/xvdc
EOT
  not_if  "grep -qs /var/tmp2 /proc/mounts"
end

directory '/var/tmp' do
  mode '0777'
end

directory '/var/tmp2' do
  mode '0777'
end

mount "/var/tmp" do
  device   "/dev/xvdb"
  fstype   "ext4"
  options  "defaults,nobootwait"
  action   [:mount, :enable]
end

mount "/var/tmp2" do
  device   "/dev/xvdc"
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
