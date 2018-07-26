#!/bin/sh
# Builds the love2d package with loverocks
loverocks deps
zip -r golflike.love *
loverocks purge
