FROM ubuntu:24.04@sha256:c35e29c9450151419d9448b0fd75374fec4fff364a27f176fb458d472dfc9e54
RUN apt-get update && apt-get install -y curl=8.5.0-2ubuntu10.6 jq=1.7.1-3ubuntu0.24.04.1

# Install Nix
WORKDIR /init
RUN curl -o nix-installer-x86_64-linux -L https://github.com/DeterminateSystems/nix-installer/releases/download/v3.15.1/nix-installer-x86_64-linux && \
    chmod +x ./nix-installer-x86_64-linux && \
    ./nix-installer-x86_64-linux install linux \
        --extra-conf "sandbox = false" \
        --extra-conf "accept-flake-config = true" \
        --init none \
        --no-confirm && \
    rm ./nix-installer-x86_64-linux
ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"

# Install Runner
RUN curl -o actions-runner-x86_64-linux.tar.gz -L https://github.com/actions/runner/releases/download/v2.331.0/actions-runner-linux-x64-2.331.0.tar.gz && \
    tar xzf ./actions-runner-x86_64-linux.tar.gz && \
    ./bin/installdependencies.sh && \
    rm ./actions-runner-x86_64-linux.tar.gz
ENV RUNNER_ALLOW_RUNASROOT=1

COPY ./start.sh /start.sh
ENTRYPOINT [ "/start.sh" ]