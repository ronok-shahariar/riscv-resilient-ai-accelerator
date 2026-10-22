FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y build-essential python3 python3-pip iverilog wget tar curl git && rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir cocotb
RUN mkdir -p /opt/riscv && wget -qO- https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2023.07.07/riscv32-elf-ubuntu-22.04-gcc-nightly-2023.07.07-nightly.tar.gz | tar -xz -C /opt/riscv --strip-components=1 || wget -qO- https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14.tar.gz | tar -xz -C /opt/riscv --strip-components=1
ENV PATH="/opt/riscv/bin:${PATH}"
WORKDIR /workspace
COPY . /workspace
