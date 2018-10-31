#!/usr/bin/env bash

set -e

segment_duration=1
playlist_type=live
segments=2

function start_segmenter() {
    cd /opt/segmenter
    echo "starting segmenter..."
    ./transport-stream-segmenter-tcp.js 1234 /media s_ stream.m3u8 $segment_duration 0.0.0.0 $playlist_type $segments
}

function start_chunk_web_server() {
    cd /opt/webserver
    echo "starting chunk web server..."
    ./index.js -p 5000 -d /media -a 127.0.0.1 >/dev/null 2>&1 &
}

function start_varnish() {
    echo "Starting varnish..."
    service varnish start >/dev/null 2>&1
}

function start_cron() {
    echo "Starting cron..."
    service cron start >/dev/null 2>&1
}

function usage() {
    echo "Usage: docker run <docker args> lhls-segmenter [-d DURATION] [-t PLAYLIST_TYPE] [-s LHLS_SEGMENTS]"
    echo ""
    echo "Options:"
    echo "    -d  segment duration in seconds (default: 4)"
    echo "    -t  playlist type, either live or event (default: live)"
    echo "    -s  lhls segments to pre-announce in playlist (default: 3)"
    echo ""
}

while getopts ":d:t:s:h" opt; do
    case $opt in
        d)
            segment_duration=$OPTARG
            ;;
        t)
            playlist_type=$OPTARG
            ;;
        s)
            segments=$OPTARG
            ;;
        h)
            usage >&2
            exit 0
            ;;
        \?)
            usage >&2
            echo "Error: invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            usage >&2
            echo "Error: option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done


function start() {
    echo "Configuration: segments $segments, segment duration $segment_duration, playlist type $playlist_type"
    start_chunk_web_server
    start_varnish
    start_cron
    start_segmenter
}

start
