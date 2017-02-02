#!/usr/bin/env bash
ls ../packages | grep -v Makefile | grep -v common | tee lists/solus_sources.txt
