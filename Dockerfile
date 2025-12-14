# syntax=docker/dockerfile:1

############################
# Stage 1: build llama.cpp #
############################
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION} AS llama-build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential cmake wget ca-certificates pkg-config \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# LunarG Vulkan repo (noble) via signed-by keyring
RUN set -eux; \
    wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc \
      | gpg --dearmor -o /usr/share/keyrings/lunarg-vulkan.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/lunarg-vulkan.gpg] https://packages.lunarg.com/vulkan/ noble main" \
      > /etc/apt/sources.list.d/lunarg-vulkan-noble.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends vulkan-sdk libcurl4-openssl-dev curl; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY llama.cpp /src/llama.cpp

WORKDIR /src/llama.cpp
RUN cmake -S . -B build \
      -DGGML_NATIVE=OFF \
      -DGGML_VULKAN=1 \
      -DLLAMA_CURL=1 \
    && cmake --build build --config Release -j"$(nproc)" \
    && mkdir -p /out/lib \
    && find build -name "*.so" -exec cp -v {} /out/lib/ \;

RUN mkdir -p /out/include \
    && (cp -av include/* /out/include/ 2>/dev/null || true) \
    && (cp -av ./*.h /out/include/ 2>/dev/null || true)


################################
# Stage 2: build azookey-swift #
################################
FROM ubuntu:24.04 AS azookey-build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
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
    libcurl4 \
    libvulkan1 \
    libsqlite3-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Swift 6.1
RUN wget -q https://download.swift.org/swift-6.1-release/ubuntu2404/swift-6.1-RELEASE/swift-6.1-RELEASE-ubuntu24.04.tar.gz \
    && tar xzf swift-6.1-RELEASE-ubuntu24.04.tar.gz -C /usr/local --strip-components=1 \
    && rm swift-6.1-RELEASE-ubuntu24.04.tar.gz

ENV PATH="/usr/local/usr/bin:/usr/local/bin:${PATH}"

WORKDIR /workspace
COPY azookey-swift /workspace

COPY --from=llama-build /out/lib/*.so /workspace/
COPY --from=llama-build /out/include /workspace/llama-include

# Build azookey-swift
RUN swift build -c release \
    -Xlinker -L/workspace \
    -Xlinker -rpath -Xlinker /workspace

RUN set -eux; \
    mkdir -p /export/libs; \
    find /usr/local/usr/lib/swift -name "*.so" -exec cp -v {} /export/libs/ \;; \
    cp -v /workspace/.build/release/libazookey-swift.so /export/libs/libazookey-swift.so


#########################################
# Stage 3: export only libs to the host #
#########################################
FROM scratch AS export

COPY --from=azookey-build /export/libs/ /libs/

