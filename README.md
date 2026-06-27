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

## How To Read This README

This README is meant to serve three readers at once:

- package users who want to know what is supported and how to run it
- thesis/supervision readers who need to understand the package contract and
  current status honestly
- contributors who want to inspect or extend the runtime

The guiding rule is:

- supported routes are documented as the intended public package contract
- experimental routes are documented as callable but outside the release
  guarantee
- known contract mismatches are called out explicitly rather than silently
  normalized as if they were correct public behavior

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

## Current Contract Notes

The intended public contract of the package is:

- `BuildAntenna[...]` should expose package-facing antenna objects in the
  package normalization/renormalization convention
- `IntegrateAntenna[...]` and `BuildAndIntegrateAntenna[...]` should consume and
  return objects in that same public convention
- bare or pre-counterterm intermediate expressions are provenance-level objects,
  not the default public endpoint

Not yet implemented or not yet repaired:

- some loop-family behavior, especially around `A31`, still needs cleanup so the
  public build-side result always matches that intended renormalized contract
- the README therefore documents the intended package boundary and flags the
  current mismatch instead of treating the present accidental behavior as the
  desired API
- an explicit public bare-output option is not yet implemented or documented as
  a stable route; it remains a design target rather than a released interface

## Route Status Notes

- supported massless routes are the ones in the release matrix and in
  `dev/run_release_verification.sh`
- massive `A30` is callable and useful, but experimental
- `D30` is callable for diagnostics and source-route inspection, but
  experimental
- loop-route normalization and renormalization notes matter for interpreting the
  public contract, especially for `A21` and `A31`

## Prerequisites

The package is a Wolfram Language runtime that delegates substantial symbolic
work to the standard high-energy-physics toolchain used by the repo.

For the supported massless release workflow, you should assume the following
are available in the Wolfram environment used to load the package:

- Wolfram Kernel / `wolframscript`
- `FeynCalc`
- `FeynArts`
- `FeynHelpers`

The runtime checks the `FeynCalc` version it was validated against and currently
expects `FeynCalc 9.3.1`.

Some supported integration routes also rely on checked-in basis or master-value
artifacts already present in the repository:

- `bases/`
- `generated_bases/`
- `masterIntegrals/master_values_runtime.wl`

Additional integration and development workflows may require the following
tools as well:

- `LiteRed` for IBP basis loading or basis generation
- `Package-X`, used through `FeynCalc`/`FeynHelpers` for `PaVe` evaluation

These extra tools are part of the runtime architecture even when a particular
user session does not touch every backend.

## Environment Assumptions

The repository is designed to be loaded from a checked-out working tree, not as
an installed paclet. The normal expectation is:

- you have the full repository locally
- the bundled `bases/`, `generated_bases/`, and `masterIntegrals/` directories
  are present
- you load [AntennaPipeline.wl](/Users/henriquefarinha/Library/CloudStorage/Dropbox/msc_thesis/thesis_docs/codexAlley/antenna_pipeline/AntennaPipeline.wl)
  from that checkout

The package does not require the full derivation tree to be recomputed on
startup. In particular, the runtime loads the checked-in
`masterIntegrals/master_values_runtime.wl` artifact rather than rebuilding the
master-integral provenance layer on each load.

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

If you want the shortest realistic first-run sequence from the terminal:

```sh
cd /path/to/antenna_pipeline
bash dev/run_release_verification.sh
```

That command is intended to answer the practical question “does this checkout
work as a supported package installation?”

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

### API Reference

`BuildAntenna[type, numFinalParticles, loopOrder, ...]`

- Purpose: build the public unintegrated antenna result for one route key.
- Input shape: an antenna key such as `{A,3,0}` written as
  `BuildAntenna[A, 3, 0, ...]`.
- Normal result shape: a scalar antenna expression, or a list of ordered public
  components when that family has a multi-component public output.
- Inspection variants: may instead return diagnostics, raw build data,
  an `AntennaObject[...]`, or an `AntennaRunRecord[...]` depending on options.
- Scope: this is the main build-side public function for both supported
  massless routes and callable experimental branches.

`BuildAntennaObject[type, numFinalParticles, loopOrder, ...]`

- Purpose: wrap a build result together with the metadata required by
  `IntegrateAntenna[...]`.
- Input shape: same route key as `BuildAntenna[...]`.
- Normal result shape: `AntennaObject[...]`.
- Scope: use this when you want explicit control over build and integration as
  separate stages.

`IntegrateAntenna[antennaObject, ...]`

- Purpose: integrate a built antenna object through the route-selected backend.
- Input shape: an `AntennaObject[...]` produced by `BuildAntennaObject[...]` or
  by `BuildAntenna[..., ReturnAntennaObject -> True]`.
- Normal result shape: an integrated scalar or integrated component list in the
  public package convention.
- Inspection variants: may return diagnostics, T-terms, master combinations,
  intermediate stages, or a full run record.
- Scope: this is the canonical explicit integration entry point.

`BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder, ...]`

- Purpose: run the build and integration pipeline in one public call.
- Input shape: same route key as `BuildAntenna[...]`.
- Normal result shape: the same public integrated result you would obtain by
  composing `BuildAntennaObject[...]` and `IntegrateAntenna[...]`.
- Scope: this is the easiest way to reach the supported integrated endpoints.

`BuildRRatio[model, ...]`

- Purpose: assemble the symbolic NNLO observable-level driver result from the
  supported antenna ingredients.
- Input shape: currently the supported release target is
  `BuildRRatio[SMQCD, quarkMass -> 0, ...]`.
- Normal result shape: by default the finite `MSbar`-convention result, or the
  raw dimensional-regularization series when requested.
- Scope: this is a massless release driver, not an experimental massive route.

`BuildAllAntennae[model, ...]`

- Purpose: bulk-build the supported massless antenna list up to `LO`, `NLO`, or
  `NNLO`.
- Input shape: `BuildAllAntennae[SMQCD, maxOrder -> LO|NLO|NNLO, ...]`.
- Normal result shape: a list of built public antenna results.
- Scope: a convenience wrapper for supported massless `SMQCD` routes only.

`BuildAndIntegrateAllAntennae[model, ...]`

- Purpose: bulk-build and bulk-integrate the supported massless antenna list.
- Input shape: `BuildAndIntegrateAllAntennae[SMQCD, maxOrder -> LO|NLO|NNLO,
  ExpansionOrder -> 0, ...]`.
- Normal result shape: a list of integrated public antenna results.
- Scope: a convenience wrapper over the one-shot route, not an independent
  physics implementation.

### Public Options Reference

The public API uses one shared family of option names. Not every option is
meaningful for every route, so the most useful way to read them is by behavior.

Selection options:

- `Component`
  Select one public component such as `Leading`, `Subleading`, `Nf`, or
  `Breve` when the chosen route has a component split.
- `Contribution`
  Select one internal contribution, such as `TwoLoopTree` or `OneLoopSelf`,
  when the route exposes a contribution-level split.

Inspection and return-shape options:

- `ReturnDiagnostics`
  Return `{result, diagnostics}` rather than only the result.
- `ReturnRecord`
  Return an `AntennaRunRecord[...]` with the result, diagnostics, and stable
  intermediate-stage view.
- `IntermediateSteps`
  Request selected named intermediate stages.
- `PrintIntermediateSteps`
  Print the requested stages to the kernel output.
- `ReturnBuildData`
  Return the internal build-side association used by the route layer.
- `ReturnAntennaObject`
  Return an `AntennaObject[...]` instead of only the plain antenna expression.
- `IntegrableForm`
  Request the build-side expression in the form used by downstream integration
  plumbing.
- `ReturnMasterCombination`
  Return the master-combination view when the chosen integration route has one.
- `ReturnTTerms`
  Return the T-term object from the integration layer when meaningful.

Stored-result options:

- `UseStoredResults`
  Reuse a matching stored public result when available.
- `StoreResults`
  Persist a newly computed public result to the stored-results cache.
- `RefreshStoredResults`
  Force recomputation and refresh the stored cache entry.
- `ResultsCacheRoot`
  Override the default repo-local stored-results directory.

Build and integration routing options:

- `quarkMass`
  Selects the massive branch when supported; the release target is massless
  unless stated otherwise.
- `ReductionBackend`
  Build-side loop reduction selector.
- `PaVeEvaluation`
  Controls whether the `PaVe` route is evaluated through `PaXEvaluate`.
- `ApplyFeynCalcMS`
  Controls whether the `FeynCalc`/`Package-X` normalization bridge is applied on
  the relevant `PaVe` integration routes.
- `ExpansionOrder`
  Sets the target epsilon-series order.
- `KinematicScale`
  Selects the symbolic scale variable used by the integration normalization
  layer.
- `NormalizeKinematicScale`
  Controls whether the selected kinematic scale is normalized to `1` in the
  final result.
- `GenerateMissingBases`
  Allow the IBP backend to generate a missing basis when that route supports it.
- `BasisFamily`, `BasisRoot`
  Low-level integration-backend overrides for IBP-family routing.
- `LoopMomentum`, `LoopMomenta`
  Loop-momentum selectors used by loop routes.
- `ApplyDimReg`
  Apply the package’s dimensional-regularization substitution.
- `ApplyStripCouplings`
  Control build-side coupling stripping.
- `ApplyCasimirSubstitution`
  Control replacement of abstract Casimirs by explicit `SU(N)` expressions.

Workflow and diagnostics options:

- `RunPaperCheck`
  Request paper-target validation when that route has a paper-check layer.
- `AllowPrototypeTargets`
  Permit explicitly prototype or provisional target routes when supported.
- `UseSourceModelRoute`
  Force the source-model route where that experimental branch supports it.
- `DetailedTimingDiagnostics`
  Request extended timing diagnostics from heavy integration routes.
- `printDiagram`, `Verbose`, `prefactor`
  Build-side workflow controls used mainly for route inspection and derivation.

Driver-specific options:

- `ResultForm`
  For `BuildRRatio[...]`, the current public forms are `"FiniteMSBar"` and
  `"RawDimRegSeries"`.
- `maxOrder`
  For bulk helpers, choose `LO`, `NLO`, or `NNLO` using uppercase order tags.

Function-to-option notes:

- `BuildAntenna[...]` has the richest build-side option surface.
- `BuildAntennaObject[...]` uses the `BuildAntenna[...]` option set except for
  `ReturnRecord`.
- `IntegrateAntenna[...]` and `BuildAndIntegrateAntenna[...]` share the same
  integration option surface.
- `BuildRRatio[...]` exposes inspection and stored-result options, but not the
  full low-level integration-routing surface.
- bulk helpers currently expose only `quarkMass`, `maxOrder`, and
  `ExpansionOrder` where relevant; they do not currently expose the full
  stored-result option family directly.

### Components And Contributions

Several public routes return more than one physically meaningful piece. The
README should be read with a distinction between component splits and
contribution splits.

Component split:

- a route returns multiple public package-facing pieces that all belong to the
  same family
- these are selected with `Component -> ...`

Contribution split:

- a route is assembled from multiple build or integration contributions that are
  meaningful to inspect separately
- these are selected with `Contribution -> ...`

The current canonical component orders are:

- `A40`: `{Leading, Subleading}`
- `A31`: `{Leading, Subleading, Nf}`
- `A22`: `{Leading, Subleading, Nf, Breve}`

How to read those names:

- `Leading` and `Subleading` refer to the public color-structure split exposed
  by the package
- `Nf` is the fermion-flavor contribution exposed as its own public component
  on routes such as `A31` and `A22`
- `Breve` is the extra public `A22` component associated with the one-loop/self
  route contribution

The most important route-shape cases are:

- `A40`-family routes return a two-component public structure
- `A31` returns three public integrated components, which feed the
  `BuildRRatio[...]` assembly as `intA31`, `intTildeA31`, and `intHatA31`
- `A22` returns four public integrated components, which feed
  `BuildRRatio[...]` as `intA22`, `intTildeA22`, `intHatA22`, and
  `intBreveA22`
- `A22` also has a contribution split at the route level, most notably
  `TwoLoopTree` and `OneLoopSelf`

Examples:

```wl
BuildAndIntegrateAntenna[A, 4, 0, Component -> Leading]
BuildAndIntegrateAntenna[A, 3, 1, Component -> Nf]
BuildAntenna[A, 2, 2, Contribution -> TwoLoopTree, ReturnDiagnostics -> True]
BuildAndIntegrateAntenna[A, 2, 2, Contribution -> OneLoopSelf, ReturnRecord -> True]
BuildAndIntegrateAntenna[A, 3, 1, ReturnDiagnostics -> True]
```

For `A22`, the build/integration distinction matters more than for the one-loop
routes. `BuildAntenna[A, 2, 2, ...]` returns the unintegrated two-loop object
split into its public components; it does not promise a generic
`PaVe`-reduced form. The reduced `A22` route lives on the integration side,
where the two-loop branch is handled through the package’s dedicated
master-integral machinery rather than through a generic one-loop `PaVe` basis.

### Normalization And Renormalization State

The intended public contract is:

- `BuildAntenna[...]` should expose package-facing results in the package
  normalization and renormalization convention
- `IntegrateAntenna[...]` and `BuildAndIntegrateAntenna[...]` should preserve
  that same public convention
- raw pre-counterterm or bare algebra is an internal/provenance object unless a
  future explicit option exposes it intentionally

The package currently uses `q2` as the canonical kinematic normalization scale
for public integrated routes. The integration layer exposes this explicitly
through:

- `KinematicScale -> q2` by default
- `NormalizeKinematicScale -> True` by default on the integration surface

For loop routes there are two distinct normalization layers to keep separate:

- build-side loop-amplitude normalization inside the package extraction logic
- integration-side convention conversion after `PaVe` or `IBP` reduction

In particular:

- the loop build/extraction layer uses `LoopExpansionNormalization[1] = 8 Pi^2`
  and `LoopExpansionNormalization[2] = (8 Pi^2)^2` when converting loop objects
  into the package expansion convention
- a `PaVe`-reduced loop antenna is therefore not automatically identical to the
  final public integrated result seen by users
- when the package evaluates a `PaVe` object through `PaXEvaluate`, the result
  must still pass through the route-specific normalization/convention bridge
  rather than being interpreted as the final public package value “as is”

On the `PaVe` / `Package-X` side:

- `PaVeEvaluation -> "PaXEvaluate"` is the default public evaluation mode
- `ApplyFeynCalcMS -> True` is the default integration-side setting
- for the massless two-parton `A21` route, the integration backend applies an
  explicit Package-X-to-paper conversion factor rather than treating the raw
  `PaXEvaluate` output as already in the final package convention

Current implementation status:

- the intended contract is that public build results are already in the package
  renormalization state
- some loop-family behavior, especially around `A31`, still needs repair to make
  that build-side contract hold uniformly
- until that repair lands, the README should be read as documenting the intended
  public boundary, with this mismatch recorded openly rather than hidden

Not yet implemented:

- an explicit bare/prototype option to expose pre-counterterm or other internal
  forms for derivation work
- any stable public promise that those internal states are selectable through the
  top-level API

Until those parts are implemented, the README does not treat bare or prototype
states as part of the stable public API.

### Stored Results And Transparent Reuse

The runtime includes a stored-result layer for public-route reuse. The intended
contract is that stored results should be usable transparently across the public
route family rather than as a private notebook trick.

The user-facing controls are:

- `UseStoredResults`
  Attempt to load a matching stored public result instead of recomputing it.
- `StoreResults`
  Save a successful newly computed public result.
- `RefreshStoredResults`
  Recompute the route and overwrite the matching stored entry.
- `ResultsCacheRoot`
  Use a non-default cache root.

Behavioral notes:

- stored results are replays of public-route outputs, not a second derivation
  engine
- when a stored result is used, the route still formats the return into the same
  public shape expected by the caller
- diagnostics are annotated so callers can distinguish cached reuse from a fresh
  run

Current public coverage:

- explicit stored-result options exist on `BuildAntenna[...]`
- explicit stored-result options exist on `BuildAntennaObject[...]`
- explicit stored-result options exist on `IntegrateAntenna[...]`
- explicit stored-result options exist on `BuildAndIntegrateAntenna[...]`
- explicit stored-result options exist on `BuildRRatio[...]`
- explicit stored-result options exist on `TObject[...]`
- bulk helper wrappers do not currently expose the full stored-result option
  family directly

Not yet implemented:

- transparent stored-result controls on the bulk helper wrappers
- a fully uniform user-facing cache story across every top-level public entry
  point

Examples:

```wl
BuildAndIntegrateAntenna[A, 3, 0, UseStoredResults -> True]
BuildAndIntegrateAntenna[A, 3, 0, StoreResults -> True]
BuildRRatio[SMQCD, quarkMass -> 0, UseStoredResults -> True]
BuildAntenna[A, 3, 1, ReturnRecord -> True, StoreResults -> True]
```

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

Operational notes:

- it requires `wolframscript` on `PATH`
- it uses the repo-local `AntennaPipeline.wl` loader for each test case
- it excludes experimental massive `A30` and `D30`
- it is more than a trivial smoke test: it exercises representative supported
  build, integrate, record, and driver routes

The exact runtime depends strongly on the local Wolfram setup and symbolic
backend performance, so the README does not promise a fixed duration. Treat it
as the canonical acceptance run rather than as a near-instant probe.

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

## Stored Results And Runtime Artifacts

The runtime includes a repo-local stored-result cache under `stored_results/`.
This is a usability feature, not a second source of truth: cached results are
replays of public-route outputs, while the route implementations remain the
authoritative computation layer.

Checked-in runtime artifacts matter in two different ways:

- `stored_results/` contains reusable public-route outputs
- `bases/`, `generated_bases/`, and
  `masterIntegrals/master_values_runtime.wl` support integration backends and
  runtime master substitution

Normal users do not need to regenerate these on every run. If you are doing
derivation or backend work, then the relevant `dev/` and `masterIntegrals/`
scripts become part of the workflow.

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

## Troubleshooting

- If `bash dev/run_release_verification.sh` fails immediately with
  `wolframscript was not found on PATH`, make sure the Wolfram command-line
  tools are installed and visible in the shell environment running the script.
- If package load fails early inside `src/core/setup.wl`, the most likely cause
  is a missing or incompatible `FeynCalc` / `FeynArts` / `FeynHelpers`
  installation.
- If a route fails inside the `IBP` backend, check that the repository basis
  directories are present and that the required runtime artifacts have not been
  removed from `bases/`, `generated_bases/`, or `masterIntegrals/`.
- If an experimental route such as massive `A30` or `D30` returns `$Failed`,
  that is not automatically an installation failure. Those branches are
  intentionally callable but outside the supported release guarantee.
- If a bulk helper aborts on nonzero `quarkMass`, lowercase `maxOrder`, or
  unsupported models such as `SUSY` / `HiggsEFT`, that is current package
  behavior rather than a broken installation.
- If you modify derivation-side master-integral files and then see mismatches in
  integrated routes, refresh and revalidate
  `masterIntegrals/master_values_runtime.wl` before assuming the runtime route
  is wrong.

## Known Non-Goals

This release does not claim:

- a fully internal closed massive `A30` master-substitution derivation
- a finished public `D30` antenna extraction
- a finished `SUSY` or `HiggsEFT` `R`-ratio route
- that every research/provenance script under `dev/` is part of the supported
  user workflow

The project is considered complete around the massless package goal, not
around finishing every exploratory physics branch.

## Internal Architecture For Modifying Routes

Users who want to extend the package, add a new branch, or change the behavior
of an existing antenna family should read the code as a profile-driven system
rather than as one long chain of direct function calls.

The shortest accurate mental model is:

```text
public API call
  -> normalize a route key {type, multiplicity, loop order}
  -> look up metadata for that key
  -> run the workflow selected by that metadata
  -> format the result into a stable public shape
```

That metadata lookup is the center of gravity of the runtime.

If you want the shortest contributor path through the codebase, start in this
order:

1. `src/core/profiles.wl`
2. `src/routes/build_workflows.wl`
3. `src/routes/integration_workflows.wl`
4. `src/interface/build_router.wl`
5. `src/interface/integration_router.wl`

That sequence shows the package in the order it actually thinks: declare route
metadata first, then define route workflows, then adapt those workflows into a
stable public API.

### Why the package is profile-centric

The package supports several antenna families that are close enough to share a
public API but different enough that they should not be forced through one
hard-coded production formula.

Examples:

- `A30` tree level is a straightforward self-interference route.
- `A40` needs a color-ordered reconstruction layer.
- `B40` and `C40` are easier to build sector by sector.
- `A21` is naturally built through a one-loop `PaVe`-style route.
- `A31` and `A22` need different extraction logic and different integration
  backends even though they are both loop-level objects.
- massive `A30` and `D30` are genuine runtime branches, but they need to carry
  explicit honesty about experimental status.

If all of those choices were written directly into the public functions, the
API layer would become a long nest of family-specific `Switch` statements and
special cases. The profile-centric design avoids that. Instead, the public and
workflow layers ask a registry:

- what family is this?
- how should it be produced?
- how should it be extracted?
- what normalization applies?
- which backend should integration use?
- which diagnostics and route story should be attached?

That design makes the code easier to audit. It also makes branch work much
safer: most modifications are localized to metadata plus one workflow, instead
of requiring invasive edits across the entire package.

### The central object: the route key

Nearly all runtime dispatch starts from a key of the form:

```wl
{type, numFinalParticles, loopOrder}
```

Typical examples are:

- `{A, 3, 0}` for `A30`
- `{A, 2, 1}` for `A21`
- `{A, 2, 2}` for `A22`
- `{B, 4, 0}` for `B40`

That key is the compact identifier passed between the public interface, the
profile registry, the route workflows, and the integration layer.

### What lives in the profile registry

The main registry lives in `src/core/profiles.wl`. It is split into a few
closely related functions.

`AntennaProfile[key]` is the main build-side metadata record. Depending on the
family, it can specify:

- a readable name such as `A30` or `C40`
- the antenna type and multiplicity
- the production mode, such as `SelfInterference`,
  `ColorOrderedAntenna`, `SectorSelfInterference`, or
  `SectorSymmetrizedInterference`
- the extraction mode, such as `BornScalar`, `TreeColorCoefficients`,
  `LoopScalar`, `LoopColorCoefficients`, or `TwoLoopTTermComponents`
- normalization data such as `ColourNorm`
- sector definitions for routes that are built from sector splits
- component and contribution lists for multi-part routes such as `A22`
- implementation-status markers for experimental branches

`AntennaReductionProfile[key]` stores build-side loop-reduction preferences.
This is separate because “how to reduce the loop object before extraction” is
not always the same question as “how to integrate the final antenna later.”

`AntennaIntegrationProfile[key]` stores integration-side routing metadata:

- default backend, usually `PaVe` or `IBP`
- basis family, when the route is basis-driven
- expansion order
- convention metadata for routes such as `A21`
- branch-specific integration status when the route is still scaffolded or
  experimental

Two further helpers live in the same file and are important to understand:

- `AntennaAmplitude[key]`
- `AntennaSelfInterference[key]`

These lazily memoize reusable tree-level ingredients. The point is not only
speed. It also makes the source of shared Born objects explicit, so different
routes do not quietly drift toward different normalizations or “almost the same”
tree inputs.

### How build routing works

The public build functions live in `src/interface/build_router.wl`, but they do
not directly perform the physics work. Their main job is:

1. build the route key
2. collect options into a normalized association
3. ask for route data
4. format that route data into a plain result, an `AntennaObject`, diagnostics,
   or an `AntennaRunRecord`

The actual route orchestration happens in `src/routes/build_workflows.wl`.

At that layer the package asks `AntennaProfile[key]` what kind of route it is
dealing with. The crucial field is usually `Production`.

That `Production` field selects the workflow branch:

- `SelfInterference` means “build the amplitude, form the self-interference,
  then extract the antenna.”
- `ColorOrderedAntenna` means “build the full object, but also run the
  color-ordered reconstruction layer and expose its diagnostics.”
- `SectorSelfInterference` means “split the amplitude into named sectors and
  interfere only the route-relevant pieces.”
- `SectorSymmetrizedInterference` means “build the sector decomposition and
  then combine it through the symmetrized interference story required by that
  family.”

The extraction step is profile-driven too. The workflow does not hard-code one
universal “turn interference into antenna” rule. Instead it passes the raw
production object plus the profile to the extraction layer, whose behavior is
chosen by profile metadata such as `Extraction`, `ColourNorm`, components, and
contributions.

This is one of the main reasons the package is maintainable: the route layer
knows the family story, while the engine layer only has to know how to perform
one physical operation at a time.

### How integration routing works

The integration side follows the same architecture, but with a different
registry.

`IntegrateAntenna[...]` and `BuildAndIntegrateAntenna[...]` live in
`src/interface/integration_router.wl`. They consume an `AntennaObject`, recover
its key and selection metadata, and then ask `AntennaIntegrationProfile[key]`
how that object should be integrated.

That profile decides things such as:

- whether the route defaults to `PaVe` or `IBP`
- which basis family is the natural one for the route
- which expansion order is the default target
- whether a branch needs route-specific handling

The orchestration itself lives in `src/routes/integration_workflows.wl`. That
file coordinates:

- backend selection
- special-route handling such as the current massive `A30` integrated bridge
- contribution-by-contribution stitching for routes like `A22`
- backend diagnostics
- T-term construction
- final integrated-antenna extraction

The important design point is that build metadata and integration metadata are
deliberately separate. An object may be most natural to build in one symbolic
language and most natural to integrate in another. `A21` is the clearest
example: its build-side and integration-side stories are related, but not
identical, and the architecture keeps that distinction explicit.

### Why records and diagnostics matter in this design

Because the package is profile-driven, the internal data returned by each route
is association-shaped before it is turned into a public result. That is not an
accident and it is not just for debugging.

Those associations let the package carry:

- the resolved profile
- the route story
- intermediate amplitudes or interferences
- extracted components
- backend diagnostics
- component and contribution metadata
- stored-result reconstruction data

That is what makes `ReturnRecord`, `IntermediateSteps`, and diagnostics useful
without forcing the normal user-facing API to expose raw internal machinery by
default.

For branch work, this is especially valuable. When a new route is not yet
release-complete, the code can still return an honest structured record that
explains:

- what was built successfully
- what is still provisional
- where the route stopped
- whether the result is experimental, partial, or fully supported

That is exactly how the current massive `A30` and `D30` branches are kept
callable without pretending they are finished massless release routes.

### How to think about adding a new branch

The intended extension path is usually:

1. decide the new route key
2. add or extend its `AntennaProfile[key]`
3. add or extend its `AntennaIntegrationProfile[key]` if integration is needed
4. teach the build workflow how to interpret the chosen `Production` and
   `Extraction` settings
5. add any route-specific helper module if the branch is exceptional enough to
   deserve its own file
6. expose stable diagnostics and route stories
7. only then widen the public “supported” claim in the README and verification
   scripts

In practice, the easiest way to go wrong is to skip step 2 and encode branch
behavior directly in the interface layer. That usually feels faster at first,
but it weakens the architecture quickly because future readers can no longer
see the route definition in one place.

### Why this architecture is a good fit for this repository

This repository sits in an awkward but productive middle ground:

- it is not just a one-off notebook;
- it is not a generic symbolic algebra framework;
- and it is not a package where every family is physically interchangeable.

The profile-centric design is what lets it behave like a package without
flattening away the physical differences between antenna families.

It gives the codebase:

- one stable public API
- one auditable metadata layer where family-specific choices are declared
- reusable engine functions for the small symbolic operations
- route files that read like workflow stories rather than backend tangles
- an honest place to keep experimental branches inside the runtime without
  overstating their status

If you are modifying the code into new branches, that is the main principle to
preserve. Try to add new physics by teaching the registry and route layer about
the branch, not by letting branch-specific assumptions leak outward into every
public function.
