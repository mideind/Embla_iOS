#!/bin/bash

# Print total lines of code in project

cd GreynirApp
echo "LOC Total:"
find . -name \*.\[m\|h\] -exec cat {} \; | wc -l

echo "LOC Total implementation files"
find . -name \*.\[m\] -exec cat {} \; | wc -l

echo "LOC Total header files"
find . -name \*.\[h\] -exec cat {} \; | wc -l
