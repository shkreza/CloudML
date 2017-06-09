# CloudML

## Setup
Allocate a desired number of Droplets with the Docker image (currently 17.05.0-ce). Once the Droplets are initialized, ssh to one that acts as lead swarm manager and execute:
```
# get the machine's advertisable IP address
ifconfig

# initialize docker swarm
docker swarm init --advertise-addr <IP>

# retrieve registration tokens for workers to join the swarm
docker swarm join-token worker

# open the port manager listens on
ufw allow <PORT>
```

The last command produces the command to run on workers to join the swarm that is managed by the manager. Run it on the worker droplets:
```
# have woker join the swarm
docker swarm join \
           --token <TOKEN> \
           <IP>:<PORT>
```

Your wokder/manager swarm is now set up.

## Docker image
The docker image that runs your ML code must have the prerequisite binaries - in this case, I intend to run Octave code, so I use a docker image that I built with Octave installed. Additionally, I use Google Cloud storage to store my octave code, which will be downloaded at runtime to the running containers. I thereofre also build the image with GCP SDK installed.

A prepared Docker image is published at my [Docker hub](https://hub.docker.com/r/shkreza/octave-gcloud/). You can retrieve it using `docker pull shkreza/octave-gcloud` or alternatively build your own images using the following Dockerfile:
```
FROM ubuntu:latest
MAINTAINER sherafat.us@gmail.com

# Install dependencies needed
RUN apt-get update && \
    apt-get install -y curl lsb-base lsb-release

# Install octave
RUN apt-get install -y octave

# Install Google Cloud SDK (instructions here: https://cloud.google.com/sdk/downloads#apt-get)
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | \
        tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
        apt-key add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk

# Expose useful ports
EXPOSE 80 443 22
```

## Service definitions
The ML code you intend to run should be available inside the container. You can use Google Cloud storage bucket, as I did below. You need to upload your octave code and data to a `BUCKET` and use the code below when starting your container to download it.

Downloading the octave code takes place as part of start-up of your container, which when in swarm mode, runs as a service in one of the worker nodes.

Therefore, assuming you have completed the swarm setup (steps above) you can define the service and its start-up code as follows. Once the code is downlaoded octave is launched in `--no-gui` mode by passing in the `.m` file for your ML model.
```
# Define docker service with your image (use your own custom image or shkreza/octave-gcloud)
docker service --name <MY_ML_SERVICE> <IMAGE> \
    /bin/bash -c " \
        # Set your project \
        gcloud config set project <GC_PROJECT> \
        \
        # Download octave code from bucket to your destination folder in the container \
        gsutil cp -r gs://<BUCKET> <DST_FOLDER> \
        \
        # Run Octave in --no-gui mode
        cd <DST_FOLDER>
        octave --no-gui <ML_FILE>.m
```

## Execution
Docker swarm manager will automaticallly assign your service/task to one of its workers, download the image and start its execution.

You can view the progress of the execution by monitoring the console output (in future, I will improve this area by allowing execution results to be pushed to a final bucket).
```
docker service logs <MY_ML_SERVICE>
```
