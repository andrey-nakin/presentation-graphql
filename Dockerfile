FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive

RUN	\
	apt-get update \
#	&& apt-get -qq -y upgrade \
	&& apt-get -qq -y install texlive-full

RUN mkdir /app

WORKDIR /app

