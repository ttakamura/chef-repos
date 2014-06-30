require 'json'
require 'slop'

def userdata_script
  <<-EOT
#!/bin/sh
service docker stop
umount /dev/xvdb
mkdir /var/tmp
mount -t ext4 /dev/xvdb /var/tmp
mount -t ext4 /dev/xvdf /mnt
service docker start
EOT
end

PROFILE         = "home"
AMI             = "ami-fbebbefa" # dokku-20140630
                  # ami-bfdaa2be # ubuntu/images/hvm/ubuntu-precise-12.04-amd64-server-20140428
IAM_ROLE        = "arn:aws:iam::302521238288:instance-profile/dokku"
TYPE            = "one-time"     # one-time or persistent
KEYPAIR         = "tatsuya"
USER_DATA       = `echo "#{userdata_script}" | openssl enc -base64`
REGION          = "ap-northeast-1"
SECURITY_GROUPS = "sg-eba2418e"
SUBNET_ID       = "subnet-4972280f"
EBS_OPTIMIZE    = false
MNT_EBS_VOL     = "vol-a7a17da1"

def make_spot_req instance_type, price, av_zone
  json = {
    "ImageId"             => AMI,
    "KeyName"             => KEYPAIR,
    "InstanceType"        => instance_type,
    "UserData"            => USER_DATA,
    "SecurityGroupIds"    => [
                              SECURITY_GROUPS
                             ],
    "EbsOptimized"        => EBS_OPTIMIZE,
    "BlockDeviceMappings" => [
                              # {
                              #   "DeviceName" => "/dev/sda1",
                              #   "Ebs"        => {
                              #     "VolumeSize"          => 10,
                              #     "SnapshotId"          => ROOT_EBS_SNAP,
                              #     "DeleteOnTermination" => false,
                              #     "VolumeType"          => "gp2"
                              #   }
                              # },
                              {
                                "DeviceName"  => "/dev/sdb",
                                "VirtualName" => "ephemeral0"
                              }
                             ]
  }

  json["IamInstanceProfile"] = {"Arn" => IAM_ROLE} if IAM_ROLE
  json["SubnetId"]           = SUBNET_ID           if SUBNET_ID

  open("/tmp/launch_config.json", "w") do |file|
    file.write json.to_json
  end

  spot_req = `aws --profile #{PROFILE} ec2 request-spot-instances --spot-price #{price} --region #{REGION} --availability-zone-group #{av_zone} --type #{TYPE} --launch-specification file:///tmp/launch_config.json`
  JSON.parse(spot_req)['SpotInstanceRequests'].first
end

def fetch_spot_req id
  spot_req = `aws --profile #{PROFILE} ec2 describe-spot-instance-requests`
  candidate = JSON.parse(spot_req)['SpotInstanceRequests']
  candidate.find do |r|
    r['SpotInstanceRequestId'] == id
  end
end

def attach_ebs instance, vol_id, device
  attach_req = `aws --profile #{PROFILE} ec2 attach-volume --volume-id #{vol_id} --instance-id #{instance} --device #{device}`
  JSON.parse attach_req
end

def describe_instance instance_id
  ec2_res = `aws --profile #{PROFILE} ec2 describe-instances --instance-ids #{instance_id}`
  JSON.parse(ec2_res)['Reservations'].first['Instances'].first
end

def associate_ip instance_id, allocation_id
  ip_res = `aws --profile #{PROFILE} ec2 associate-address --instance-id #{instance_id} --allocation-id #{allocation_id}`
  JSON.parse ip_res
end

# ------------------------------------------------------------------------------------------------------
# main
# ------------------------------------------------------------------------------------------------------

@opts = Slop.parse(help: true, strict: true) do
  banner 'Usage: spot-boot.rb [options]'

  on 'i', 'instance_type=', 'Instance type'
  on 'p', 'price=',         'Bet price $/hour'
  on 'z', 'zone=',          'Availability Zone'
  on 's', 'spot_req=',      'Spot-request Id, already submitted'
  on 'n', 'ip=',            'Associate the EIP of association_id'
end

if @opts[:spot_req]
  @spot_req_id = @opts[:spot_req]
else
  spot_req = make_spot_req @opts[:instance_type], @opts[:price], @opts[:zone]
  @spot_req_id = spot_req['SpotInstanceRequestId']
  sleep 5
end

begin
  spot_req = fetch_spot_req(@spot_req_id)
  puts "spot-req ##{spot_req['SpotInstanceRequestId']} - #{spot_req['Status']['Code']} - #{spot_req['Status']['Message']}"
  sleep 5
end while spot_req['Status']['Code'] != 'fulfilled'

instance_id = spot_req['InstanceId']
puts instance_id

begin
  instance = describe_instance instance_id
  puts "instance ##{instance_id} - #{instance['State']['Name']}"
  sleep 5
end while instance['State']['Name'] != 'running'

unless instance['BlockDeviceMappings'].find{|v| v['DeviceName'] == '/dev/sdf' }
  ebs_req = attach_ebs instance_id, MNT_EBS_VOL, '/dev/sdf'
  p ebs_req
end

if @opts[:ip]
  ip_req = associate_ip instance_id, @opts[:ip]
  p ip_req
end
