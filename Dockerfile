ARG CURL_VERSION="8.5.0-2ubuntu10.6" # ubuntu/curl
ARG GIT_VERSION="1:2.43.0-1ubuntu7.3" # ubuntu/git
ARG JQ_VERSION="1.7.1-3ubuntu0.24.04.1" # ubuntu/jq
ARG GH_VERSION="2.45.0-1ubuntu0.3" # ubuntu/gh
ARG CERTIFICATES_VERSION="20240203" # ubuntu/ca-certificates
ARG INSTALLER_VERSION="3.15.1" # github-tags/DeterminateSystems/nix-installer&versioning=semver
ARG RUNNER_VERSION="2.331.0" # github-tags/actions/runner&versioning=semver

FROM ubuntu:24.04@sha256:c35e29c9450151419d9448b0fd75374fec4fff364a27f176fb458d472dfc9e54
# Apt
ARG CURL_VERSION
ARG GIT_VERSION
ARG JQ_VERSION
ARG GH_VERSION
ARG CERTIFICATES_VERSION
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl=${CURL_VERSION} \
        git=${GIT_VERSION} \
        jq=${JQ_VERSION} \
        gh=${GH_VERSION} \
        ca-certificates=${CERTIFICATES_VERSION} && \
    rm -rf /var/lib/apt/lists/*

# Nix
ARG INSTALLER_VERSION
WORKDIR /init
RUN curl -o nix-installer-x86_64-linux -L "https://github.com/DeterminateSystems/nix-installer/releases/download/v${INSTALLER_VERSION}/nix-installer-x86_64-linux" && \
    chmod +x ./nix-installer-x86_64-linux && \
    ./nix-installer-x86_64-linux install linux \
        --extra-conf "sandbox = false" \
        --extra-conf "accept-flake-config = true" \
        --init none \
        --no-confirm && \
    rm ./nix-installer-x86_64-linux
ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"

# Runner
ARG RUNNER_VERSION
RUN curl -o actions-runner-x86_64-linux.tar.gz -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" && \
    tar xzf ./actions-runner-x86_64-linux.tar.gz && \
    ./bin/installdependencies.sh && \
    rm ./actions-runner-x86_64-linux.tar.gz
ENV RUNNER_ALLOW_RUNASROOT=1

COPY ./start.sh /start.sh
ENTRYPOINT [ "/start.sh" ]