#!/bin/sh

ls -lah /custom-config/
ls -lah /app/

cp -f /custom-config/config.json /app/config.json || exit 0
