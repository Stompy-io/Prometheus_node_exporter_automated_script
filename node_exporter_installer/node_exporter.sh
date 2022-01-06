#!/bin/bash

node_exporter_dir=/opt/node_exporter
default_user_group_file=./default/user_group.txt
default_version_file=./default/version.txt
default_systemd_file=./default/systemd.txt
systemd_path=/etc/systemd/system/node-exporter.service
datenow=$(date "+%F %T")

# Set user and group with uid and gid based on the provided default file
user=$(grep user $default_user_group_file | awk -F'=' '{print $2}' | awk -F':' '{print $1}')
uid=$(grep user $default_user_group_file | awk -F'=' '{print $2}' | awk -F':' '{print $2}')
group=$(grep group $default_user_group_file | awk -F'=' '{print $2}' | awk -F':' '{print $1}')
gid=$(grep group $default_user_group_file | awk -F'=' '{print $2}' | awk -F':' '{print $2}')

# Set the version based on the provided default file
version=$(grep version $default_version_file | awk -F'=' '{print $2}')

# Install node exporter agent
node_exporter_installation() {
  sudo -u $user bash -c "wget -q https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-1.3.1.linux-amd64.tar.gz --directory $node_exporter_dir"
  sudo -u $user bash -c "tar xvfz $node_exporter_dir/node_exporter-${version}.linux-amd64.tar.gz --directory $node_exporter_dir"
  sudo -u root bash -c "sed -e 's/<node_exporter_directory>/\/opt\/node_exporter/' -e 's/<version>/${version}/' $default_systemd_file > $systemd_path"
}

create_node_exporter_dir(){
  sudo mkdir $node_exporter_dir
  sudo chown $user:$group $node_exporter_dir
  echo "$datenow - [INFO] - Done node_exporter directory has been created and ownership has been changed. Proceeding..."
}

# Check if directory $node_exporter_dir already exists
check_node_exporter_dir() {
  if [ -d "$node_exporter_dir" ]; then
    echo "$datenow - [ERROR] - $node_exporter_dir already exists, if you want to remove this package then run ./node_exporter_v2.sh remove or reinstall by running the command ./node_exporter_v2.sh reinstall"
        exit
  else
    echo "$datenow - [INFO] - Done checking, directory does not exist. Proceeding..."
  fi
}

# Create node_exporter user and group
create_node_exporter_user_group() {
  sudo groupadd -g $gid $group
  sudo useradd -u $uid $user -g $group
}

# Check if user/group and uid/gid exists else create them
check_user_group() {
  if [ ! -z $(grep $user /etc/passwd | awk -F':' '{print $1}') ]; then
    echo "$datenow - [ERROR] - $user already exists please use another user that will run node-exporter agent by updating $default_user_group_file user parameter"
        exit
  elif [ ! -z $(grep $uid /etc/passwd | awk -F':' '{print $3}') ]; then
    echo "$datenow - [ERROR] - $uid already exists please use another uid that will run node-exporter agent by updating $default_user_group_file user parameter"
        exit
  elif [ ! -z $(grep $group /etc/group | awk -F':' '{print $1}') ]; then
    echo "$datenow - [ERROR] - $group already exists please use another group that will run node-exporter agent by updating $default_user_group_file group parameter"
        exit
  elif [ ! -z $(grep $gid /etc/group | awk -F':' '{print $3}') ]; then
    echo "$datenow - [ERROR] - $gid already exists please use another gid that will run node-exporter agent by updating $default_user_group_file group parameter"
        exit
  else
    echo "$datenow - [INFO] - Done checking, user and group does not exist. Proceeding..."
  fi
}

# Remove node exporter agent
remove_node_exporter() {
  echo "$datenow - [INFO] - Stopping node-exporter agent"
  sudo systemctl stop node-exporter
  echo "$datenow - [INFO] - Removing auto start of node-exporter agent service"
  sudo systemctl disable node-exporter
  echo "$datenow - [INFO] - Removing node exporter user and group"
  sudo userdel -rf $user > /dev/null 2>&1
  sudo groupdel $group > /dev/null 2>&1
  echo "$datenow - [INFO] - Removing node exporter directory"
  sudo rm -rf $node_exporter_dir > /dev/null 2>&1
  echo "$datenow - [INFO] - Removing node exporter systemd service file"
  sudo rm -rf $systemd_path > /dev/null 2>&1
  echo "$datenow - [INFO] - Reloading systemd daemon"
  sudo systemctl daemon-reload
}

# Install node exporter agent
install_node_exporter() {
  echo "$datenow - [INFO] - Checking default node_exporter user and group if exists..."
  check_user_group
  echo "$datenow - [INFO] - Creating user and groups for node_exporter..."
  create_node_exporter_user_group
  echo "$datenow - [INFO] - Checking default $node_exporter_dir if exists..."
  check_node_exporter_dir
  echo "$datenow - [INFO] - Creating directory and assigning $user as its owner and $group as its group"
  create_node_exporter_dir
  echo "$datenow - [INFO] - Installing node exporter version $version"
  node_exporter_installation
  echo "$datenow - [INFO] - Adding auto start of node-exporter agent service"
  sudo systemctl enable node-exporter
  echo "$datenow - [INFO] - Reloading systemd daemon"
  sudo systemctl daemon-reload
  echo "$datenow - [INFO] - Done installation, you may now try starting the node exporter agent by running sudo systemctl start node-exporter or if this is a reinstall then restart by running sudo systemctl restart node-exporter"
}

#User option to either install, remove or reinstall node-exporter package
if [ "$1" = "install" ]; then
  install_node_exporter
elif [ "$1" = "remove" ]; then
  remove_node_exporter
elif [ "$1" = "reinstall" ]; then
  remove_node_exporter
  install_node_exporter
else
  echo "To run the script use $0 install/remove/reinstall with only 1 parameter. eg. ($0 install)"
fi