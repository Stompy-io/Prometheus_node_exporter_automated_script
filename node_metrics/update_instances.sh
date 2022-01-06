#!/bin/bash

node_metrics_dir=/home/ubuntu/node_metrics

# Clear instances.txt file
cat /dev/null > $node_metrics_dir/instances.txt

aws ec2 describe-instances --region ap-southeast-1 | jq .Reservations[].Instances[].PublicIpAddress | sed 's/\"//' | sed 's/\"//' > $node_metrics_dir/public_IP.txt

# Remove all instance string after prom-server in prometheus.yml
sed -i '1,/prom-server/!d' /etc/prometheus/prometheus.yml

echo -e "prom-server\nprom-target" > $node_metrics_dir/instances.txt

while read -r public_ip; do

check_connectivity=$(nc -v $public_ip 9100 -w 1 > /dev/null 2>&1)
if [ $? -eq 0 ];then
(( instance_num=instance_num+1 ))

cat << EOF >> $node_metrics_dir/prometheus.yml
    - targets: ['$public_ip:9100']
      labels:
        instance: "instance-${instance_num}"
EOF

echo "instance-${instance_num}" >> $node_metrics_dir/instances.txt
else
  echo "Skipping $public_ip since it is not able to connect on port 9100"
fi

done < $node_metrics_dir/public_IP.txt

# Restart prometheus service
echo "Restarting prometheus service"
sudo systemctl restart prometheus
echo "Ending script..."