# syntax = tonistiigi/dockerfile:runmount20180618 # enables --mount option for run
#FROM jimschubert/8-jdk-alpine-mvn:1.0
#FROM localstack/java-maven-node-python
FROM ubuntu:18.04

RUN --mount=target=/polycube-codegen cp -r /polycube-codegen /tmp/polycube-codegen && \
cd /tmp/polycube-codegen && SUDO="" ./install.sh && apt-get clean && \
rm -fr /root /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV POLYCUBE_IN_DOCKER="true"
ENTRYPOINT ["polycube-codegen"]
