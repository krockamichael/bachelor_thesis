#!/bin/bash

curl -o all_packages.txt http://luarocks.org/manifest

PACKAGES=$(grep -E "^   [[:alnum:]]|^   \\['" all_packages.txt | \
           tr -d '[' | \
           tr -d ']' | \
           tr -d "\'" | \
           cut -d "=" -f1 | \
           tr -d ' ')

for PACKAGE in $PACKAGES ; do
    luarocks install --tree "modules/$PACKAGE" $PACKAGE
    if [ $? -ne 0 ] ; then
        rm -rf "modules/$PACKAGE"
    fi
done
