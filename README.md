# jamsend

Hifi streaming with radio-tuner UI

## setup

First time,

```bash
docker pull oven/bun
docker run -v .:/home/bun/app oven/bun bun install
```

Thence,

```bash
docker compose up
```

# spec (all TODO)

## p2p

- one of them hosts the stream
- others help distribute it

## radio list

climbing directories, randomly selecting, transcoding

## radio-tuner

you turn the knob to jump into the middle of a new track.

## opus conversion

in ffmpeg-wasm


