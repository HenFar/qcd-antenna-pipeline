# Conventions and normalisation

[Manual index](index.md) · [Route status](route-status.md) · [Documentation home](../README.md)

This page states the package-facing conventions used by supported AntCalc
routes. It distinguishes public antenna definitions, colour coefficients,
backend expressions, and experimental provenance bridges.

## Public convention boundary

`BuildAntenna` is intended to return package-facing results in the package
normalisation and renormalisation convention. `IntegrateAntenna` and
`BuildAndIntegrateAntenna` preserve that convention. Bare, pre-counterterm, or
route-native expressions are provenance objects; they are not a second public
physics result.

Build records retain a `Public`/`Prototype` boundary for inspection. The
prototype branch is provisional and only supported for direct
`BuildAntenna[..., BuildOutputBranch -> "Prototype"]` expression inspection;
it is intentionally unavailable through integration-ready object forms.

## Colour components

For `A40`, `Leading` denotes one ordered `A4^0` antenna and `Subleading`
denotes `tilde A4^0` itself. The raw full-colour coefficient has the relation

```text
full-colour subleading coefficient = - tilde A4^0
```

The minus belongs to colour algebra at observable assembly; it is not absorbed
into the public antenna definition. The same separation between colour factors
and antenna definitions applies to analogous components.

## Dimensional regularisation and scales

The package declares one working continuation,

```text
D -> 4 - 2 Epsilon
```

controlled by `ApplyDimReg`. This is a package-wide convention for supported
workflows, not a menu of independently validated `CDR`, `HV`, `GDR`, or
external-state prescriptions.

`q2` is the canonical public kinematic scale. The integration surface exposes
`KinematicScale -> q2` and `NormalizeKinematicScale`; inspect the route
environment report for the effective defaults of a specific route.

## Loop and backend bridges

Loop construction and integration are separate normalisation layers. The build
layer uses `LoopExpansionNormalization[1] = 8 Pi^2` and
`LoopExpansionNormalization[2] = (8 Pi^2)^2` when mapping loop objects into the
package expansion convention. A raw `PaVe` or IBP expression is therefore not
automatically a public integrated antenna.

On relevant PaVe routes, `PaVeEvaluation -> "PaXEvaluate"` and
`ApplyFeynCalcMS -> True` are the public defaults. The massless `A21` route
uses an explicit Package-X-to-paper conversion rather than treating raw
`PaXEvaluate` output as final convention data. IBP loop families likewise use
an explicit backend-to-public convention bridge, reported in diagnostics as
`"ConventionBridgeFactor"` where applicable.

## A31 and A22

The public `A31` build branch applies the required lower-`A30` UV-counterterm
pattern; the prototype branch retains pre-counterterm route-native components
for provenance. The public integrated `A31` components match their encoded
targets after the master-convention repair.

For `A22`, the supported integrated object is the paper-facing
`T_{qq}^{(6)}` component set, not an unspecified package-internal final
antenna. The two-loop route is handled through dedicated master-integral
machinery rather than a generic PaVe basis.

## Massive A30

The unintegrated massive `A30` route is package-derived. Its integrated route
can reduce to the runtime `MX30` master basis, but the relation between the
dotted runtime second master and the literature numerator master has not been
derived internally. Any closed literature comparison remains a documented
experimental bridge, not a validated runtime derivation. See the [route
status](route-status.md) and the later research documentation.

## Inspecting convention state

```wl
AntennaPipelineConventionModel[]
AntennaPipelineConventionReport[]
AntennaPipelineDimRegDeclaration[]
AntennaRouteProfileReport[A, 3, 1]
AntennaRouteEnvironmentReport[A, 3, 1]
```
