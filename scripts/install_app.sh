#!/bin/bash

set -e # Stop script if any command fails

echo "Waiting for apt locks to release..."

API_S3_BUCKET="${api_s3_bucket}"
API_ARTIFACT_NAME="${api_artifact_name}"
API_ARTIFACT_FOLDER="${api_artifact_folder}"
APP_S3_BUCKET="${app_s3_bucket}"
APP_ARTIFACT_NAME="${app_artifact_name}"

# ensuring to use IPv4 and waiting for background system updates to finish
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done

# ensure unzip and awscli are installed (required for S3 and zip files)
sudo apt update -y # sudo apt-get update -y
# sudo DEBIAN_FRONTEND=noninteractive apt-get install -y unzip curl wget

# getting to home directory
cd /home/ubuntu/

# installing aws cli : official installation method
# installing required dependencies
sudo apt install curl unzip -y

# downloading the aws cli installer
# checking architecture with uname -m, to verify
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip # x86_64 installer
# curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o awscliv2.zip # aarch64 installer

# extracting and running the installer
unzip awscliv2.zip
sudo ./aws/install

# cleaning up the downloaded files
rm -rf awscliv2.zip aws/

# if want to, very the aws cli veriin
# aws --version

# there is also antoher method to install aws clo using Snap store (but not recommended)


# download .net 9 runtime
wget https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/9.0.11/aspnetcore-runtime-9.0.11-linux-x64.tar.gz

# unzip the downloaded .net 9 runtime zip file
mkdir -p /home/ubuntu/dotnet
tar zxf aspnetcore-runtime-9.0.11-linux-x64.tar.gz -C /home/ubuntu/dotnet

# set environment variables for .net 9 runtime
export DOTNET_ROOT=/home/ubuntu/dotnet
export PATH=$PATH:/home/ubuntu/dotnet

# remove the downloaded .net 9 runtime zip file
rm aspnetcore-runtime-9.0.11-linux-x64.tar.gz

# to make the export and path available for each ec2 user login
echo "export DOTNET_ROOT=/home/ubuntu/dotnet" >> /home/ubuntu/.bashrc #.bash_profile .bashrc
echo "export PATH=\$PATH:/home/ubuntu/dotnet" >> /home/ubuntu/.bashrc #.bash_profile .bashrc

# create a directory for the millstack web api project and run the project
mkdir -p /home/ubuntu/millstack-ec2
cd /home/ubuntu/millstack-ec2

# pulling the published zip file from S3 bucket
# aws s3 cp s3://millstack-aspnet-web-api/Misstak_Publish.zip .
aws s3 cp s3://$API_S3_BUCKET/$API_ARTIFACT_NAME .
unzip -o $API_ARTIFACT_NAME # -o : overrides if files already exists
mv $API_ARTIFACT_FOLDER/* .
# rm $API_ARTIFACT_FOLDER.zip
rm -rf $API_ARTIFACT_FOLDER $API_ARTIFACT_NAME

# getting .env file
aws s3 cp s3://$APP_S3_BUCKET/$APP_ARTIFACT_NAME .


# CREATE SYSTEMD SERVICE (The "Background" Logic)
sudo cat <<EOT > /etc/systemd/system/millstack.service
[Unit]
Description=Millstack .NET Web API Service
After=network.target

[Service]
WorkingDirectory=/home/ubuntu/millstack-ec2
ExecStart=/home/ubuntu/dotnet/dotnet /home/ubuntu/millstack-ec2/Millstack-WebAPI.dll --urls "http://0.0.0.0:7080"
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=millstack-api
User=ubuntu
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_ROOT=/home/ubuntu/dotnet

[Install]
WantedBy=multi-user.target
EOT

# tart the service
sudo chown -R ubuntu:ubuntu /home/ubuntu/millstack-ec2 /home/ubuntu/dotnet
sudo systemctl daemon-reload
sudo systemctl enable millstack.service
sudo systemctl start millstack.service



# run the project on a particualr port number
# dotnet Millstack-WebAPI.dll --urls "http://*:7080;"