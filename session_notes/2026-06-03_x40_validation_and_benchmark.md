# 2026-06-03 X40 validation and benchmark pass

## Fresh-kernel public-route checks

Commands run from a clean kernel:

```wl
BuildAndIntegrateAntenna[B, 4, 0, ReturnDiagnostics -> True, ExpansionOrder -> 0]
BuildAndIntegrateAntenna[C, 4, 0, ReturnDiagnostics -> True, ExpansionOrder -> 0]
```

Observed behavior after correcting the earlier `Check[...]` wrapper mistake:

```text
A40 Leading        public route succeeds; backend diagnostics report
                   UnmatchedCount -> 0 and RemainingTojSpOrDotQ -> False

A40 Subleading     treated as already verified in the package regression notes

B40                BuildAntennaObject[B, 4, 0] succeeds in about 10 s
                   IntegrateAntenna[obj, ...] succeeds in about 81 s
                   BuildAndIntegrateAntenna[...] succeeds in about 90 s
                   Returns the expected {integrated expression, diagnostics}
                   pair through both public routes

C40                BuildAntennaObject[C, 4, 0] succeeds in about 6 s
                   IntegrateAntenna[obj, ...] succeeds in about 252 s
                   BuildAndIntegrateAntenna[...] succeeds in about 255 s
                   Returns the expected {integrated expression, diagnostics}
                   pair through both public routes
```

The earlier `$Failed` conclusion for `B40` and `C40` was a false negative from
wrapping the calls in `Check[..., $Failed]`, which caught the intentional
`IntegrateAntenna::heavy` warning message.

## Benchmark harness

Added:

```text
dev/run_public_route_benchmarks.wl
```

Current behavior:

```text
- Loads the package from a clean kernel
- Runs only public entrypoints
- Measures BuildAntenna, BuildAntennaObject, IntegrateAntenna, and
  BuildAndIntegrateAntenna
- Covers the baseline route set agreed for the benchmark phase
- Emits a JSON report with route label, entrypoint, wall-clock time,
  success/failure, timeout flag, and diagnostic summary fields when available
```
