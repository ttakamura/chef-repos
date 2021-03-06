INSTANCE_TYPE=$1         # c3.2xlarge
PRICE=$2                 # 0.1

PROFILE="home"
AMI="ami-bfdaa2be"       # Ubuntu 14.04 HVM
IAM_ROLE="arn:aws:iam::302521238288:instance-profile/dokku"
TYPE="one-time"          # or persistent
KEYPAIR="tatsuya"
USER_DATA=`echo "" | openssl enc -base64`
REGION="ap-northeast-1"
SECURITY_GROUPS="sg-eba2418e"
SUBNET_ID="subnet-4972280f"
AV_ZONE="ap-northeast-1c"


### jq check
JQ_COMMAND=`which jq`
if [ -z ${JQ_COMMAND} ]; then
    echo "jq command not found"
    exit 1
fi

### SET JSON
rm -f /tmp/launch_config.json
cat << EOF >> /tmp/launch_config.json
{
  "ImageId": "${AMI}",
  "KeyName": "${KEYPAIR}",
  "InstanceType": "${INSTANCE_TYPE}",
  "SubnetId": "${SUBNET_ID}",
  "UserData": "${USER_DATA}",
  "SecurityGroupIds": [
    "${SECURITY_GROUPS}"
  ],
  "IamInstanceProfile": {
    "Arn":"${IAM_ROLE}"
  },
  "BlockDeviceMappings": [
    {
      "DeviceName": "/dev/sda1",
      "Ebs": {
        "VolumeSize": 10,
        "DeleteOnTermination": false,
        "VolumeType": "gp2"
      }
    },
    {
      "DeviceName": "/dev/sdb",
      "VirtualName": "ephemeral0"
    },
    {
      "DeviceName": "/dev/sdc",
      "VirtualName": "ephemeral1"
    }
  ]
}
EOF

#
# "Ebs":
#   "SnapshotId": "string",
#
#    {
#      "DeviceName": "/dev/sdf",
#      "Ebs": {
#        "VolumeSize": ${EBS_SNAPSHOT_SIZE},
#        "SnapshotId": "${EBS_SNAPSHOT}",
#        "DeleteOnTermination": false,
#        "VolumeType": "gp2"
#      }
#    }


### PUT SPOT_REQUEST
aws --profile ${PROFILE} ec2 request-spot-instances --spot-price ${PRICE} --region ${REGION} --availability-zone-group ${AV_ZONE} --type ${TYPE} --launch-specification file:///tmp/launch_config.json > /tmp/spot_request.json
SIR_ID=`jq '.SpotInstanceRequests[0] | .SpotInstanceRequestId' /tmp/spot_request.json --raw-output`

echo "[INFO] SpotInstanceRequestID: ${SIR_ID}";
sleep 7

### GET SPOT_INSTANCE INSTANCE_ID
rm -f /tmp/spot_instance.json

aws ec2 describe-spot-instance-requests --spot-instance-request-ids ${SIR_ID} --region ${REGION} > /tmp/spot_instance.json
INSTANCE_ID=`jq '.SpotInstanceRequests[0] | .InstanceId' /tmp/spot_instance.json --raw-output`

while [ "${INSTANCE_ID}" == "null" ]
do
    aws ec2 describe-spot-instance-requests --spot-instance-request-ids ${SIR_ID} --region ${REGION} > /tmp/spot_instance.json
    INSTANCE_ID=`jq '.SpotInstanceRequests[0] | .InstanceId' /tmp/spot_instance.json --raw-output`

    sleep 10
done

echo "[INFO] INSTANCE_ID: ${INSTANCE_ID}";
