#!/bin/bash

for testcase in 1 2 3 4; do
    testcase_dir="Testcase${testcase}"
    out_dir="Testcase${testcase}Diff"

    rm -rf "$out_dir"

    for f1 in "$testcase_dir"/*.1.txt; do
        [ -e "$f1" ] || continue
        base=$(basename "$f1" .1.txt)
        
        f2="${testcase_dir}/${base}.2.txt"
        outfile="${out_dir}/${base}Diff.txt"

        diff_out=$(diff -u "$f1" "$f2")
        diff_rc=$?

        if [ "$diff_rc" -ne 0 ]; then
            mkdir -p "$out_dir"
            echo "$diff_out" > "$outfile"
            has_diff=1
        fi
    done

    if [ "$has_diff" -eq 0 ]; then
        rm -rf "$out_dir"
    fi
done
