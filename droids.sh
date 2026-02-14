#!/bin/bash
scp ty/bot.js d:
scp docker-compose.droid.yml d:
ssh -L 7900:localhost:7900 d docker-compose up
