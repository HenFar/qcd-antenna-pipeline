# Runtime masters and literature provenance

[Developer index](README.md) · [Research status](research-status.md) · [Documentation home](../README.md)

The runtime loads checked-in A31/A22 master substitutions from:

```text
masterIntegrals/master_values_runtime.wl
```

This avoids rebuilding the derivation layer at package startup. It does not
make the artifact a cache of final antenna answers: it is a required runtime
input with its own provenance and validation workflow.

## Refresh and validate runtime values

After changing derivation-side files, refresh the runtime artifact:

```sh
cd /path/to/antenna_pipeline
bash masterIntegrals/run_kernel.sh -run 'Get["masterIntegrals/export_runtime_master_values.wl"]; Exit[]'
```

Validate it against the live derivation layer:

```sh
cd /path/to/antenna_pipeline
bash masterIntegrals/run_kernel.sh -run 'Get["dev/validate_runtime_master_values.wl"]; Exit[]'
```

## Source map

| Source | Role in the runtime/provenance layer |
|---|---|
| `hep-ph/0403057` | R-ratio and T-object construction; A31/A22 master provenance |
| `hep-ph/0311276` | A40/B40/C40 master-integral provenance |
| `hep-ph/0505111` | remaining main antenna targets and comparison objects |

The runtime distinguishes package-owned routing, normalisation, diagnostics,
and integration plumbing from imported targets and master values. Literature
expressions are comparison/provenance data unless the route has a documented
derivation to the corresponding runtime basis.

## Massive A30

The massive route has a real runtime `MX30` reduction and a legitimate
unintegrated antenna. Its first runtime master has a natural bridged paper
identification. Its second runtime master is dotted while the paper basis uses
a numerator master. The latter relation remains provisional until a direct
reduction derives it. Do not solve that relation backwards from agreement with
a closed paper expression.

## Repository roles

| Directory | Role |
|---|---|
| `src/` | runtime source tree |
| `dev/` | release checks, benchmarks, and research/provenance scripts |
| `masterIntegrals/` | derivation-owned master-integral provenance |
| `bases/`, `generated_bases/` | integration backend assets |
| `stored_results/` | optional public-route replay cache, not source of truth |
