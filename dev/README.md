# `dev/` Script Map

`dev/` is not part of the canonical runtime. It contains support material for
verification, benchmarking, provenance, and historical exploration.

Use this directory in three modes.

## 1. Release Verification

The canonical release acceptance script is:

- [run_release_verification.sh](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/run_release_verification.sh)

This checks only the supported massless release matrix. It is the only
supported release gate; `run_release_verification.wl` is a retired explanatory
stub, kept solely to stop old commands from producing a misleading smoke-pass.

It starts one fresh Wolfram kernel per case, writes one JSON evidence report per
case. It distinguishes `Validated`, `Unvalidated`, `Failed`, and
`InconclusiveTimeout`: a completed calculation or an empty diagnostics
association is not a validation pass. The driver exits nonzero if any case is
unvalidated, failed, or times out. The default timeout is two hours; override
it with `ANTCALC_RELEASE_TIMEOUT`. For a final defence evidence bundle, retain
the reports with:

```sh
ANTCALC_RELEASE_KEEP_OUTPUT=1 \
ANTCALC_RELEASE_OUTPUT_DIR=/path/to/release-evidence \
./dev/run_release_verification.sh
```

The route-level worker is
[release_acceptance_worker.wl](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/release_acceptance_worker.wl).
For a short selected rerun, set `ANTCALC_RELEASE_CASES`, for example
`ANTCALC_RELEASE_CASES=A20,A21,A30 ./dev/run_release_verification.sh`.

Each JSON report records the validation tier, scope, declared required checks,
and observed evidence. `ExternalLiterature` is eligible for `Validated` when
all declared checks pass. `InternalConsistency` is deliberately reported as
`Unvalidated` even when its residual checks pass; it is useful evidence but not
a substitute for an independent target. At present this applies to A31 and
A22; R-ratio LO/NLO are likewise unvalidated until explicit lower-order targets
are added.

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
