#!/bin/bash

# Directory containing test files
TEST_DIR="./tests"

for TEST_FILE in "$TEST_DIR"/*; do
    if [[ -f $TEST_FILE ]]; then
        BMP_INPUT="$TEST_FILE"
        # BMP_OUTPUT="./$(basename "$TEST_FILE" .bmp)_res.bmp"
        BMP_OUTPUT="/dev/null"

        OUTPUT=$(./hth "$BMP_INPUT" "$BMP_OUTPUT" 2>&1)
        EXIT_CODE=$?

        # check if the program crashed
        if [[ $EXIT_CODE -ne 0 ]]; then
            echo "$TEST_FILE"
        fi
    fi

done
