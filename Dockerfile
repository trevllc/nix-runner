ARG SYSTEMD_VERSION="255.4-1ubuntu8.12" # ubuntu/noble-updates/systemd
ARG CURL_VERSION="8.5.0-2ubuntu10.6" # ubuntu/noble-updates/curl
ARG GIT_VERSION="1:2.43.0-1ubuntu7.3" # ubuntu/noble-updates/git
ARG CA_CERTIFICATES_VERSION="20240203" # ubuntu/noble/ca-certificates
ARG NIX_INSTALLER_VERSION="3.15.2" # github-tags/DeterminateSystems/nix-installer&versioning=semver

FROM ubuntu:24.04@sha256:cd1dba651b3080c3686ecf4e3c4220f026b521fb76978881737d24f200828b2b

# Apt
ARG SYSTEMD_VERSION
ARG CURL_VERSION
ARG GIT_VERSION
ARG CA_CERTIFICATES_VERSION
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        systemd=${SYSTEMD_VERSION} \
        curl=${CURL_VERSION} \
        git=${GIT_VERSION} \
        ca-certificates=${CA_CERTIFICATES_VERSION} && \
    rm -rf /var/lib/apt/lists/*

# Nix
ARG NIX_INSTALLER_VERSION
RUN curl -o nix-installer-x86_64-linux -L "https://github.com/DeterminateSystems/nix-installer/releases/download/v${NIX_INSTALLER_VERSION}/nix-installer-x86_64-linux" && \
    chmod +x ./nix-installer-x86_64-linux && \
    ./nix-installer-x86_64-linux install linux \
        --extra-conf "sandbox = false" \
        --extra-conf "accept-flake-config = true" \
        --extra-conf "always-allow-substitutes = true" \
        --extra-conf "trusted-users = @nix" \
        --extra-conf "max-silent-time = 300" \
        --extra-conf "fallback = true" \
        --extra-conf "eval-cores = 0" \
        --no-start-daemon \
        --no-confirm && \
    rm ./nix-installer-x86_64-linux
ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"

# Deps
COPY ./flake.nix /runner/flake.nix
RUN nix profile add --inputs-from /runner \
    nixpkgs#github-runner \
    nixpkgs#gitea-actions-runner \
    nixpkgs#nodejs_24 \
    nixpkgs#xz \
    nixpkgs#gh \
    nixpkgs#jq \
    nixpkgs#jc && \
    nix profile add --priority 10 --inputs-from /runner nixpkgs#forgejo-runner

WORKDIR /runner
COPY ./runner/token.sh /runner/token
COPY ./runner/run.sh /runner/run
COPY ./runner/backup.sh /runner/backup
COPY ./runner/start.sh /runner/start
ENTRYPOINT [ "/runner/start" ]