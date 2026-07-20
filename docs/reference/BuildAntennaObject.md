# `BuildAntennaObject`

[Reference index](README.md) · [`BuildAntenna`](BuildAntenna.md) · [Documentation home](../README.md)

```wl
BuildAntennaObject[type, numFinalParticles, loopOrder, opts]
```

Builds an `AntennaObject[...]` that can be passed directly to
[`IntegrateAntenna`](IntegrateAntenna.md). It is the explicit object-building
form of the modular workflow:

```wl
obj = BuildAntennaObject[A, 3, 0];
result = IntegrateAntenna[obj];
```

It shares the build-side controls of [`BuildAntenna`](BuildAntenna.md), except
for the return-shape controls `ReturnRecord`, `ReturnBuildData`, and
`ReturnAntennaObject`. It always uses the public build branch: prototype output
is deliberately unavailable in an object intended for public integration.

For most ordinary workflows,

```wl
BuildAntenna[A, 3, 0, IntegrableForm -> True]
```

is the more direct way to express the build-to-integrate handoff. Use
`BuildAntennaObject` when one single full object is specifically required for
explicit orchestration or inspection.
