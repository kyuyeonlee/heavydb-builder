FROM nvidia/cuda:11.0.3-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install general dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    software-properties-common \
    wget \
    curl \
    git \
    unzip \
    pkg-config \
    lsb-release \
    ca-certificates \
    libssl-dev \
    zlib1g-dev \
    libtinfo-dev \
    libncurses5-dev \
    libedit-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    sudo \
    python3 \
    python3-pip \
    openjdk-11-jdk \
    gcc-8 g++-8 \
    libthrift-dev \
    thrift-compiler \
    libblosc-dev \
    librdkafka-dev \
    libxerces-c-dev

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 80

# CMake >= 3.16
RUN wget https://github.com/Kitware/CMake/releases/download/v3.21.0/cmake-3.21.0-linux-x86_64.sh \
 && chmod +x cmake-3.21.0-linux-x86_64.sh \
 && ./cmake-3.21.0-linux-x86_64.sh --skip-license --prefix=/usr/local \
 && rm cmake-3.21.0-linux-x86_64.sh

# LLVM 9.0
RUN wget https://apt.llvm.org/llvm.sh \
 && chmod +x llvm.sh \
 && ./llvm.sh 9 \
 && rm llvm.sh

# Set clang-9 as default if using clang
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-9 90 \
 && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-9 90

# Go 1.12+
RUN wget https://golang.org/dl/go1.17.13.linux-amd64.tar.gz \
 && tar -C /usr/local -xzf go1.17.13.linux-amd64.tar.gz \
 && rm go1.17.13.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Boost 1.72
RUN wget https://archives.boost.io/release/1.72.0/source/boost_1_72_0.tar.gz \
 && tar xfz boost_1_72_0.tar.gz \
 && cd boost_1_72_0 && ./bootstrap.sh && ./b2 install \
 && cd .. && rm -rf boost_1_72_0 boost_1_72_0.tar.gz

# gperftools
RUN apt-get update && apt-get install -y \
    autoconf automake libtool

RUN git clone https://github.com/gperftools/gperftools.git /tmp/gperftools \
 && cd /tmp/gperftools \
 && ./autogen.sh \
 && ./configure --prefix=/usr/local \
 && make -j$(nproc) \
 && make install \
 && ldconfig \
 && rm -rf /tmp/gperftools

# Arrow 3.0.0
RUN git clone https://github.com/apache/arrow.git -b apache-arrow-3.0.0 \
 && cd arrow/cpp && mkdir release && cd release \
 && cmake .. -DCMAKE_BUILD_TYPE=Release \
 && make -j$(nproc) && make install \
 && cd ../../../ && rm -rf arrow

# Dependencies that were not specified WTF!!!!!
RUN apt-get update && apt-get install -y \
 libarchive-dev \
 libbz2-dev \
 libclang-9-dev \
 libfmt-dev \
 maven \
 jq \
 doxygen

RUN git config --global --add safe.directory /workspace/heavydb
# Install dependencies needed for Arrow + CUDA
RUN apt-get update && apt-get install -y \
    libssl-dev zlib1g-dev liblz4-dev libzstd-dev libprotobuf-dev protobuf-compiler \
    libboost-all-dev cmake git curl unzip autoconf libtool \
    libgoogle-glog-dev libgflags-dev ninja-build

# Build Arrow with CUDA support
RUN git clone --branch apache-arrow-3.0.0 https://github.com/apache/arrow.git /tmp/arrow \
 && mkdir /tmp/arrow/cpp/build \
 && cd /tmp/arrow/cpp/build \
 && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DARROW_CUDA=ON \
    -DARROW_COMPUTE=ON \
    -DARROW_IPC=ON \
    -DARROW_PARQUET=ON \
    -DARROW_WITH_ZSTD=ON \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_BROTLI=ON \
    -DARROW_WITH_ZLIB=ON \
    -DCUDA_CUDA_LIBRARY=/usr/local/cuda/lib64/stubs/libcuda.so \
    -DARROW_CSV=ON \
    -DARROW_FILESYSTEM=ON \
 && make -j$(nproc) && make install \
 && ldconfig && rm -rf /tmp/arrow

RUN apt-get update && apt-get install -y python3 python3-dev python3-pip python-is-python3

# You would want to comment out "#include <tbb/version.h>" in Tests/TestHelpers.h
RUN apt-get update && apt-get install -y libtbb-dev libsnappy-dev libpng-dev

# Install PROJ dependencies
RUN apt-get update && apt-get install -y \
    sqlite3 \
    libsqlite3-dev \
    libtiff-dev \
    make

# Build and install PROJ 7.1.0
RUN curl -L https://download.osgeo.org/proj/proj-7.1.0.tar.gz | tar xz -C /tmp \
 && cd /tmp/proj-7.1.0 \
 && mkdir build && cd build \
 && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
 && make -j$(nproc) && make install \
 && ldconfig \
 && rm -rf /tmp/proj-7.1.0

# GDAL 3.1.3
RUN curl -LO https://download.osgeo.org/gdal/3.1.3/gdal-3.1.3.tar.gz \
 && tar xzf gdal-3.1.3.tar.gz && cd gdal-3.1.3 \
 && ./configure --prefix=/usr/local \
 && make -j$(nproc) && make install && ldconfig

RUN apt-get update && apt-get install -y libpdal-dev

# dependencies for nsight (https://leimao.github.io/blog/Docker-Nsight-Systems/)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        dbus \
        fontconfig \
        gnupg \
        libasound2 \
        libfreetype6 \
        libglib2.0-0 \
        libnss3 \
        libsqlite3-0 \
        libx11-xcb1 \
        libxcb-glx0 \
        libxcb-xkb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxi6 \
        libxml2 \
        libxrandr2 \
        libxrender1 \
        libxtst6 \
        libgl1-mesa-glx \
        libxkbfile-dev \
        openssh-client \
        wget \
        xcb \
        xkb-data && \
    apt-get clean

RUN cd /tmp && \
    wget https://developer.nvidia.com/downloads/assets/tools/secure/nsight-systems/2023_4_1_97/nsight-systems-2023.4.1_2023.4.1.97-1_amd64.deb && \
    apt-get install -y ./nsight-systems-2023.4.1_2023.4.1.97-1_amd64.deb && \
    rm -rf /tmp/*

# Set environment variables if needed
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

CMD ["/bin/bash"]