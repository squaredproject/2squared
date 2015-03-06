#!/bin/sh

cd "$( dirname "$0" )"
javac -cp "Trees/code/*" -d Trees/build-tmp Trees/*.java
