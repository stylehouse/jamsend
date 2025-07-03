# jamsend

Hifi streaming with radio-tuner UI

# features

## radio-tuner

you turn the knob to jump into the middle of a new track.

# goals

- p2p
- peer as a source of music, shared directories
- climbing directories, randomly selecting, transcoding in ffmpeg-wasm
- collectivise music collection connections
- build a trust network
- cytoscape ui, presence|rate|pitch-bendable aud
- culture (ethnology, typology, ?) graph
- auto-heal

# setup

```bash
# get such a container
docker compose build
# populate your ./node_modules, mounted in the container under /app
docker run --rm -v .:/app jamsend-app:latest npm install
# thence
docker compose up
```

If your docker0 interface isnt 172.17.0.1 (so eg _leproxy_ can reverse to it), edit *docker-compose.yml* and related things until it works.
