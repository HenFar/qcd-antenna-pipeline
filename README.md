# Antenna Pipeline

`antenna_pipeline` is a Wolfram Language package for building and integrating
QCD antenna functions through a small public API. The release target of this
repo is now explicit:

```text
Load one package, call a small set of public functions, and reproduce the
massless A-type antenna story needed for the NNLO SMQCD R-ratio workflow.
```

This repo is no longer presented as an open-ended “finish every branch”
research notebook. It is a package with a completed massless target and two
callable experimental branches that are intentionally outside the release
guarantee.

## Release Promise

The release-complete package surface is:

- massless tree-level `A20`, `A30`, `A40`, `tildeA40`, `B40`, and `C40`
- integrated `A21`
- integrated `A30`
- integrated `A31`, `tildeA31`, and `hatA31`
- integrated `A22`, `tildeA22`, `hatA22`, and `breveA22`
- the massless `SMQCD` high-level driver
  `BuildRRatio[SMQCD, quarkMass -> 0]`
- the massless SMQCD bulk convenience routes
  `BuildAllAntennae[SMQCD, maxOrder -> LO|NLO|NNLO]`
  and `BuildAndIntegrateAllAntennae[SMQCD, ...]`
- the record/inspection layer built around `ReturnRecord` and
  `IntermediateSteps`

These are the routes the package claims as supported for external use.

## Experimental Branches

Two branches remain public-callable, but they are not part of the release
guarantee:

- massive `A30`
- `D30`

They remain in the runtime because they are useful research tracks, but they
must be understood as experimental:

- they expose diagnostics and records honestly;
- they may return unfinished results or `$Failed`;
- they are documented separately from the supported massless package promise;
- they are not the package acceptance target.

### Massive A30

The current massive `A30` status is:

- `BuildAntenna[A, 3, 0, quarkMass -> mQ]` is legitimate and package-derived
- `BuildAntennaObject[A, 3, 0, quarkMass -> mQ]` is available as the
  integration-ready public wrapper for that massive build result
- the bibliography-facing integrated result is encoded and checked as
  provenance
- the package can reduce the massive integrand to the `MX30` master
  combination
- the fully internal closed master-substitution derivation is still not
  complete

So the honest endpoint today is:

- correct unintegrated massive antenna
- explicit literature/provenance bridge for the integrated result
- package-owned reduction to masters
- no release-guaranteed closed integrated runtime result

### D30

The current `D30` status is:

- the effective source-model infrastructure exists under `src/`
- source amplitudes and source interferences are built by the runtime
- the public `BuildAntenna[D, 3, 0, ...]` route exposes that started work
  through diagnostics and run records
- the final symbolic extraction into a validated public `D30` antenna is still
  unfinished
- there is no public integration route

So `D30` is a runtime research branch, not a finished package feature.

## Supported Release Matrix

```text
Family / object                  build   integrate   release status
-------------------------------------------------------------------
A20                             yes     n/a         supported
A30                             yes     yes         supported
A40                             yes     yes         supported
tildeA40                        yes     yes         supported
B40                             yes     yes         supported
C40                             yes     yes         supported
A21                             yes     yes         supported
A31                             yes     yes         supported
tildeA31                        yes     yes         supported
hatA31                          yes     yes         supported
A22                             yes     yes         supported
tildeA22                        yes     yes         supported
hatA22                          yes     yes         supported
breveA22                        yes     yes         supported
BuildRRatio[SMQCD, m=0]         n/a     n/a         supported
BuildAllAntennae[SMQCD, ...]    yes     n/a         supported convenience
BuildAndIntegrateAllAntennae    yes     yes         supported convenience
massive A30                     yes     partial     experimental
D30                             partial no          experimental
```

## Loading

From a Wolfram notebook or kernel:

```wl
repoRoot = "/path/to/antenna_pipeline";
Get[FileNameJoin[{repoRoot, "AntennaPipeline.wl"}]]
```

From the terminal:

```sh
cd /path/to/antenna_pipeline
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -noprompt -run 'Get["AntennaPipeline.wl"]; Exit[]'
```

`AntennaPipeline.wl` is the only canonical loader.

## Public API

The main public entry points are:

```wl
BuildAntenna[type, numFinalParticles, loopOrder, ...]
BuildAntennaObject[type, numFinalParticles, loopOrder, ...]
IntegrateAntenna[antennaObject, ...]
BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder, ...]
BuildRRatio[model, ...]
BuildAllAntennae[model, ...]
BuildAndIntegrateAllAntennae[model, ...]
```

The usual user-facing story is:

1. build an unintegrated antenna with `BuildAntenna[...]`
2. optionally build an integration-ready object with `BuildAntennaObject[...]`
3. integrate with `IntegrateAntenna[...]`
4. or use `BuildAndIntegrateAntenna[...]` for the one-shot route

## Happy Path

The canonical onboarding workflow is:

1. Load the package.
2. Run one build example.
3. Run one integrated example.
4. Run the release verification script.
5. Optionally inspect records and intermediate stages.

Representative examples:

```wl
BuildAntenna[A, 2, 0]
BuildAndIntegrateAntenna[A, 3, 0]
BuildAndIntegrateAntenna[A, 3, 0, ReturnRecord -> True]
BuildRRatio[SMQCD, quarkMass -> 0]
BuildRRatio[SMQCD, quarkMass -> 0, ResultForm -> "RawDimRegSeries"]
BuildAllAntennae[SMQCD, maxOrder -> NNLO]
BuildAndIntegrateAllAntennae[SMQCD, maxOrder -> NNLO, ExpansionOrder -> 0]
```

## Bulk Workflows

For the fully implemented massless SMQCD release target, the package also
ships two convenience drivers that walk the supported antenna list up to a
chosen perturbative order:

- `BuildAllAntennae[SMQCD, maxOrder -> LO|NLO|NNLO]`
- `BuildAndIntegrateAllAntennae[SMQCD, maxOrder -> LO|NLO|NNLO,
  ExpansionOrder -> 0]`

Their current scope is intentionally narrow:

- they are implemented for `SMQCD`
- they use uppercase order tags `LO`, `NLO`, and `NNLO`
- their massless target is the same supported `A`, `B`, and `C` release set
- they are convenience wrappers over `BuildAntenna[...]` and
  `BuildAndIntegrateAntenna[...]`, not independent physics routes

The current SMQCD lists are:

- `LO`: `A20`
- `NLO`: `A20`, `A30`, `A21`
- `NNLO`: `A20`, `A30`, `A21`, `A40`, `B40`, `C40`, `A31`, `A22`

They are not yet the right entry point for experimental massive work:

- nonzero `quarkMass` currently aborts in these bulk helpers
- `SUSY` and `HiggsEFT` bulk enumeration are scaffolded but not implemented

If you want inspectable state rather than only the final result:

```wl
rec = BuildAndIntegrateAntenna[A, 3, 0, ReturnRecord -> True];
rec["Result"]
rec["IntermediateSteps"]
rec["Diagnostics"]
rec["MasterCombination"]
```

The default behavior is unchanged: without `ReturnRecord -> True`, the public
functions still return the same plain result shapes as before.

## Release Verification

The canonical package acceptance script is:

```sh
cd /path/to/antenna_pipeline
bash dev/run_release_verification.sh
```

That script checks only the supported release matrix. It is the intended
“does this package installation work?” command for external users.

A lighter smoke test is:

```sh
cd /path/to/antenna_pipeline
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -noprompt -run 'Get["AntennaPipeline.wl"]; Print[BuildAntenna[A,2,0]]; Print[BuildAndIntegrateAntenna[A,3,0]]; Exit[]'
```

The benchmark harness remains available, but it is not the acceptance test:

```sh
cd /path/to/antenna_pipeline
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -noprompt -script dev/run_public_route_benchmarks.wl
```

## Experimental Inspection

The experimental branches remain callable, but should be used with that status
in mind.

Massive `A30` build-side route:

```wl
BuildAntenna[A, 3, 0, quarkMass -> mQ, ReturnRecord -> True]
BuildAntennaObject[A, 3, 0, quarkMass -> mQ]
```

Massive `A30` integrated-route diagnostics:

```wl
BuildAndIntegrateAntenna[A, 3, 0, quarkMass -> mQ, ReturnDiagnostics -> True]
```

`D30` source-route diagnostics:

```wl
BuildAntenna[D, 3, 0, ReturnDiagnostics -> True]
BuildAntenna[D, 3, 0, ReturnRecord -> True]
```

Research and provenance material for those branches lives under:

- [dev/massiveA30](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/massiveA30)
- [dev/massiveA30_sources](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/massiveA30_sources)
- [dev/d30](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/d30)

## Runtime Master Values

The runtime `A31` and `A22` master substitutions are intentionally loaded from
a checked-in artifact rather than recomputed on package load:

- artifact:
  [masterIntegrals/master_values_runtime.wl](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/masterIntegrals/master_values_runtime.wl)
- provenance layer:
  [masterIntegrals/](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/masterIntegrals)

Refresh the artifact after changing the derivation-side files:

```sh
cd /path/to/antenna_pipeline
bash masterIntegrals/run_kernel.sh -run 'Get["masterIntegrals/export_runtime_master_values.wl"]; Exit[]'
```

Validate it against the live derivation layer:

```sh
cd /path/to/antenna_pipeline
bash masterIntegrals/run_kernel.sh -run 'Get["dev/validate_runtime_master_values.wl"]; Exit[]'
```

## Repository Layout

The release-facing surface is intentionally small:

- [AntennaPipeline.wl](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/AntennaPipeline.wl)
  is the canonical loader
- [src/](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/src)
  is the canonical runtime source tree
- [dev/](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev)
  contains release verification, benchmarks, and research/provenance scripts
- [masterIntegrals/](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/masterIntegrals)
  contains derivation-owned master-integral provenance for runtime values

See
[src/README.md](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/src/README.md)
for the runtime architecture walkthrough and
[dev/README.md](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/dev/README.md)
for the development-script map.

## Known Non-Goals

This release does not claim:

- a fully internal closed massive `A30` master-substitution derivation
- a finished public `D30` antenna extraction
- a finished `SUSY` or `HiggsEFT` `R`-ratio route
- that every research/provenance script under `dev/` is part of the supported
  user workflow

The project is considered complete around the massless package goal, not
around finishing every exploratory physics branch.
