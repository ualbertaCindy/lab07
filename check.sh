

all_ok=1

for testcase in 1 2 3 4; do
    tc_dir="Testcase${testcase}"
    out_dir="Testcase${testcase}Diff"
    ok=1

    any_diff=0
    differing_bases=""
    all_bases=""


    for f1 in "$tc_dir"/*.1.txt; do
        [ -e "$f1" ] || continue
        base=$(basename "$f1" .1.txt)
        f2="$tc_dir/${base}.2.txt"
        [ -e "$f2" ] || continue

        all_bases="$all_bases $base"
        if ! cmp -s "$f1" "$f2"; then
            any_diff=1
            differing_bases="$differing_bases $base"
        fi
    done

    if [ "$any_diff" -eq 0 ]; then
        if [ -e "$out_dir" ]; then
            echo "${out_dir} should not exist (no differences in ${tc_dir})" >&2
            ok=0
        fi
    else
        if [ ! -d "$out_dir" ]; then
            echo "missing ${out_dir}/" >&2
            ok=0
        else
            # Every differing pair needs a correct output file
            for base in $differing_bases; do
                outfile="$out_dir/${base}Diff.txt"
                if [ ! -f "$outfile" ]; then
                    echo "missing ${outfile}" >&2
                    ok=0
                    continue
                fi
                # Skip the 2 header lines (paths/timestamps) as per the hint
                expected=$(diff -u "$tc_dir/${base}.1.txt" "$tc_dir/${base}.2.txt" | tail -n +3)
                actual=$(tail -n +3 "$outfile")
                if [ "$expected" != "$actual" ]; then
                    echo "wrong contents in ${outfile}" >&2
                    ok=0
                fi
            done

            # Identical pairs must NOT have an output file
            for base in $all_bases; do
                case " $differing_bases " in
                    *" $base "*) ;;
                    *)
                        if [ -e "$out_dir/${base}Diff.txt" ]; then
                            echo "unexpected ${out_dir}/${base}Diff.txt (pair is identical)" >&2
                            ok=0
                        fi
                        ;;
                esac
            done
        fi
    fi

    if [ "$ok" -eq 1 ]; then
        echo "Testcase${testcase}: PASS"
    else
        echo "Testcase${testcase}: FAIL"
        all_ok=0
    fi
done

if [ "$all_ok" -eq 1 ]; then
    exit 0
else
    exit 1
fi
