FROM ubuntu:latest
MAINTAINER sherafat.us@gmail.com

# Install octave and curl
RUN apt-get update && \
    apt-get install -y octave curl lsb-base lsb-release

# Install Google Cloud SDK (instructions here: https://cloud.google.com/sdk/downloads#apt-get)
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | \
        tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
        apt-key add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk

EXPOSE 80 443
