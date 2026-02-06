#!/bin/sh
user=$(id -u)
group=$(id -g)
sudo mkdir -p /mnt/music-jamsend/-\ Steve
sudo chown $user:$group /mnt/music-jamsend
echo "/mnt/music /mnt/music-jamsend/-\ Steve none bind,ro 0 0" | sudo tee -a /etc/fstab

sudo mount /mnt/music-jamsend/-\ Steve

