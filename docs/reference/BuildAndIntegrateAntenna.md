# `BuildAndIntegrateAntenna`

[Reference index](README.md) · [`BuildAntenna`](BuildAntenna.md) · [`IntegrateAntenna`](IntegrateAntenna.md) · [Documentation home](../README.md)

```wl
BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder, opts]
```

This is the one-shot convenience entry point. Its required architecture is:

```wl
obj = BuildAntenna[type, numFinalParticles, loopOrder,
  IntegrableForm -> True, ...];
IntegrateAntenna[obj, ...]
```

The public implementation follows that build-then-integrate workflow. It is
not allowed to use a distinct physics convention, hide an integration option,
or substitute a one-shot cached expression for a computation that the
corresponding direct route cannot perform. Cache controls are applied only to
the canonical build and integration stages.

## Options and return forms

Its integration options are exactly those of [`IntegrateAntenna`](IntegrateAntenna.md),
including `ReturnMasterCombination`, `ExpansionOrder`, `ReturnTTerms`, cache
controls, component selection, records, and intermediate-stage requests.

Build-side controls required to construct the input object—such as
`quarkMass`, `ApplyDimReg`, and `LoopMomentum`—are forwarded through the
workflow. For detailed option meaning, use the direct integration reference
together with [`BuildAntenna`](BuildAntenna.md).

The normal return is the integrated public result. With `ReturnDiagnostics`,
it is `{result, diagnostics}`; with `ReturnRecord`, it is an
`AntennaRunRecord` containing build and integration provenance.

## Example equivalence

```wl
oneShot = BuildAndIntegrateAntenna[A, 3, 0];

obj = BuildAntenna[A, 3, 0, IntegrableForm -> True];
explicit = IntegrateAntenna[obj];
```

For a supported route and identical options, `oneShot` and `explicit` are the
same public result. This equivalence is covered by regression checks for
component-wise integrable forms and master-combination return behaviour.
