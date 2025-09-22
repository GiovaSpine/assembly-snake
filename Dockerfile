FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc-multilib \
        libc6-dev-i386 \
        libncurses5-dev:i386 \
        libncursesw5-dev:i386 \
        nasm \
        build-essential \
        sudo \
        make \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY snake.s time.s utility.s ./

RUN as --32 snake.s -o snake.o && \
    as --32 time.s -o time.o && \
    as --32 utility.s -o utility.o && \
    gcc -m32 snake.o time.o utility.o -o snake -lncurses

CMD ["./snake"]
