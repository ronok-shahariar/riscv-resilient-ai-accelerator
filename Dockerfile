FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools and clean up apt cache in the same layer to minimize size
RUN apt-get update && apt-get install -y --no-install-recommends \
    iverilog \
    gcc-riscv64-unknown-elf \
    binutils-riscv64-unknown-elf \
    python3 \
    make \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Set working directory inside the container
WORKDIR /workspace