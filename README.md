# jamsend

Hifi streaming with radio-tuner UI

## setup

First time,

```bash
# get such a container
docker compose build
# populate your ./node_modules, mounted in the container under /app
docker run --rm -v .:/app jamsend-app:latest npm install"
```

Thence,

```bash
docker compose up
```

If your docker0 interface isnt 172.17.0.1 (so _leproxy_ can reverse to it), edit *docker-compose.yml* and related things until it works.

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




