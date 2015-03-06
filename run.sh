#!/bin/sh

cd "$( dirname "$0" )"
java -Xms256m -Xmx1g -cp "Trees/build-tmp:Trees/code/*" RunHeadless "${PWD}/Trees"
