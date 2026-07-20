# `BuildAntenna`

[Reference index](README.md) · [Public API overview](../manual/public-api.md) · [Documentation home](../README.md)

```wl
BuildAntenna[type, numFinalParticles, loopOrder, opts]
```

Builds one public unintegrated antenna. The route key is written directly, for
example `BuildAntenna[A, 3, 0]` for massless tree-level `A30`.

## Normal returns

- A scalar expression for a single-component route.
- An ordered list for a multi-component route, unless `Component` selects one
  public component.
- An integration-ready object or component-wise objects with
  `IntegrableForm -> True`.

`BuildAntennaObject[...]` is the explicit convenience form for requesting one
`AntennaObject`; it accepts the same build controls except `ReturnRecord`.

## Normal-use options

`printDiagram -> True` is an inspection feature only: it renders the generated
FeynArts diagram set and does not alter the amplitude, reduction, or returned
antenna. Tree diagrams are rendered explicitly even when the corresponding
Born amplitude was already memoized in the current kernel.

| Option | Default | Meaning |
|---|---:|---|
| `Component` | `All` | select a named public component when present |
| `IntegrableForm` | `False` | return the route form consumed by `IntegrateAntenna` |
| `IntermediateSteps` | `{}` | request diagnostic construction stages |
| `printDiagram` | `False` | print FeynArts diagrams for the route sources, including a memoized Born source |
| `quarkMass` | `0` | select the experimental massive branch when supported |
| `UseStoredResults` | `False` | reuse a matching stored public result |
| `StoreResults` | `False` | store a successful public result |

`IntermediateSteps` accepts `None`, `False`, `{}`, one string, a list of
strings, `True`, or `All`. `True` and `All` return a compact, route-aware
association rather than the raw build record. The ordinary tree view is
`"Amplitude"`, `"Interference"`, and `"Antenna"`. One-loop routes additionally
provide `"InterferenceBeforeReduction"` (the expression immediately before the
selected loop reduction) and `"ReducedInterference"` (the PaVe form on a PaVe
route). Request individual labels to retrieve only the stages needed.

For example:

```wl
{antenna, steps} = BuildAntenna[A, 3, 1, IntermediateSteps -> True];
steps["InterferenceBeforeReduction"]
```

The complete route-owned association remains available separately through
`BuildAntenna[..., ReturnRecord -> True]["BuildData"]`.

## Inspection and expert options

| Option | Meaning |
|---|---|
| `ReturnDiagnostics` | return `{result, diagnostics}` |
| `ReturnRecord` | return an `AntennaRunRecord` with full provenance stages |
| `PrintIntermediateSteps` | print the requested captured stages; retained for compatibility |
| `ResultsCacheRoot`, `RefreshStoredResults` | cache-root and cache-refresh controls |

`ReturnBuildData` and `ReturnAntennaObject` remain accepted only as deprecated
compatibility aliases. They issue a message and should not be used in new code.
Use `BuildAntenna[..., ReturnRecord -> True]["BuildData"]` for route-owned
build data. Use `IntegrableForm -> True` for the composable integration input,
or `BuildAntennaObject[...]` for one full object. Source contributions are
route-owned: inspect `"ContributionsUsed"` in a record or diagnostics payload
rather than selecting one directly.

## Derivation and prototype controls

These options remain supported for expert investigation but are not ordinary
public workflow controls:

```text
RunPaperCheck, Verbose, prefactor, ApplyStripCouplings,
ApplyCasimirSubstitution, ApplyDimReg, LoopMomentum, LoopMomenta,
ReductionBackend, BuildOutputBranch, AllowPrototypeTargets,
UseSourceModelRoute
```

`BuildOutputBranch -> "Prototype"` is direct-expression inspection only. It is
intentionally rejected with `BuildAntennaObject` or `IntegrableForm -> True`;
these object forms retain the public branch.

`LoopMomentum` and `LoopMomenta` are real backend inputs, not merely cosmetic
replacement rules. Changing a completed expression afterwards is not generally
equivalent to choosing the loop variable before FeynCalc/LiteRed processing.

## Relevant stage names

The compact build-stage collector recognises:

```text
Amplitude
InterferenceBeforeReduction
ReducedInterference
Interference
Antenna
```

The former raw labels (`BuildData`, `BuildOutputBoundary`,
`BuildOutputBoundarySummary`, `FullBuildResult`, `SelectedBuildResult`,
`AntennaObject`, and `BuildDiagnostics`) remain available only when explicitly
named for expert inspection.

See [records and diagnostics](records-and-diagnostics.md) for how stages,
records, and printing currently interact.
