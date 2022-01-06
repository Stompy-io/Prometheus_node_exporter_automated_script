#!/bin/bash

node_metrics_dir=/home/ubuntu/node_metrics
metric_values_dir=$node_metrics_dir/metric_values
daily_upload_dir=$node_metrics_dir/metric_values/daily_dump
s3_bucket_dir=s3://stompy-prom-thanos-metrics/node_metrics/

# Extract all instances with labels in prometheus.yml
# grep instance /etc/prometheus/prometheus.yml | awk -F':' '{print $2}' | sed 's/"//g' | tr -d [[:blank:]] > $node_metrics_dir/instances.txt

# Extract all node_exporter metrics
curl -s http://localhost:9090/api/v1/label/__name__/values | jq . | grep node | sed -e 's/"//' -e 's/"//' -e 's/,//' | tr -d [[:blank:]] > $node_metrics_dir/node_metrics.json

create_folders() {
  # Create instance label folders and node exporter folders
  while read -r instance_label; do
    if [ ! -d $metric_values_dir/$instance_label ]; then
      mkdir $metric_values_dir/$instance_label
        while read -r metric; do
          if [ ! -d $metric_values_dir/$instance_label/$metric ]; then
            mkdir $metric_values_dir/$instance_label/$metric
          else
            echo "Directory exists" > /dev/null 2>&1
          fi
        done < $node_metrics_dir/node_metrics.json
    else
      echo "Directory exists" > /dev/null 2>&1
    fi
  done < $node_metrics_dir/instances.txt

  # Create daily dump directory
  if [ ! -d $daily_upload_dir ]; then
    mkdir $daily_upload_dir
  else
    echo "Directory exists" > /dev/null 2>&1
  fi
}


extract_node_exporter_values() {
  # Extract node exporter metrics
  while read -r instance_label; do
    while read -r metric; do
      curl -s "http://localhost:9090/api/v1/query?query=${metric}%7Binstance%3D%22${instance_label}%22%7D" | jq .data.result[] > $metric_values_dir/$instance_label/$metric/$metric.`date +%F`_`date +%T`.json;
      curl -s "http://localhost:9090/api/v1/query?query=${metric}%7Binstance%3D%22${instance_label}%22%7D" | jq .data.result[] >> $daily_upload_dir/${instance_label}_compiled_metrics.`date +%F`.json
    done < $node_metrics_dir/node_metrics.json
  done < $node_metrics_dir/instances.txt
}


upload_to_s3() {
  date_yesterday=`date +%F -d "yesterday"`
  aws s3 sync $metric_values_dir/daily_dump s3://stompy-prom-thanos-metrics/node_metrics/ --exclude "*" --include "*${date_yesterday}*"

  # Remove yesterdays node_exporter json files
  rm -rf $metric_values_dir/*/*/*${date_yesterday}* > /dev/null 2>&1
}


# Start of bash script
create_folders

if [ "$1" = "extract" ]; then
  extract_node_exporter_values
elif [ "$1" = "upload" ]; then
  upload_to_s3
else
   echo "No parameter given, please indicate either extract or upload, e.g. ./$0 extract or ./$0 upload"
fi