#!/bin/sh
VER=2.5.4
curl -k -o trs80gp-$VER.zip http://48k.ca/trs80gp-$VER.zip
unzip -j -o trs80gp-$VER.zip windows/* -d trs80gp
