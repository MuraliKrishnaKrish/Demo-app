#!/bin/sh
grep -q "Version" index.html && echo "PASS: Version tag found" || { echo "FAIL: Missing Version tag"; exit 1; }
