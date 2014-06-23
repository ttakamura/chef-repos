
if node[:tk][:ebs]
  node[:tk][:ebs].each do |dir, settings|
    device, vol_id = settings

    # mkfs.ext4 /dev/xv
    bash "Attach and mount EBS on #{device}" do
      code <<-EOT
export MY_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
export AWS_DEFAULT_REGION=ap-northeast-1
aws ec2 attach-volume --instance-id $MY_ID --volume-id #{vol_id} --device #{device}
sleep 5
mount /dev/xvdf /mnt
EOT
      not_if 'df | grep /mnt'
    end

  end
end
