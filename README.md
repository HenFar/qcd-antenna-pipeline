# AntCalc

AntCalc is a Wolfram Language package for building and integrating QCD antenna
functions. Its public workflow is deliberately small:

```wl
BuildAntenna[...] → IntegrateAntenna[...]
```

`BuildAndIntegrateAntenna[...]` is the corresponding one-shot convenience
wrapper. AntCalc is active thesis research software: its supported massless
routes are usable, while the massive `A30` and `D30` research tracks are
explicitly experimental.

## Status

Current development release: **AntCalc 0.1.0 α 3**.

The current defended target is the massless antenna workflow needed for the
NNLO SMQCD R-ratio. See the [route-status
matrix](docs/manual/route-status.md) before relying on a route in a calculation.

AntCalc is active, unpublished thesis research software. It is shared for
evaluation and academic discussion; reuse, redistribution, and relicensing
require the author's permission.

## Install and load

After cloning the repository, install the paclet once from a Wolfram notebook
or kernel:

```wl
repoRoot = "/path/to/antenna_pipeline";
archive = CreatePacletArchive[repoRoot, $TemporaryDirectory];
PacletInstall[archive];
```

Then restart the kernel and load AntCalc normally:

```wl
<< AntCalc`
```

If the paclet was installed while the notebook kernel was already running,
evaluate `PacletDataRebuild[]`, restart the kernel, and try again.

While actively editing a cloned checkout, load its current source directly
instead of the installed paclet copy:

```wl
repoRoot = "/path/to/antenna_pipeline";
Get[FileNameJoin[{repoRoot, "AntennaPipeline.wl"}]]
```

## Quick start

```wl
<< AntCalc`

(* Unintegrated tree-level NLO antenna. *)
a30 = BuildAntenna[A, 3, 0];

(* One-shot construction and integration. *)
intA30 = BuildAndIntegrateAntenna[A, 3, 0];

(* The explicitly modular equivalent. *)
a30Object = BuildAntenna[A, 3, 0, IntegrableForm -> True];
intA30Direct = IntegrateAntenna[a30Object];
```

## Documentation

The documentation is being migrated to a FeynCalc-like manual structure:

- [Documentation home](docs/README.md)
- [Manual index](docs/manual/index.md)
- [Route status and support contract](docs/manual/route-status.md)
- [Tutorials and runnable examples](docs/tutorials/README.md)
- [Reference guide](docs/reference/README.md)
- [Developer documentation](docs/development/README.md)
- [Citation and provenance](docs/manual/citation-and-provenance.md)
- [Documentation migration ledger](docs/migration-status.md)

The previous comprehensive document is retained during this transition as
[README_old.md](README_old.md). It is archival material, not the preferred
starting point for a new user.

## Dependencies

Supported workflows require a compatible Wolfram Language installation with
FeynCalc and its FeynArts/FeynHelpers environment. IBP-backed integration
routes also require LiteRed2. AntCalc includes repository-owned basis and
runtime-master artifacts required by its supported routes.

The validated alpha-3 toolchain is:

```text
FeynCalc 10.2.1 · FeynArts 3.12 (27 Mar 2025) ·
FeynHelpers 2.0.0 · FeynCalcLegacy 1.0.0
LiteRed2 2.025 β
```

## Scope

AntCalc does not presently claim a fully derived closed massive `A30` master
substitution, a finished public `D30` antenna, or complete `SUSY`/`HiggsEFT`
R-ratio workflows. These limits are described in the [route-status
matrix](docs/manual/route-status.md).
