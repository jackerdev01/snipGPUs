# snipGPU for anyone's machine: the Linux build from this repo's Releases (a compiled program), nothing else.
# The user's files live in /data (a volume): config_*.yaml, .env, SSH key, state, logs. First start creates them and
# stops until .env and the wallets are filled. Built and pushed by .github/workflows/docker.yml on each release.
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY snipgpu-linux /app/snipgpu
RUN chmod 755 /app/snipgpu
ENV SNIPVAST_PACKAGED=1 \
    SNIPVAST_DATA_DIR=/data
# root: a ./data bind mount created by Docker on a Linux host belongs to root
VOLUME /data
WORKDIR /data
ENTRYPOINT ["/app/snipgpu"]
