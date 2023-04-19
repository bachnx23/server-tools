#!/bin/bash
# file: ttfb.sh
# curl command to check the time to first byte
# ** usage **
# 1. ./ttfb.sh "https://google.com"
# 2. seq 10 | xargs -Iz ./ttfb.sh "https://google.com"

curl -o /dev/null \
     -H 'Cache-Control: no-cache' \
     -s \
     -w "{\"connect\": %{time_connect},\"ttfb\": %{time_starttransfer}, \"total\": %{time_total}, \"status_code\": %{http_code}}\n" \
     $1
