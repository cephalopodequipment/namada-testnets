FROM rust:1-bullseye AS build-env-rust
ARG TAG
WORKDIR /root
RUN apt-get update && apt-get install -y libclang-dev
RUN rustup default nightly && rustup component add rustfmt --toolchain nightly
RUN git clone https://github.com/anoma/namada.git
RUN cd namada && git checkout $TAG && make build-release


FROM golang:1.19-bullseye AS build-env-go
ARG TENDERMINT_TAG
WORKDIR /root
RUN git clone https://github.com/heliaxdev/tendermint.git
RUN cd tendermint && git checkout $TENDERMINT_TAG && make build

FROM debian:bullseye-slim
RUN useradd -m namada -s /bin/bash
ARG TENDERMINT_TAG
WORKDIR /home/namada
COPY --chown=0:0 --from=build-env-rust /root/namada/target/release/namada /usr/bin/namada
COPY --chown=0:0 --from=build-env-rust /root/namada/target/release/namadac /usr/bin/namadac
COPY --chown=0:0 --from=build-env-rust /root/namada/target/release/namadan /usr/bin/namadan
COPY --chown=0:0 --from=build-env-rust /root/namada/target/release/namadaw /usr/bin/namadaw

COPY --chown=0:0 --from=build-env-go /root/tendermint/build/tendermint /usr/bin/tendermint-$TENDERMINT_TAG
RUN ln /usr/bin/tendermint-$TENDERMINT_TAG /usr/bin/tendermint
USER namada:namada

VOLUME ["/home/namada/.namada"]

ENTRYPOINT ["namada"]

