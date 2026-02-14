#!/bin/bash
# my ~/.ssh/config makes ds hostname=d user=s
#  and over there s is in the group docker, is uid=1000
# over there has also got to be:
# ./music and ./chrome-profile
#  and I had to chmod o+w them
scp ty/bot.js docker-compose.droid.yml ds:
ssh -L 7900:localhost:7900 ds docker compose up
