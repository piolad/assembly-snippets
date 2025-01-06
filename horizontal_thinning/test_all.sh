#!/bin/bash

# Directory containing test files
TEST_DIR="./tests"
RESULT_DIR="./tests/results"
EXPECTED_DIR="./tests/expected"

# Create results directory if it doesn't exist
mkdir -p "$RESULT_DIR"

for TEST_FILE in "$TEST_DIR"/*; do
    if [[ -f $TEST_FILE ]]; then
        BMP_INPUT="$TEST_FILE"
        BMP_OUTPUT="$RESULT_DIR/$(basename "$TEST_FILE" .bmp)_res.bmp"

        # Run the program
        OUTPUT=$(./hth "$BMP_INPUT" "$BMP_OUTPUT" 2>&1)
        EXIT_CODE=$?

        # Check if the program crashed
        if [[ $EXIT_CODE -ne 0 ]]; then
            echo "[ERR!] $TEST_FILE caused a crash"
        else
            # Compare the output file with the expected file
            EXPECTED_FILE="$EXPECTED_DIR/$(basename "$TEST_FILE" .bmp)_res.bmp"

            if [[ -f $EXPECTED_FILE ]]; then
                if ! diff -q <(xxd "$BMP_OUTPUT") <(xxd "$EXPECTED_FILE") > /dev/null; then
                    echo "[ERR!] $TEST_FILE produced incorrect output"
                else
                    echo "[ok] $TEST_FILE"
                fi
            else
                echo "[no exp file] : $TEST_FILE  ($EXPECTED_FILE)"
            fi
        fi
    fi

done
