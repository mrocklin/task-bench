#!/bin/bash

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $1 = crop ]]; then
    function crop {
        pdfcrop "$1" >/dev/null && mv "$(basename "$1" .pdf)"-crop.pdf "$1"
    }
else
    function crop { true; }
fi

if [[ $(basename $PWD) = compute ]]; then
    "$root_dir"/metg.py -m cori -g 1 -d stencil_1d --csv excel > metg_stencil.csv
    for pattern in nearest spread fft; do
        "$root_dir"/metg.py -m cori -g 1 -d $pattern --csv excel > metg_${pattern}.csv
    done
    "$root_dir"/metg.py -m cori -g 4 -d nearest --csv excel > metg_ngraphs_4_nearest.csv

    "$root_dir"/efficiency.py -m cori -g 1 -d stencil_1d -n 1 --csv excel > efficiency_stencil.csv
    "$root_dir"/efficiency.py -m cori -g 1 -d stencil_1d -n 1 -s 'mpi nonblock' --csv excel > efficiency_stencil_mpi.csv

    "$root_dir"/flops.py -m cori -g 1 -d stencil_1d -n 1 --csv excel > flops_stencil.csv
    "$root_dir"/flops.py -m cori -g 1 -d stencil_1d -n 1 -s 'mpi nonblock' --csv excel > flops_stencil_mpi.csv

    "$root_dir"/weak.py -m cori -g 1 -d stencil_1d -s 'mpi nonblock' --csv excel > weak_mpi.csv
    "$root_dir"/strong.py -m cori -g 1 -d stencil_1d -s 'mpi nonblock' --csv excel > strong_mpi.csv

    "$root_dir"/render_metg.py metg_stencil.csv # --title "METG vs Nodes (Cori, Compute, Stencil)"
    for pattern in nearest spread fft; do
        "$root_dir"/render_metg.py metg_${pattern}.csv # --title "METG vs Nodes (Cori, Compute, ${pattern})"
    done
    "$root_dir"/render_metg.py metg_ngraphs_4_nearest.csv # --title 'METG vs Nodes (Cori, Compute, 4x Nearest)'

    "$root_dir"/render_metg.py efficiency_stencil.csv \
               --xlabel 'Task Granularity (ms)' \
               --xdata 'time_per_task' \
               --x-invert \
               --xbase 10 \
               --no-xticks \
               --ylabel 'Efficiency' \
               --ylim '(-0.05,1.05)' \
               --no-ylog \
               --y-percent \
               --highlight-column 'metg' # \
               # --title 'Efficiency vs Task Granularity (Cori, Compute, Stencil)'

    "$root_dir"/render_metg.py efficiency_stencil_mpi.csv \
               --legend '' \
               --height 4 \
               --xlabel 'Task Granularity (ms)' \
               --xdata 'time_per_task' \
               --x-invert \
               --xbase 10 \
               --no-xticks \
               --ylabel 'Efficiency' \
               --ylim '(-0.05,1.05)' \
               --no-ylog \
               --y-percent \
               --highlight-column 'metg' # \
               # --title 'MPI Efficiency vs Task Granularity (Cori, Compute, Stencil)'

    "$root_dir"/render_metg.py flops_stencil.csv \
               --xlabel 'Problem Size' \
               --xdata 'iterations' \
               --x-invert \
               --no-xticks \
               --ylabel 'TFLOPS' \
               --yscale 1e-12 \
               --no-ylog \
               --highlight-column 'metg' # \
               # --title 'FLOPS vs Problem Size (Cori, Compute, Stencil)'

    "$root_dir"/render_metg.py flops_stencil_mpi.csv \
               --legend '' \
               --height 4 \
               --xlabel 'Problem Size' \
               --xdata 'iterations' \
               --x-invert \
               --no-xticks \
               --ylabel 'TFLOPS' \
               --yscale 1e-12 \
               --no-ylog \
               --highlight-column 'metg' # \
               # --title 'MPI FLOPS vs Problem Size (Cori, Compute, Stencil)'

    "$root_dir"/render_metg.py weak_mpi.csv \
               --legend '' \
               --xlabel 'Nodes' \
               --xdata 'nodes' \
               --ylabel 'Wall Time (s)' \
               --highlight-column 'metg' # \
               # --title 'Weak Scaling by Problem Size (Cori, Compute, Stencil)'

    "$root_dir"/render_metg.py strong_mpi.csv \
               --legend '' \
               --xlabel 'Nodes' \
               --xdata 'nodes' \
               --ylabel 'Wall Time (s)' \
               --highlight-column 'metg' # \
               # --title 'Strong Scaling by Problem Size (Cori, Compute, Stencil)'

    crop metg_stencil.pdf
    for pattern in nearest spread fft; do
        crop metg_${pattern}.pdf
    done
    crop metg_ngraphs_4_nearest.pdf
    crop efficiency_stencil.pdf
    crop efficiency_stencil_mpi.pdf
    crop flops_stencil.pdf
    crop flops_stencil_mpi.pdf
    crop weak_mpi.pdf
    crop strong_mpi.pdf

elif [[ $(basename $PWD) = memory ]]; then

    "$root_dir"/flops.py -m cori -r bytes -g 1 -d stencil_1d -n 1 --csv excel > bytes_stencil.csv

    "$root_dir"/efficiency.py -m cori -r bytes -g 1 -d stencil_1d -n 1 --csv excel > efficiency_stencil.csv

    "$root_dir"/render_metg.py bytes_stencil.csv \
               --xlabel 'Problem Size' \
               --xdata 'iterations' \
               --x-invert \
               --no-xticks \
               --ylabel 'GB/s' \
               --yscale 1e-9 \
               --no-ylog \
               --highlight-column 'metg' # \
               # --title 'B/s vs Problem Size (Cori, Memory, Stencil)'

    "$root_dir"/render_metg.py efficiency_stencil.csv \
               --xlabel 'Task Granularity (ms)' \
               --xdata 'time_per_task' \
               --x-invert \
               --xbase 10 \
               --no-xticks \
               --ylabel 'Efficiency' \
               --ylim '(-0.05,1.05)' \
               --no-ylog \
               --y-percent \
               --highlight-column 'metg' # \
               # --title 'Efficiency vs Task Granularity (Cori, Memory, Stencil)'

    crop bytes_stencil.pdf
    crop efficiency_stencil.pdf

elif [[ $(basename $PWD) = radix ]]; then

    "$root_dir"/radix.py -m cori -g 1 -d nearest -n 1 --csv excel > metg_nearest.csv

    "$root_dir"/render_metg.py metg_nearest.csv \
               --xlabel 'Dependencies per Task' \
               --xdata 'radix' \
               --no-xlog # \
               # --title 'METG vs Dependencies per Task (Cori, Compute, Nearest)'

    crop metg_nearest.pdf

elif [[ $(basename $PWD) = communication ]]; then
    "$root_dir"/comm.py -m cori -g 4 -d spread -n 16 --csv excel > metg_nodes_16.csv
    "$root_dir"/comm.py -m cori -g 4 -d spread -n 64 --csv excel > metg_nodes_64.csv
    "$root_dir"/comm.py -m cori -g 4 -d spread -n 256 --csv excel > metg_nodes_256.csv

    for comm in 16 256 4096 65536; do
        "$root_dir"/efficiency.py -m cori -g 4 -d spread -n 16 -c ${comm} --hide-metg --csv excel > efficiency_nodes_16_comm_${comm}.csv
        "$root_dir"/efficiency.py -m cori -g 4 -d spread -n 64 -c ${comm} --hide-metg --csv excel > efficiency_nodes_64_comm_${comm}.csv
    done

    for comm in 256 4096 65536 1048576; do
        "$root_dir"/efficiency.py -m cori -g 4 -d spread -n 256 -c ${comm} --hide-metg --csv excel > efficiency_nodes_256_comm_${comm}.csv
    done

    "$root_dir"/render_metg.py metg_nodes_16.csv \
               --xlabel 'Message Size (B)' \
               --xdata 'comm' # \
               # --title 'METG vs Communication (Cori, Compute, 4x Spread)'

    "$root_dir"/render_metg.py metg_nodes_64.csv \
               --xlabel 'Message Size (B)' \
               --xdata 'comm' # \
               # --title 'METG vs Communication (Cori, Compute, 4x Spread)'

    "$root_dir"/render_metg.py metg_nodes_256.csv \
               --xlabel 'Message Size (B)' \
               --xdata 'comm' # \
               # --title 'METG vs Communication (Cori, Compute, 4x Spread)'

    for comm in 16 256 4096 65536; do
        "$root_dir"/render_metg.py efficiency_nodes_16_comm_${comm}.csv \
                   --xlabel 'Task Granularity (ms)' \
                   --xdata 'time_per_task' \
                   --x-invert \
                   --xbase 10 \
                   --no-xticks \
                   --ylabel 'Efficiency' \
                   --ylim '(-0.05,1.05)' \
                   --no-ylog \
                   --y-percent \
                   --highlight-column 'metg' # \
                   # --title "Efficiency vs Task Granularity (Cori, Compute, Stencil, Comm ${comm})"

        "$root_dir"/render_metg.py efficiency_nodes_64_comm_${comm}.csv \
                   --xlabel 'Task Granularity (ms)' \
                   --xdata 'time_per_task' \
                   --x-invert \
                   --xbase 10 \
                   --no-xticks \
                   --ylabel 'Efficiency' \
                   --ylim '(-0.05,1.05)' \
                   --no-ylog \
                   --y-percent \
                   --highlight-column 'metg' # \
                   # --title "Efficiency vs Task Granularity (Cori, Compute, Stencil, Comm ${comm})"
    done

    for comm in 256 4096 65536 1048576; do
        "$root_dir"/render_metg.py efficiency_nodes_256_comm_${comm}.csv \
                   --xlabel 'Task Granularity (ms)' \
                   --xdata 'time_per_task' \
                   --x-invert \
                   --xbase 10 \
                   --no-xticks \
                   --ylabel 'Efficiency' \
                   --ylim '(-0.05,1.05)' \
                   --no-ylog \
                   --y-percent \
                   --highlight-column 'metg' # \
                   # --title "Efficiency vs Task Granularity (Cori, Compute, Stencil, Comm ${comm})"
    done

    crop metg_nodes_16.pdf
    crop metg_nodes_64.pdf
    crop metg_nodes_256.pdf
    for comm in 16 256 4096 65536; do
        crop efficiency_nodes_16_comm_${comm}.pdf
        crop efficiency_nodes_64_comm_${comm}.pdf
    done
    for comm in 256 4096 65536 1048576; do
        crop efficiency_nodes_256_comm_${comm}.pdf
    done

elif [[ $(basename $PWD) = imbalance ]]; then
    "$root_dir"/imbalance.py -m cori -g 4 -d nearest -n 1 --csv excel > metg_ngraphs_4_nearest.csv

    for imbalance in 0.0 0.5 1.0 1.5 2.0; do
        "$root_dir"/efficiency.py -m cori -g 4 -d nearest -n 1 -i ${imbalance} --hide-metg --csv excel > efficiency_imbalance_${imbalance}.csv
    done

    "$root_dir"/render_metg.py metg_ngraphs_4_nearest.csv \
               --xlabel 'Imbalance' \
               --xdata 'imbalance' \
               --no-xlog # \
               # --title 'METG vs Imbalance (Cori, Compute, 4x Nearest)'

    for imbalance in 0.0 0.5 1.0 1.5 2.0; do
        "$root_dir"/render_metg.py efficiency_imbalance_${imbalance}.csv \
                   --xlabel 'Task Granularity (ms)' \
                   --xdata 'time_per_task' \
                   --x-invert \
                   --xbase 10 \
                   --no-xticks \
                   --ylabel 'Efficiency' \
                   --ylim '(-0.05,1.05)' \
                   --no-ylog \
                   --y-percent \
                   --highlight-column 'metg' # \
                   # --title "Efficiency vs Task Granularity (Cori, Compute, Stencil, Imbalance ${imbalance})"
    done

    crop metg_ngraphs_4_nearest.pdf
    for imbalance in 0.0 0.5 1.0 1.5 2.0; do
        crop efficiency_imbalance_${imbalance}.pdf
    done
else
    echo "Not in a data directory, change to 'compute' or 'imbalance' and then rerun."
fi
