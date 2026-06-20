# `dev/` Script Map

`dev/` is not part of the canonical runtime. It contains support material for
verification, benchmarking, provenance, and historical exploration.

Use this directory in three modes.

## 1. Release Verification

The canonical release acceptance script is:

- [run_release_verification.sh](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/run_release_verification.sh)

This checks only the supported massless release matrix.

## 2. Performance / Benchmarks

The main benchmark entrypoint is:

- [run_public_route_benchmarks.wl](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/run_public_route_benchmarks.wl)

Use it when you want timing data, not when you want a release pass/fail check.

## 3. Research / Provenance

The main structured research areas are:

- [massiveA30/](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/massiveA30)
- [massiveA30_sources/](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/massiveA30_sources)
- [d30/](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/d30)
- [src_legacy_flat_2026-06-14/](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/src_legacy_flat_2026-06-14)

The many top-level one-off scripts in `dev/` are historical derivation and
debugging artifacts. They are kept for provenance, but they are not part of
the supported package workflow.

If you are new to the repo, start from:

1. the top-level [README.md](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/README.md)
2. [src/README.md](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/src/README.md)
3. [run_release_verification.sh](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/run_release_verification.sh)
