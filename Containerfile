# =========================================================
# Local-LLM - llama.cpp CPU runtime
# E1-03 - Containerfile
# =========================================================

# ---------------------------------------------------------
# Stage 1: Build
# ---------------------------------------------------------
FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

# IMPORTANTE:
# Fijar una versión/tag concreto evita construir siempre
# contra el HEAD cambiante del repositorio.
ARG LLAMA_CPP_TAG=b11193

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Código fuente versionado
RUN git clone \
        --depth 1 \
        --branch ${LLAMA_CPP_TAG} \
        https://github.com/ggml-org/llama.cpp.git \
        llama.cpp

WORKDIR /opt/llama.cpp

# Build CPU genérico.
# GGML_NATIVE=OFF evita generar código específico de la CPU
# donde se realiza el build.
RUN cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_NATIVE=OFF \
        -DLLAMA_BUILD_TESTS=OFF \
        -DLLAMA_CURL=OFF \
        -DGGML_BACKEND_DL=ON \
        -DGGML_CPU_ALL_VARIANTS=ON && \
    cmake --build build \
        --config Release \
        --target llama-server \
        -j2


# ---------------------------------------------------------
# Stage 2: Runtime
# ---------------------------------------------------------
FROM ubuntu:24.04 AS runtime

ARG DEBIAN_FRONTEND=noninteractive

# Únicamente dependencias necesarias para ejecutar
# llama-server.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgomp1 \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Runtime application
WORKDIR /app

COPY --from=builder \
    /opt/llama.cpp/build/bin/llama-server \
    /app/llama-server

# Bibliotecas GGML/llama.cpp generadas durante el build.
RUN mkdir -p /app/lib

# Runtime libraries
COPY --from=builder /opt/llama.cpp/build /tmp/llama-build

RUN find /tmp/llama-build \
        \( -type f -o -type l \) \
        -name "*.so*" \
        -exec cp -a {} /app/lib/ \; && \
    rm -rf /tmp/llama-build

ENV LD_LIBRARY_PATH=/app/lib

# ---------------------------------------------------------
# Security
# ---------------------------------------------------------

# Usuario sin privilegios
RUN useradd \
        --system \
        --create-home \
        --uid 10001 \
        --shell /usr/sbin/nologin \
        llama

# Punto de montaje externo para el modelo.
# El modelo NO forma parte de la imagen.
RUN mkdir -p /models && \
    chown llama:llama /models

USER 10001

# llama-server escuchará dentro del contenedor en 8080.
EXPOSE 8080

ENTRYPOINT ["/app/llama-server"]