# Research-status ledger

[Developer index](README.md) · [Route status](../manual/route-status.md) · [Documentation home](../README.md)

This is a dated development snapshot, not the supported-route contract. For
what AntCalc currently promises to an external user, use the [route-status
matrix](../manual/route-status.md).

## Current position

AntCalc is in-progress thesis research software. Its supported massless routes
are suitable for inspection, testing, and academic evaluation; the repository
is not a frozen general-purpose release. Experimental branches and `dev/`
scripts record active work, not hidden promises of completeness.

## Recent milestones

- **2026-07-15:** raw one-loop A31 Ward identity passes after PaVe tensor
  reduction.
- **2026-07-14:** massless A30 and both A40 external-gluon Ward replacements
  pass exactly.
- **2026-07-14:** fresh uncached NNLO `BuildRRatio` validation closes through
  epsilon^0 and agrees with the encoded SMQCD finite target.
- **2026-07-14:** A31 Appendix A.2 master phase/convention repair reproduces
  direct paper targets and removes EulerGamma from public series.
- **2026-07-11:** public integrated A22 matches the
  `hep-ph/0403057` paper-facing `T_{qq}^{(6)}` components; the combined
  diagnostics route completes.
- **2026-07-08:** A40/B40/C40 normalisation was aligned with the standard A30
  convention path.
- **2026-07-01:** package-wide defaults and stored-result semantics were
  consolidated and revalidated.
- **2026-06-29–30:** the A31 public build boundary and direct-expression
  public/prototype selector were introduced.

## Completed foundation

The following development tracks are complete enough to underpin the current
massless contract:

1. canonical convention metadata and route/environment reports;
2. explicit `D -> 4 - 2 Epsilon` declaration;
3. public/prototype output-boundary infrastructure;
4. A31 public build-side counterterm presentation and integrated target repair;
5. PaVe/Package-X and IBP convention bridges;
6. package-wide defaults with explicit precedence;
7. cache semantic-versioning and public/prototype cache separation;
8. exact massless validation slices for integrated routes, R-ratio closure,
   and applicable Ward identities.

## Active and deferred work

| Track | Status |
|---|---|
| Catani-operator validation | not yet implemented |
| Factorisation-limit validation | not yet implemented |
| Massive A30 second-master derivation | unresolved research objective |
| User-facing examples/tutorial notebooks | planned separately from `dev/` scripts |
| Broader convention-regression coverage | deferred maintenance work |
| Systematic massive programme, massive B4/C4, initial-state antennae | research extensions |

The massive A30 objective is a derivation of the paper/runtime master-basis
relation, not a closed value solved backwards from literature agreement.

## Experimental inspection

Experimental branches remain callable for diagnostics, but neither their
availability nor a stored result is a supported-result claim.

```wl
BuildAntenna[A, 3, 0, quarkMass -> mQ, ReturnRecord -> True]
BuildAntennaObject[A, 3, 0, quarkMass -> mQ]
BuildAndIntegrateAntenna[A, 3, 0, quarkMass -> mQ, ReturnDiagnostics -> True]

BuildAntenna[D, 3, 0, ReturnDiagnostics -> True]
BuildAntenna[D, 3, 0, ReturnRecord -> True]
```

Related derivation and source-route material is under
[`dev/massiveA30`](../../dev/massiveA30),
[`dev/massiveA30_sources`](../../dev/massiveA30_sources), and
the current D30 scratch material under [`dev/scratch/d30`](../../dev/scratch/d30).

## Benchmarking is not acceptance

The benchmark harness is available locally:

```sh
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -noprompt \\
  -script dev/run_public_route_benchmarks.wl
```

It records performance characteristics only. Release and physics acceptance
remain separate correctness-facing workflows; a timeout or a fast cached value
does not establish physics agreement.

## Transparency rules

- Supported, experimental, and prototype states must remain distinct.
- A route is not “complete” merely because a cached/stored expression matches
  a paper target.
- Diagnostics should report unresolved bridge status rather than mask it.
- Interface documentation should describe actual current behaviour and mark
  compatibility controls under redesign.

## Authorship note

The physics, package architecture, and profile/route design are thesis work by
the repository author. AI coding tools were used for implementation
acceleration, bug finding, stress testing, and documentation drafting from the
author's working notes and task tracking.
