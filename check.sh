#!/bin/bash

overall_pass=1

for testcase in 1 2 3 4; do
    tc_dir="Testcase${testcase}"
    out_dir="Testcase${testcase}Diff"
    tc_ok=1

    # Step 1: Find all pairs, separate differing / identical pairs
    declare -a diff_bases=()
    declare -a same_bases=()

    for f1 in "$testcase_dir"/*.1.txt; do
        [ -e "$f1" ] || continue
        base=$(basename "$f1" .1.txt)
        f2="${testcase_dir}/${base}.2.txt"

        # cmp -s: silent compare, 0=same
        cmp -s "$f1" "$f2"
        if [ $? -ne 0 ]; then
            diff_bases+=("$base")
        else
            same_bases+=("$base")
        fi
    done

    has_any_diff=0
    if [ ${#diff_bases[@]} -gt 0 ]; then
        has_any_diff=1
    fi

    # Rule A: If any diff exists, outdir MUST exist; else MUST NOT exist
    if [ "$has_any_diff" -eq 1 ]; then
        if [ ! -d "$out_dir" ]; then
            echo "ERROR: $out_dir should exist but it is missing" >&2
            testcase_ok=0
        fi
    else
        if [ -d "$out_dir" ]; then
            echo "ERROR: $out_dir should NOT exist but it exists" >&2
            tc_ok=0
        fi
    fi

    # Rule B: Every differing base must have Diff.txt, and content matches diff -u
    for base in "${diff_bases[@]}"; do
        expected_file="${out_dir}/${base}Diff.txt"
        if [ ! -f "$expected_file" ]; then
            echo "ERROR: Missing expected file $expected_file" >&2
            testcase_ok=0
        else
            # Generate correct diff -u, skip first two timestamp lines
            correct=$(diff -u "${testcase_dir}/${base}.1.txt" "${testcase_dir}/${base}.2.txt" | tail -n +3)
            stored=$(tail -n +3 "$expected_file")
            if [ "$correct" != "$stored" ]; then
                echo "ERROR: Content mismatch in $expected_file" >&2
                tc_ok=0
            fi
        fi
    done

    # Rule C: Identical pairs MUST NOT have Diff.txt
    for base in "${same_bases[@]}"; do
        forbidden="${out_dir}/${base}Diff.txt"
        if [ -f "$forbidden" ]; then
            echo "ERROR: Forbidden file exists (pair is identical): $forbidden" >&2
            tc_ok=0
        fi
    done

    # Print required line
    if [ "$testcase_ok" -eq 1 ]; then
        echo "Testcase${testcase}: PASS"
    else
        echo "Testcase${testcase}: FAIL"
        overall_pass=0
    fi

    unset diff_bases
    unset same_bases
done

if [ "$overall_pass" -eq 1 ]; then
    exit 0
else
    exit 1
fi
