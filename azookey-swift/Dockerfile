FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    clang \
    pkg-config \
    libicu-dev \
    libncurses5-dev \
    libxml2-dev \
    binutils \
    libblocksruntime-dev \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://download.swift.org/swift-6.1-release/ubuntu2404/swift-6.1-RELEASE/swift-6.1-RELEASE-ubuntu24.04.tar.gz && \
    tar xzf swift-6.1-RELEASE-ubuntu24.04.tar.gz -C /usr/local --strip-components=1 && \
    rm swift-6.1-RELEASE-ubuntu24.04.tar.gz

ENV PATH="/usr/local/usr/bin:/usr/local/bin:${PATH}"

WORKDIR /workspace
COPY . /workspace

RUN swift build -c release -Xlinker -L/workspace
