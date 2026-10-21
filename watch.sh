#!/bin/zsh

find ./trees -name '*.tree' | entr forester build
