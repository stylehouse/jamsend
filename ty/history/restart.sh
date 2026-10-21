#!/bin/bash
set -e
sudo systemctl stop jamsend-watchdog jamsend-launcher jamsend-x11vnc jamsend-wm jamsend-xvfb
sudo systemctl start jamsend-xvfb jamsend-wm jamsend-x11vnc jamsend-launcher jamsend-watchdog