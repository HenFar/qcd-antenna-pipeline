# Installation, loading, and verification

[Manual index](index.md) · [Route status](route-status.md) · [Documentation home](../README.md)

## Requirements

Supported AntCalc workflows need a Wolfram Language kernel and the
high-energy-physics environment used by the package:

- FeynCalc;
- the FeynArts and FeynHelpers components used through FeynCalc;
- LiteRed2 for IBP-backed integration routes.

Some routes also use Package-X through the FeynCalc/FeynHelpers environment.
The repository ships basis and runtime-master artifacts in `bases/`,
`generated_bases/`, and `masterIntegrals/master_values_runtime.wl`; retain them
when copying or cloning the package. AntCalc does not rebuild the derivation
layer merely to start a kernel session.

The package has been exercised on macOS Apple Silicon and Windows Intel
systems. This is evidence of tested environments, not a cross-platform runtime
or memory guarantee.

## Validated alpha-3 environment

The alpha-3 release was verified with this symbolic-backend baseline:

```text
FeynCalc 10.2.1 · FeynArts 3.12 (27 Mar 2025) ·
FeynHelpers 2.0.0 · FeynCalcLegacy 1.0.0
LiteRed2 2.025 β
```

The package records this baseline in `AntennaPipelineConventionReport[]`.
The startup banner reports the versions actually found in the current kernel;
that report is diagnostic information, not a claim that every arbitrary newer
or older combination has been validated.

## Install the paclet

After cloning the complete repository, install AntCalc once:

```wl
repoRoot = "/path/to/antenna_pipeline";
archive = CreatePacletArchive[repoRoot, $TemporaryDirectory];
PacletInstall[archive];
```

If you are reinstalling a changed development build with the same paclet
version, use:

```wl
PacletInstall[archive, ForceVersionInstall -> True];
PacletDataRebuild[];
```

Restart the kernel after installation, then load the package:

```wl
<< AntCalc`
```

If a notebook kernel was already active when the paclet was installed,
`PacletDataRebuild[]` followed by a kernel restart refreshes its paclet index.

## Develop from a checkout

During active source editing, use the repository loader instead of the
installed paclet. It reads the saved checkout immediately:

```wl
repoRoot = "/path/to/antenna_pipeline";
Get[FileNameJoin[{repoRoot, "AntennaPipeline.wl"}]]
```

Use `<< AntCalc`` to test the packaged copy an external user would receive.
Rebuild and reinstall that paclet after a coherent group of changes. A fresh
kernel is the reliable way to ensure old definitions are not still resident.

## Verify an installation

The supported release acceptance command is:

```sh
cd /path/to/antenna_pipeline
bash dev/run_release_verification.sh
```

It uses the checkout loader, excludes experimental massive `A30` and `D30`,
and exercises representative public build, integration, record, and driver
routes. It requires `wolframscript` on `PATH`; symbolic route duration depends
on the local backend environment.

The physics-validation harness is developer-facing:

```sh
cd /path/to/antenna_pipeline
bash dev/run_physics_validation.sh
```

It reports explicit `Pass`, `Fail`, `KnownIssue`, `RouteEvaluationFailed`, or
`NotAvailableYet` states; it is not a substitute for the release acceptance
command.

## Troubleshooting

- A load failure in `src/core/setup.wl` usually indicates a missing or
  incompatible FeynCalc, FeynArts, or FeynHelpers installation.
- An IBP failure can indicate missing basis directories or runtime-master
  artifacts.
- A `$Failed` result from massive `A30` or `D30` is not necessarily an
  installation error: these routes are experimental.
- Bulk helpers currently reject nonzero `quarkMass`, lowercase `maxOrder`, and
  unsupported models such as `SUSY` and `HiggsEFT`.
- If derivation-side master-integral files change, refresh and validate the
  runtime-master artifact before attributing an integrated-route mismatch to
  the public runtime.
