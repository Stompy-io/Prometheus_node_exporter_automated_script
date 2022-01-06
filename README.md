## Node Exporter
### How to Install
1. cd node_exporter_installer
2. ./node_exporter.sh (install/remove/reinstall)

### Default values
1. It will auto create linux user/group named node_exporter with uid and gid of 1001
2. The node_exporter directory is located in /opt/node_exporter/node_exporter-$version.linux-amd64 (e.g. /opt/node_exporter/node_exporter-1.3.1.linux-amd64)
3. The current default version is 1.3.1
4. NOTE: If you want to update the user/group and uid/gid just go to default/user_group.txt and update the corresponding user/group/uid/gid for your preference
5. NOTE: If you want to update the version to be installed just go to default/version.txt and update the version of node-exporter you want to install depending on your preference

### Run node exporter
1. Start node exporter
  - sudo systemctl start node-exporter
2. Check node exporter status
  - sudo systemctl status node-exporter
3. Stop node exporter
  - sudo systemctl stop node-exporter

### How to check what metrics will be sent
1. curl http://localhost:9100/metrics


## Prometheus auto add of instances
- For initial setup of node_exporter.sh, first you need to copy prometheus.yml in /etc/prometheus/prometheus.yml of the prometheus server. Once done you may now copy update instances.sh which will generate the txt files needed for node-exporter extractor else this script will fail.
- Additional note is that the script only detects instances that has public IP addresses and will not included in the list if has private IP only, if private IP will be used then there is a change needed on the script.


## Prometheus node-exporter extractor 
1. Extractor script(extract_node_metrics.sh) always run every minute 5 on 24/7 setup
2. Note that you need to create /metric_values, if not existing, since this will contain the metrics extracted from node-exporter and contains the dump json files to be uploaded daily
3. Daily upload runs at 12:08 daily so that it will have enough time to gather all metric data and will only upload yesterdays time prior to the execution time
4. All json files from extrcator script generated every minute 5 are dumped in /metric_values/<prometheus-target-label>/<node-exporter-metric> with filename containing date and time.
5. All json files consisting of compiled metrics that is uploaded every 12:10 daily are dumped in /metric_values/daily_dump and uploaded into s3://stompy-prom-thanos-metrics/node_metrics s3 bucket
6. All json files consisting of compiled metrics with yesterdays date are deleted