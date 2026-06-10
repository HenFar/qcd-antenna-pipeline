# Antenna Pipeline

`antenna_pipeline` is a Mathematica package for building and integrating QCD
antenna functions through a small public API. It packages the thesis workflow
into reusable functions so that interested users can generate tree-level and
loop-level antenna ingredients, inspect intermediate stages when needed, and
reproduce the massless A-type results used in the NNLO `R`-ratio calculation
without working directly through the original notebooks.

The package is intentionally loaded with plain Wolfram `Get[...]` calls rather
than package contexts.  This keeps the current FeynCalc/FeynArts/FeynHelpers
symbol behavior unchanged.

## Project Target

The package-level goal is:

```text
Load one Mathematica package, call public functions, and reproduce the
massless A-type antenna ingredients needed for the NNLO R-ratio calculation
described in hep-ph/0403057.
```

In practice that means the package should be able to:

```text
1. Build the required massless A-type antennae from public entry points.
2. Integrate the required antennae through the package backends.
3. Match the published 0403057 results for the A-type ingredients used in
   the R-ratio construction.
4. Be usable by someone who did not write the thesis notebooks.
```

## Status Bar

Current project status against that target:

```text
[done] Public package load via Get[".../AntennaPipeline.wl"]
[done] Public unintegrated A-type tree antennae: A20, A30, A40, tildeA40
[done] Public unintegrated B40 and C40
[done] Public integrated A21
[done] Public integrated A30
[done] Public integrated X40-family route for A40 / tildeA40 / B40 / C40
[done] Public integrated A31, tildeA31, hatA31
[done] Public integrated A22, tildeA22, hatA22, breveA22 via the stitched route
[done] A22 matched to 0403057 through the real IBP path
[done] X40 public-route validation is closed to the current fresh-kernel state
[done] Baseline public-route benchmark runner completed an initial timing map
       in `dev/run_public_route_benchmarks.wl`
[done] Optional public intermediate-step capture and printing are available via
       `IntermediateSteps -> {...}` and `PrintIntermediateSteps -> True`
[done] Shared `X40` basis-order optimization is adopted as the default public
       route behavior; timing diagnostics identify basis matching as the main
       performance bottleneck
[done] Prototype public `BuildRRatio[SMQCD, quarkMass -> 0]` driver now
       assembles the final symbolic massless NNLO `R`-ratio expression from
       the validated public antenna routes
[partial] Package usability/docs are improving, but the repo is not yet in the
          final "anyone can load it and reproduce the whole 0403057 A-type
          story without guidance" state
[todo] Final polish for distributable package usability: clearer onboarding,
       end-to-end verification workflow, and heavy-route ergonomics
```

All current target A-type public antenna routes now run.  The remaining gap is
not missing A-type coverage; it is runtime/usability polish around routes that
are already implemented and validated but can still be very heavy in practice.

## Release Checklist

Operational checklist for the massless A-type 0403057 package goal:

```text
Legend:
  build     = public BuildAntenna[...] route exists
  integrate = public IntegrateAntenna[...] route exists
  paper     = matched to the encoded paper target / diagnostic target
  clean     = verified from a fresh kernel through the public route
  notes     = main caveat for package users
```

```text
Family / object                  build   integrate   paper   clean   notes
----------------------------------------------------------------------------
A20                             yes     n/a         yes     yes     tree-level public object
A30                             yes     yes         yes     yes     integrated through X30 IBP
A40                             yes     yes         yes*    yes     fresh-kernel public route verified via `Component -> Leading`; current object integration runtime about 194 s on MacBook Pro M4 after shared `X40` basis reordering
tildeA40                        yes     yes         yes*    yes     fresh-kernel public route verified via `Component -> Subleading`; current object integration runtime about 582 s on MacBook Pro M4 after shared `X40` basis reordering
B40                             yes     yes         yes*    yes     fresh-kernel public object and one-shot routes both verified; current object integration runtime about 16 s on MacBook Pro M4 after shared `X40` basis reordering
C40                             yes     yes         yes*    yes     fresh-kernel public object and one-shot routes both verified; current object integration runtime about 308 s on MacBook Pro M4 after shared `X40` basis reordering
A21                             yes     yes         yes     yes     public PaVe/Package-X route
A31                             yes     yes         yes     yes     public integrated final antenna route; current object integration runtime about 197 s on MacBook Pro M4 after the A31 family basis reordering
tildeA31                        yes     yes         yes     yes     returned with A31 list route
hatA31                          yes     yes         yes     yes     returned with A31 list route
A22                             yes     yes         yes     yes     stitched public route via TwoLoopTree + OneLoopSelf
tildeA22                        yes     yes         yes     yes     stitched public route
hatA22                          yes     yes         yes     yes     stitched public route
breveA22                        yes     yes         yes     yes     one-loop-self branch of stitched route
```

`yes*` here means the unintegrated tree-level paper diagnostics are already in
the package and exposed through the existing diagnostics workflow; the
integrated public-route status for the X40 family is now whatever the fresh
kernel returns today, and the fresh-kernel public checks now succeed for
`A40`, `tildeA40`, `B40`, and `C40`.

## Roadmap

The next work should be organized in this order.

### Immediate Benchmark Queue

```text
1. Use the completed baseline benchmark snapshot to target the real runtime
   bottlenecks, rather than guessing from route complexity alone.
2. The shared `X40` basis reorder is now the adopted default for the family;
   it substantially improves `A40` and `B40`, with a modest accepted
   regression on `C40` in exchange for keeping the full `X40` family on one
   common basis-order structure.
3. `A31 Leading` has now been inspected with the same timing diagnostics, and
   its dominant cost is also `MatchIBPBasis`.
4. An `A31` family basis-order optimization is now adopted from that timing
   evidence; the refreshed post-reorder `A31 Leading` object-first baseline is
   about 197 s on a MacBook Pro M4.
5. Keep the benchmark harness as the standard way to compare future changes
   against the current baseline.
```

### Mandatory Package Milestones

```text
1. Performance / efficiency pass.
   - Initial baseline timing data is now in hand for the agreed public-route
     matrix on a MacBook Pro M4.
   - Timing diagnostics now show that the dominant `X40` cost is
     `MatchIBPBasis`, not basis loading and not the final
     series/simplification stage.
   - The shared `X40` basis reorder is now adopted as the default family-wide
     optimization.  On the benchmark MacBook Pro M4 it reduces:
       `A40 Leading` object integration from about 690 s to about 194 s,
       `A40 Subleading` from about 1823 s to about 582 s,
       and `B40` from about 85 s to about 16 s.
   - `C40` becomes somewhat slower under the shared order (about 308 s instead
     of about 260 s), but that tradeoff is currently accepted to preserve a
     single common `X40` family structure rather than route-specific basis
     heuristics.
   - `A31 Leading` shows the same bottleneck shape as `X40`: basis loading and
     final simplification are negligible, while `MatchIBPBasis` dominates the
     run.
   - The `A31` family basis order is now updated to prioritize the dominant
     matched bases (`A31Basis9`, `A31Basis10`, `A31Basis12`, `A31Basis2`,
     then `A31Basis6` and `A31Basis5`).
   - That family reorder reduces the fresh-kernel `A31 Leading`
     object-first route from about 695 s to about 197 s on the benchmark
     MacBook Pro M4.

2. Intermediate-step visibility.
   - Done in the current public API: `IntermediateSteps -> {...}` captures
     named build-side and integration-side stages without changing default
     black-box behavior.
   - Done in the current public API: `ReturnRecord -> True` on
     `BuildAntenna[...]`, `IntegrateAntenna[...]`, and
     `BuildAndIntegrateAntenna[...]` returns an inspectable
     `AntennaRunRecord[...]` wrapper whose `"Result"` field matches the
     historical public return exactly.
   - `PrintIntermediateSteps -> True` adds a notebook-friendly view layer on
     top of the same structured stage capture.
   - Record mode is the "do not hide what was already computed" path:
     diagnostics are always included there, and the useful build/integration
     stages can be inspected later without rerunning the route.

3. Loop-build public API cleanup.
   - Done in the current public API: one-loop `BuildAntenna[...]` now defaults
     to the PaVe-reduced form users are expected to inspect.
   - The raw unreduced loop expression remains available explicitly through
     `ReductionBackend -> None` on the build side.
   - Integrable one-loop objects now choose their build-time reduction shape
     from the route they need to feed, so the object-first integration path
     stays consistent with the route backend.
   - `IntegrateAntenna[...]` no longer exposes a separate PaVe-shape toggle;
     that choice now lives entirely at build time.

4. Prototype R-ratio driver.
   - Done in the current public API for massless `SMQCD`:
     `BuildRRatio[SMQCD, quarkMass -> 0]`.
   - The driver uses the thesis notebook/package formula as its assembly
     source and collects the required antenna ingredients through the
     validated public routes.
   - `BuildRRatio[SUSY, ...]` and `BuildRRatio[HiggsEFT, ...]` now exist as
     explicit public shells, but still return clear not-yet-implemented
     failures in this prototype milestone.

5. Wolfram-facing documentation polish.
   - Add usage comments / inline function documentation so Mathematica
     autocomplete and help popups expose meaningful summaries.
   - Expand the README with reproducible examples, runtime expectations, and
     staged validation commands.
```

### Thesis / Research Extensions

```text
1. Derive the 0403057 master integrals "by hand" as a thesis-methods layer,
   even though the package can already substitute the validated master values.

2. Extend beyond A-type into D-type and F-type antennae.
   - First exploratory target: one example antenna in each model family,
     such as `D30` and `F30`.
   - Planned route: test `SUSY` and `HiggsEFT` model support through FeynCalc /
     FeynArts and use those examples to establish the multi-model workflow.
```

### Guiding Principle

```text
First make the current massless 0403057 A-type package robust, measurable, and
inspectable.  Only then extend the physics scope to new models and new antenna
families.
```

### Thesis Priority Tiers

```text
Tier 1: thesis-critical, must finish before defense preparation
- Run and extend the timing / benchmark suite for the public antenna routes.
- Add options to expose intermediate pipeline stages for debugging and
  explanation.
- Keep the prototype public R-ratio driver for massless SMQCD aligned with
  the thesis formula and the validated public ingredient routes.
- Improve function comments / usage text so Mathematica-side discoverability is
  acceptable during the thesis and defense period.
- Write the thesis around the validated massless A-type package story.

Tier 2: thesis-useful, only if Tier 1 is stable
- Work out at least one 0403057 master-integral derivation "by hand" for the
  thesis narrative.
- Try one exploratory beyond-A-type example such as D30 or F30.
- Try one exploratory non-SMQCD model path such as SUSY or HiggsEFT.

Tier 3: post-defense / follow-up paper scope
- Systematic D-type and F-type implementation.
- Broader SUSY / HiggsEFT support.
- Full software-polish pass beyond thesis-critical usability.
```

## Current Scope

Implemented tree-level antennae:

```text
A20
A30
A40
tildeA40
B40
C40
```

Implemented one-loop infrastructure:

```text
A21 unintegrated
A31, tildeA31, hatA31 unintegrated diagnostics
A21 integrated through the PaVe/Package-X route
X30/A30 integrated through the LiteRed IBP route
X40 four-particle tree phase-space IBP backend infrastructure
X31/A31 LiteRed IBP basis and master infrastructure
A31 T-term to integrated-antenna postprocessing
A22 experimental source-production hooks, generated one-loop self and
two-loop-tree IBP bases, and 0403057 T-term targets
```

The A21 integrated route uses `FeynCalc`PaXEvaluate` as the integral evaluator.
The remaining normalization is a Package-X-to-paper convention conversion for
the real massless two-parton final-state branch.  The production route does not
replace `B0` or `C0` by hand.

The first IBP-backed route is the X30/NLO integration used by A30.  It loads
existing LiteRed bases from disk, reduces to the `R3` master, and matches the
finite-truncated result quoted in the X30 IBP notebook.

The X40 IBP backend loads the existing 72 LiteRed bases from disk, covering
all 24 final-state permutations for the `chain`, `box`, and `hybrid`
topologies.  It classifies reduced masters into `R4`, `R6`, `R8a`, and `R8b`,
then applies the finite-truncated master expansions and the four-particle
global normalization used in the X40 notebook.  The same backend now sits
behind the public `IntegrateAntenna[...]` route for `A40`, `tildeA40`,
`B40`, and `C40`.  Fresh-kernel public validation now gives a clean public
result for the full X40 family:

```text
A40 Leading:    clean through the public route; object-first timing after the
                shared X40 basis reorder is about 194 s on a MacBook Pro M4
A40 Subleading: clean through the public route; object-first timing after the
                shared X40 basis reorder is about 582 s on a MacBook Pro M4
B40:            clean through both `IntegrateAntenna[obj,...]` and
                `BuildAndIntegrateAntenna[...]`; object-first timing after the
                shared X40 basis reorder is about 16 s on a MacBook Pro M4
C40:            clean through both `IntegrateAntenna[obj,...]` and
                `BuildAndIntegrateAntenna[...]`; object-first timing after the
                shared X40 basis reorder is about 308 s on a MacBook Pro M4
```

So the remaining X40 work is no longer validation closeout; it is family-level
performance and usability work around routes that are now verified and
materially faster under the shared basis-order optimization.

The X31/A31 IBP backend loads the existing A31, A31SL, and A31Super LiteRed
bases from `momentumBasis`.  It converts the FeynCalc one-loop antenna
integrands to the k1,k2,k3,l LiteRed convention, reduces direct terms, and
maps the reduced masters into the `V5a`, `V5b`, and `V8` literature master
classes.  The route is intentionally conservative: term-level reductions are
validated, while full-component reductions are expected to be expensive and
should be launched deliberately.

The A31 and A22 runtime master substitutions are now loaded from the
checked-in artifact `masterIntegrals/master_values_runtime.wl`.  That artifact
is exported from the derivation/provenance layer under `masterIntegrals/`, so
the package keeps a visible source for those values without recomputing the
master derivations during normal package loads.

For A31 the integrated IBP components are first interpreted as the colour
brackets of the `Tqqg6` object.  The post-integration layer then applies the
known T-to-antenna relations, including the lower-order `A21 A30` product and
renormalization pieces, to produce `{A31, tildeA31, hatA31}`.

A22 is currently recognized as a four-component two-parton, two-loop sector
with component order `{Leading, Subleading, Nf, Breve}`.  Experimental source
production hooks exist for the tree/two-loop interference and one-loop
self-interference, and the 0403057 T-term targets are encoded for diagnostics.
The one-loop self-interference route has a generated LiteRed basis family,
`A22OneLoopSelf`, so the `Breve` source can be matched and reduced to its
factorised two-bubble master.  That master is identified with the `A22,LO`
virtual two-loop master in appendix A.1 of hep-ph/0403057 and substituted in
the paper convention.  This reproduces the `Tqqbar^(6,[1x1])` Breve bracket.
The tree/two-loop route has a generated eight-basis family,
`A22TwoLoopTree`; the leading component now reduces with no unmatched IBP
terms and no leftover LiteRed objects, and the public
`Contribution -> TwoLoopTree, Component -> Leading` route now reproduces the
0403057 `Tqqbar^(6,[2x0])` bracket through topology-specific IBP master
substitution.  The `Subleading` and `Nf` tree/two-loop routes now match the
remaining 0403057 colour brackets through the same real IBP path.

After editing the derivation-side master files, refresh the checked-in runtime
artifact with:

```sh
bash masterIntegrals/run_kernel.sh -run 'Get["masterIntegrals/export_runtime_master_values.wl"]; Exit[]'
```

Then verify that the artifact still matches the live derivation layer:

```sh
bash masterIntegrals/run_kernel.sh -run 'Get["dev/validate_runtime_master_values.wl"]; Exit[]'
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

Loading the master file only defines the functions, profiles, paper targets,
and diagnostics.  It does not build amplitudes, interferences, or antennae.
Call the public functions explicitly:

```wl
BuildAntenna[A, 2, 0]
BuildAntenna[A, 4, 0]
BuildAndIntegrateAntenna[A, 2, 1]
RunAntennaDiagnostics[]
```

For notebook compatibility, the old public variables can still be populated
on demand:

```wl
AssignAntennaProductionVariables[]
```

This assigns:

```wl
A20
A30
A40
tildeA40
B40
C40
```

## Public Entry Points

The main public entry points are:

```wl
BuildAntenna[type, numFinalParticles, loopOrder]
BuildAntennaObject[type, numFinalParticles, loopOrder, ...]
IntegrateAntenna[antennaObject, ...]
BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder, ...]
BuildRRatio[model, ...]
```

`BuildAntenna[...]` is the constructor.  The primary integration route is now
object-based: build an antenna object with `BuildAntennaObject[...]` or
`BuildAntenna[..., IntegrableForm -> True]`, then pass that object to
`IntegrateAntenna[...]`.  For one-loop antennae the default build output is
now the PaVe-reduced form; request `ReductionBackend -> None` if you
specifically want the raw unreduced loop expression instead.  The plain
`BuildAntenna[...]` output stays readable by default and is intentionally not
directly integrable, because it does not carry the routing metadata needed by
the integration backends.  The older `LegacyIntegrateAntenna[type, n, loop,
...]` form is still available as compatibility sugar and delegates to
`BuildAndIntegrateAntenna[...]`.

`BuildRRatio[...]` is the first high-level physics driver layered on top of
those antenna routes.  In the current prototype it supports only the massless
`SMQCD` case and returns the final symbolic NNLO `R`-ratio expression built
from the validated public antenna ingredients.  The `SUSY` and `HiggsEFT`
entry points already exist as explicit API shells, but they still fail
cleanly as not-yet-implemented placeholders.  The current output uses the same
package conventions as the ingredient routes, so the symbolic result is
expressed in terms of `SUNN`, `Nf`, `FeynCalc\`Epsilon`, `q2`, and
`SMP["alpha_s"]`.

All current public entry points also accept an optional generated-result cache
layer:

```wl
UseStoredResults -> False
StoreResults -> False
ResultsCacheRoot -> Automatic
RefreshStoredResults -> False
```

Caching is off by default.  The normal pipeline remains the source of truth:
stored results are generated artifacts that can be regenerated from fresh
public-route evaluations whenever needed.

The cache can also be inspected directly through two read-only helpers:

```wl
ListStoredResults[]
StoredResultInfo[...]
```

### Quick API Reference

Unintegrated antennae:

```wl
BuildAntenna[A, 2, 0]  (* A20 *)
BuildAntenna[A, 3, 0]  (* A30 *)
BuildAntenna[A, 4, 0]  (* {A40, tildeA40} *)
BuildAntenna[B, 4, 0]  (* B40 *)
BuildAntenna[C, 4, 0]  (* C40 *)
BuildAntenna[A, 2, 1]  (* A21 *)
BuildAntenna[A, 3, 1]  (* {A31, tildeA31, hatA31} *)
BuildAntenna[A, 2, 2]  (* experimental/heavy: {A22, tildeA22, hatA22, breveA22} *)
BuildAntenna[A, 2, 1, ReductionBackend -> None]  (* raw unreduced A21 loop form *)
BuildAntenna[A, 2, 2, Contribution -> OneLoopSelf]
  (* bounded A22 source route: {$Failed, $Failed, $Failed, breveA22} *)
```

Integrated antennae:

```wl
BuildAndIntegrateAntenna[A, 2, 1]  (* integrated A21, PaVe/Package-X route *)
BuildAndIntegrateAntenna[A, 3, 0]  (* integrated A30, X30 IBP route *)
BuildAndIntegrateAntenna[A, 4, 0, Component -> Leading, ExpansionOrder -> 0]
  (* integrated A40 via the X40 IBP route *)
BuildAndIntegrateAntenna[A, 4, 0, Component -> Subleading, ExpansionOrder -> 0]
  (* integrated tildeA40 via the X40 IBP route *)
BuildAndIntegrateAntenna[B, 4, 0, ExpansionOrder -> 0]
  (* integrated B40 via the X40 IBP route *)
BuildAndIntegrateAntenna[C, 4, 0, ExpansionOrder -> 0]
  (* integrated C40 via the X40 IBP route *)
BuildAndIntegrateAntenna[A, 3, 1, ExpansionOrder -> 0]
  (* {integrated A31, integrated tildeA31, integrated hatA31} *)
BuildAndIntegrateAntenna[A, 2, 2, ExpansionOrder -> 0]
  (* {integrated A22, integrated tildeA22, integrated hatA22, integrated breveA22} *)
```

High-level `R`-ratio driver:

```wl
BuildRRatio[SMQCD, quarkMass -> 0]
BuildRRatio[SMQCD, quarkMass -> 0, ReturnDiagnostics -> True]
BuildRRatio[SUSY, quarkMass -> 0]      (* placeholder shell: not implemented *)
BuildRRatio[HiggsEFT, quarkMass -> 0]  (* placeholder shell: not implemented *)
```

Generated-result cache examples:

```wl
BuildAndIntegrateAntenna[A, 4, 0, Component -> Leading, ExpansionOrder -> 0,
  StoreResults -> True]

BuildAndIntegrateAntenna[A, 4, 0, Component -> Leading, ExpansionOrder -> 0,
  UseStoredResults -> True]

BuildRRatio[SMQCD, quarkMass -> 0, StoreResults -> True]
BuildRRatio[SMQCD, quarkMass -> 0, UseStoredResults -> True]
BuildRRatio[SMQCD, quarkMass -> 0, RefreshStoredResults -> True,
  StoreResults -> True]

ListStoredResults[]
ListStoredResults[RouteKind -> "BuildRRatio"]
StoredResultInfo[BuildAndIntegrateAntenna, A, 4, 0,
  Component -> Subleading, ExpansionOrder -> 0]
StoredResultInfo[BuildRRatio, SMQCD, quarkMass -> 0]
```

Object-first integration:

```wl
obj = BuildAntennaObject[A, 3, 1];
IntegrateAntenna[obj, ExpansionOrder -> 0]
obj2 = BuildAntenna[A, 3, 1, IntegrableForm -> True];
IntegrateAntenna[obj2, ExpansionOrder -> 0]
```

Inspectable run records:

```wl
buildRecord = BuildAntenna[A, 3, 1, ReturnRecord -> True];
buildRecord["Result"]
buildRecord["IntermediateSteps"]
buildRecord["AntennaObject"]

obj = BuildAntennaObject[A, 3, 1];
integrationRecord = IntegrateAntenna[obj, ExpansionOrder -> 0,
  ReturnRecord -> True];
integrationRecord["Result"]
integrationRecord["MasterCombination"]
integrationRecord["MasterSubstitutedExpression"]
integrationRecord["BackendDiagnostics"]

fullRecord = BuildAndIntegrateAntenna[A, 2, 1, ReturnRecord -> True];
fullRecord["Result"]
fullRecord["Diagnostics"]
fullRecord["SourceObject"]
```

Default behavior is unchanged when `ReturnRecord` is omitted or `False`.  In
record mode, `ReturnDiagnostics` becomes unnecessary because the record always
contains the diagnostics association.

Multi-component antennae can be indexed directly:

```wl
BuildAntenna[A, 4, 0, Component -> Leading]
BuildAntenna[A, 4, 0, Component -> Subleading]
BuildAntenna[A, 3, 1, Component -> Nf]
BuildAntenna[A, 2, 2, Component -> Breve]
```

The default `Component -> All` preserves the historical list output.  For
three-component A-type objects the list order is:

```wl
{Leading, Subleading, Nf}
```

For A22 the list order is:

```wl
{Leading, Subleading, Nf, Breve}
```

A22 has two physically distinct source contributions.  The public integrated
route keeps the historical four-slot output

```wl
{A22, tildeA22, hatA22, breveA22}
```

but internally stitches it from two different T objects:

```wl
{A22, tildeA22, hatA22}  <- Contribution -> TwoLoopTree
{breveA22}               <- Contribution -> OneLoopSelf
```

Those contributions can still be requested separately:

```wl
BuildAntenna[A, 2, 2, Contribution -> OneLoopSelf]
BuildAntenna[A, 2, 2, Contribution -> OneLoopSelf, Component -> Breve]
BuildAntenna[A, 2, 2, Contribution -> TwoLoopTree]
BuildAntenna[A, 2, 2, Contribution -> TwoLoopTree, Component -> Leading]
```

`Contribution -> OneLoopSelf` builds only the one-loop self-interference
source of `breveA22`; it does not generate the two-loop amplitude.  The
default `Contribution -> All` now means "build or integrate the public
four-component A22 object by combining the bounded `TwoLoopTree` and
`OneLoopSelf` routes", rather than trying to force the mixed object through a
single basis family.  The same contribution split is accepted by
`IntegrateAntenna`:

```wl
BuildAndIntegrateAntenna[A, 2, 2, Contribution -> OneLoopSelf,
  Component -> Breve]
BuildAndIntegrateAntenna[A, 2, 2, Contribution -> TwoLoopTree,
  Component -> Leading, ReturnDiagnostics -> True]
```

At present the bounded `Contribution -> OneLoopSelf` call reaches the
experimental `A22OneLoopSelf` IBP profile, loads the generated LiteRed basis,
and reduces the source to a factorised two-bubble master.  The backend then
substitutes the `A22,LO` master from appendix A.1 of hep-ph/0403057 in the
matching paper convention.  The `A22TwoLoopTree` route loads eight generated
bases and is suitable for bounded component diagnostics.  The leading
component now matches the 0403057 two-loop/tree T bracket through the real
IBP route.  The public `BuildAndIntegrateAntenna[A, 2, 2]` route is now wired to
assemble the four-component A22 object by combining the three two-loop/tree
colour-bracket calls with the separate one-loop/self `breveA22` component,
but the expensive `Subleading` and full default-list validations should still
be treated as active work rather than finished lightweight checks.

Generate the A22 one-loop self basis from a clean LiteRed kernel with:

```sh
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script antenna_pipeline/dev/generate_a22_one_loop_self_basis.wl
```

Generate the A22 tree/two-loop basis family with:

```sh
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script antenna_pipeline/dev/generate_a22_two_loop_tree_bases.wl
```

The generator intentionally does not load `AntennaPipeline.wl`, FeynCalc, or
FeynArts.  LiteRed basis generation is context-sensitive, so generation is
kept in this clean script and the package only loads the saved basis.

Run the public-route benchmark harness with:

```sh
/Applications/Wolfram.app/Contents/MacOS/WolframKernel -script antenna_pipeline/dev/run_public_route_benchmarks.wl
```

Optional environment variables:

```text
ANTENNA_BENCHMARK_TIMEOUT      per-call timeout in seconds (default: 300)
ANTENNA_BENCHMARK_LABELS       comma-separated subset of route labels
ANTENNA_BENCHMARK_OUTPUT       optional JSON output path
```

The current baseline route set is:

```text
A20
A30
A40 Leading
A40 Subleading
B40
C40
A21
A31 Leading
A22 Leading
A22 full stitched
```

An additional optional cache-hit benchmark label is also available once a
stored result exists:

```text
RRatio SMQCD cached
```

For each baseline route the script records four public entrypoints:

```text
BuildAntenna
BuildAntennaObject
IntegrateAntenna
BuildAndIntegrateAntenna
```

### Runtime Expectations

The following timings are the current public-route expectations measured from
fresh kernels on a MacBook Pro M4 during the benchmark and follow-up
performance-investigation passes on June 4-5, 2026.
They should be treated as approximate user-facing expectations rather than
hard guarantees.

```text
Route / entrypoint snapshot                Expected runtime
----------------------------------------------------------
A20 build-only                            under 0.1 s
A30 one-shot                              about 0.15 s
A21 build-only                            about 0.5 s
A21 object integration                    about 0.36 s
A22 Leading one-shot                      about 223 s
A22 full stitched one-shot                about 589 s
A31 Leading object integration            about 197 s
A40 Leading object integration            about 194 s
A40 Subleading object integration         about 582 s
B40 object integration                    about 16 s
C40 object integration                    about 308 s
RRatio SMQCD driver (fresh)               about 3061 s
RRatio SMQCD driver (cached load)         about 1.14 s
```

The current practical picture is:

```text
- `BuildAntennaObject[...]` is usually much cheaper than the heavy integration leg.
- For the hard loop/X40 routes, most runtime is spent inside `IntegrateAntenna[...]`.
- For the heavy `X40` routes, the dominant cost was found to be
  `MatchIBPBasis`, not basis loading and not final simplification.
- A single shared `X40` basis reorder now gives a substantial speedup across
  the family, especially for `A40 Leading`, `tildeA40`, and `B40`.
- `BuildAndIntegrateAntenna[...]` is usually only modestly slower than the
  split object-first route, but the object-first route remains the cleanest way
  to inspect heavy-route timing diagnostics.
- `A31 Leading` is now another confirmed matching-dominated heavy route with a
  family-level basis reorder in place; on the benchmark MacBook Pro M4 that
  reduces the object-first route to about 197 s.
```

### Stored Result Cache

Heavy public outputs can now be stored under the repo-local
`stored_results/` tree:

```text
stored_results/build/
stored_results/build_objects/
stored_results/integrated/
stored_results/build_and_integrate/
stored_results/rratio/
```

These files are versioned generated artifacts, not hard-coded replacements for
the implementation.  Fresh computation is still the default package behavior;
the cache is there to make repeated heavy use practical when you opt in.

The committed stored artifacts currently correspond to the massless public
benchmark set on the benchmark MacBook Pro M4:

```text
- `A21`
- `A30`
- `A31`
- `A22 Leading`
- `A22 full stitched`
- `A40 Leading`
- `A40 Subleading`
- `B40`
- `C40`
- `BuildRRatio[SMQCD, quarkMass -> 0]`
```

Typical stored-result workflow:

```wl
(* fresh compute, no cache involvement *)
BuildRRatio[SMQCD, quarkMass -> 0]

(* compute and store the top-level result *)
BuildRRatio[SMQCD, quarkMass -> 0, StoreResults -> True]

(* reuse the stored top-level result *)
BuildRRatio[SMQCD, quarkMass -> 0, UseStoredResults -> True]

(* refresh the top-level artifact while reusing nested stored ingredients *)
BuildRRatio[SMQCD, quarkMass -> 0,
  RefreshStoredResults -> True,
  StoreResults -> True]
```

In the current benchmark set, the fresh massless `SMQCD` `R`-ratio build takes
about `3061 s`, while a top-level cache hit returns in about `1.14 s`.

Display-only options such as `IntermediateSteps` and
`PrintIntermediateSteps` are not part of the cache key.  When a stored result
is loaded, the package reuses the saved result/diagnostics payload and applies
requested intermediate-step display on top of that cached payload when
possible.

The cache semantics are:

```text
- `UseStoredResults -> True` tries to load a matching stored artifact first
- `StoreResults -> True` writes a successful fresh result to disk
- `RefreshStoredResults -> True` recomputes the top-level request and overwrites
  its stored artifact on success
- for `BuildRRatio[...]`, a top-level refresh now reuses matching nested stored
  antenna ingredients instead of refreshing every heavy ingredient underneath
```

The new read-only helpers make the stored set easy to inspect:

```wl
ListStoredResults[]
ListStoredResults[RouteKind -> "BuildRRatio"]
StoredResultInfo[BuildRRatio, SMQCD, quarkMass -> 0]
StoredResultInfo[BuildAndIntegrateAntenna, A, 4, 0,
  Component -> Subleading, ExpansionOrder -> 0]
```

`ListStoredResults[]` returns compact metadata for the stored entries, while
`StoredResultInfo[...]` resolves one exact cache entry and reports its schema
version, request key, path, whether diagnostics are stored, and whether the
payload currently passes the cache validator.

### Intermediate-Step Capture

The first public inspection pass is now available through:

```wl
IntermediateSteps -> {...}
PrintIntermediateSteps -> True
DetailedTimingDiagnostics -> True
```

This is non-default and leaves the normal black-box return shape unchanged
unless explicitly requested.  In the current first pass:

```text
- `BuildAntenna[...]` and `BuildAntennaObject[...]` can return structured
  build-side stages such as `BuildData`, `FullBuildResult`,
  `SelectedBuildResult`, `AntennaObject`, and `BuildDiagnostics`.
- `IntegrateAntenna[...]` and `BuildAndIntegrateAntenna[...]` can return
  structured integration-side stages such as `InputAntenna`,
  `RawIntegrated`, `TTerms`, `FinalIntegrated`, `SelectedIntegrated`,
  `BackendDiagnostics`, and `IntegrationDiagnostics`.
- When `ReturnDiagnostics -> True`, the requested stages are attached under
  `\"IntermediateSteps\"` inside the diagnostics association.
- When `ReturnDiagnostics -> False`, the call returns `{result,
  intermediateStepsAssociation}` when intermediate capture is requested.
- If `PrintIntermediateSteps -> True` is also set, the requested stages are
  printed with simple stage headers during evaluation.
- IBP-backed integrations now also attach a `"TimingDiagnostics"` association
  inside `"BackendDiagnostics"` with stage-level timings for basis loading,
  reduction, and the final series/simplification pipeline.
- If `DetailedTimingDiagnostics -> True` is requested on an IBP-backed route,
  `"BackendDiagnostics"` also includes per-term `"TermRecords"` with
  match/reduce timings and simple leaf-count size indicators for investigation
  work.
- The current A21 smoke tests validate the first-pass user experience:
  the PaVe-default build now matches the PaVe paper target in diagnostics, and
  the integration-side `BackendDiagnostics` stage returns a clean empty
  association when the selected backend has no extra payload to expose.
```

For example:

```wl
BuildAndIntegrateAntenna[A, 3, 1,
  Component -> Leading,
  ExpansionOrder -> 0,
  ReturnDiagnostics -> True,
  PrintIntermediateSteps -> True,
  IntermediateSteps -> {"RawIntegrated", "TTerms", "BackendDiagnostics"}
]
```

For the earlier A40 case, for example:

```wl
BuildAntenna[A, 4, 0]
```

returns:

```wl
{A40, tildeA40}
```

For A31 integration, the final antennae are returned by default, while the
intermediate `Tqqg6` colour brackets are available explicitly:

```wl
BuildAndIntegrateAntenna[A, 3, 1, ExpansionOrder -> 0]
BuildAndIntegrateAntenna[A, 3, 1, ReturnTTerms -> True, ExpansionOrder -> 0]
```

The A31 integrated route has two deliberately separate layers:

```text
IBP-reduced raw components -> Tqqg6 colour brackets -> final integrated antennae
```

The implemented relations are:

```wl
TLeading = RawLeading - 11/(6 Epsilon) IntegratedA30
TSubleading = RawSubleading
TNf = RawHat - (-2/(6 Epsilon)) IntegratedA30

A31 = TLeading - IntegratedA21 IntegratedA30
tildeA31 = -(TSubleading + IntegratedA21 IntegratedA30)
hatA31 = TNf
```

Component selection also works after integration:

```wl
BuildAndIntegrateAntenna[A, 3, 1, Component -> Leading, ExpansionOrder -> 0]
BuildAndIntegrateAntenna[A, 3, 1, Component -> Subleading, ExpansionOrder -> 0]
BuildAndIntegrateAntenna[A, 3, 1, Component -> Nf, ExpansionOrder -> 0]
```

Diagnostics for A31 integration report both levels:

```wl
{result, diag} =
  BuildAndIntegrateAntenna[A, 3, 1, ReturnDiagnostics -> True,
    ExpansionOrder -> 0];

diag["TTermResiduals"]
diag["IntegratedAntennaResiduals"]
```

### Common Workflows

Build a tree-level antenna:

```wl
a30 = BuildAntenna[A, 3, 0];
```

Build a public antenna object for later integration:

```wl
a31Obj = BuildAntennaObject[A, 3, 1];
```

Build one component of a multi-component antenna:

```wl
a40Lead = BuildAntenna[A, 4, 0, Component -> Leading];
a40Sub = BuildAntenna[A, 4, 0, Component -> Subleading];
```

Build the unintegrated A31 antenna components:

```wl
{a31, tildeA31, hatA31} = BuildAntenna[A, 3, 1];
```

Integrate A21 through the PaVe/Package-X route:

```wl
intA21 = BuildAndIntegrateAntenna[A, 2, 1];
```

Integrate A30 through the X30 IBP route:

```wl
intA30 = BuildAndIntegrateAntenna[A, 3, 0];
```

Integrate a previously built object:

```wl
intA31FromObject = IntegrateAntenna[a31Obj, ExpansionOrder -> 0];
```

Build an integrable object without changing the readable default output:

```wl
a22Obj = BuildAntenna[A, 2, 2, IntegrableForm -> True];
intA22FromObject = IntegrateAntenna[a22Obj, ExpansionOrder -> 0];
```

Inspect the intermediate A31 `Tqqg6` colour brackets:

```wl
tTermsA31 =
  BuildAndIntegrateAntenna[A, 3, 1, ReturnTTerms -> True,
    ExpansionOrder -> 0];
```

Return the final integrated A31 antennae:

```wl
intA31Components =
  BuildAndIntegrateAntenna[A, 3, 1, ExpansionOrder -> 0];
```

Return only one final integrated A31 component:

```wl
intTildeA31 =
  BuildAndIntegrateAntenna[A, 3, 1, Component -> Subleading,
    ExpansionOrder -> 0];
```

Assemble the massless `SMQCD` NNLO `R`-ratio expression:

```wl
rRatioSMQCD = BuildRRatio[SMQCD, quarkMass -> 0];
```

Store and later reuse the same heavy `R`-ratio driver result:

```wl
BuildRRatio[SMQCD, quarkMass -> 0, StoreResults -> True];
BuildRRatio[SMQCD, quarkMass -> 0, UseStoredResults -> True];
```

Inspect the assembled ingredient bundle and the raw combination used by the
driver:

```wl
{rRatioSMQCD, rRatioDiag} =
  BuildRRatio[SMQCD, quarkMass -> 0, ReturnDiagnostics -> True,
    IntermediateSteps -> {"Ingredients", "AssemblyExpression"}];
```

Run tree-level regression checks:

```wl
RunAntennaDiagnostics[]
```

Diagnostics are explicit:

```wl
RunAntennaDiagnostics[]
RunAntennaDiagnostics[LoopOrder -> 1]
```

Diagnostic build data are available without changing the ordinary symbolic
workflow:

```wl
BuildAntenna[B, 4, 0, ReturnDiagnostics -> True]
BuildAntenna[A, 3, 1, ReturnDiagnostics -> True]
BuildAndIntegrateAntenna[A, 2, 1, ReturnDiagnostics -> True]
```

Minimal antenna-object helpers are available for the staged workflow:

```wl
AntennaObjectQ[a31Obj]
AntennaKey[a31Obj]
AntennaComponent[a31Obj]
AntennaContribution[a31Obj]
AntennaExpression[a31Obj]
AntennaFullExpression[a31Obj]
```

## Testing Against The Paper

For unintegrated antennae with encoded paper targets:

```wl
{a20, d20} = BuildAntenna[A, 2, 0, ReturnDiagnostics -> True];
{a30, d30} = BuildAntenna[A, 3, 0, ReturnDiagnostics -> True];
{a40, d40} = BuildAntenna[A, 4, 0, ReturnDiagnostics -> True];
{b40, db40} = BuildAntenna[B, 4, 0, ReturnDiagnostics -> True];
{c40, dc40} = BuildAntenna[C, 4, 0, ReturnDiagnostics -> True];

d20["PaperDiagnostics"]["ExactMatchQ"]
d30["PaperDiagnostics"]["ExactMatchQ"]
d40["PaperDiagnostics"]["A40ExactMatchQ"]
d40["PaperDiagnostics"]["tA40ExactMatchQ"]
db40["PaperDiagnostics"]["ExactMatchQ"]
dc40["PaperDiagnostics"]["ExactMatchQ"]
```

For integrated routes already matched to the paper:

```wl
{a21Int, da21Int} =
  BuildAndIntegrateAntenna[A, 2, 1, ReturnDiagnostics -> True];

{a31Int, da31Int} =
  BuildAndIntegrateAntenna[A, 3, 1, ReturnDiagnostics -> True,
    ExpansionOrder -> 0];

{a22Int, da22Int} =
  BuildAndIntegrateAntenna[A, 2, 2, ReturnDiagnostics -> True,
    ExpansionOrder -> 0];

da21Int["IntegratedResidualIsZero"]
da31Int["IntegratedAntennaResiduals"]
da31Int["TTermResiduals"]
da22Int["IntegratedAntennaResiduals"]
da22Int["TTermResiduals"]
```

The expected values are:

```wl
True
{0, 0, 0}
{0, 0, 0}
{0, 0, 0, 0}
{0, 0, 0, 0}
```

## How The Files Communicate

`AntennaPipeline.wl` loads the files in `src/` in dependency order.  Files do
not pass values to one another directly.  They define functions and variables
in the active Wolfram session; those functions then pass amplitudes,
interferences, antennae, and integrated results at runtime.

The intended flow is:

```text
profiles -> amplitudes -> interferences -> extraction -> BuildAntenna
BuildAntenna -> IntegrateAntenna -> PaVe or IBP backend -> post-integration extraction
paper targets + diagnostics -> opt-in checks
```

## File Map

```text
src/setup.wl
  FeynCalc/FeynArts/FeynHelpers loading, constants, and shared substitutions.

src/kinematics_and_utilities.wl
  Kinematic rules, coupling stripping, color/spin utilities, and common
  FeynCalc replacement rules.

src/amplitudes_tree.wl
  Tree-level amplitude generation.

src/amplitudes_loop.wl
  One-loop amplitude generation and loop-amplitude cleanup.

src/interference_tree.wl
  Tree/tree interference machinery.

src/interference_loop.wl
  Tree/loop interference machinery and one-loop normalization.

src/profiles.wl
  Antenna profiles, reduction profiles, and integration profiles.

src/extraction_tree.wl
  Tree-level component extraction and four-quark sector selection.

src/extraction_loop.wl
  One-loop component extraction.

src/color_ordered_a40.wl
  Color-ordered A40 construction from the unsquared color-chain amplitude.

src/build_router.wl
  Internal build associations and the public BuildAntenna wrapper.

src/production_assignments.wl
  Optional notebook-style public variable assignment through
  AssignAntennaProductionVariables[].

src/integration_router.wl
  Public IntegrateAntenna dispatch.

src/integration_pave.wl
  PaVe backend and Package-X convention handling.

src/integration_ibp.wl
  LiteRed IBP backend; currently complete for X30/A30 and equipped with X40
  and X31 basis/master infrastructure.  It also contains the experimental
  `A22OneLoopSelf` profile that loads the generated two-loop self basis.

src/integrated_antenna_extraction.wl
  Post-integration conversion from T-object colour brackets to final
  integrated antenna components.

src/paper_targets.wl
  Paper/reference expressions.

src/diagnostics.wl
  Paper comparisons, residual helpers, momentum-label scans, and
  diagnostic runners.

dev/generate_a22_one_loop_self_basis.wl
  Standalone clean-kernel LiteRed generator for the experimental A22
  one-loop self-interference basis.

src/notebook_patches.wl
  Disabled-by-default, notebook-style explanatory patches.
```

## Verification

Tree diagnostics should print:

```text
A20
True
A30
True
A40
True
tA40
True
B40
True
C40
True
```

One-loop diagnostics should print:

```text
A21
True
A21 integrated
True
A31 reconstruction
True
hatA31 raw
True
A31 color-free
True
```

Direct compatibility checks:

```wl
AssignAntennaProductionVariables[];
A20 === BuildAntenna[A, 2, 0]
A30 === BuildAntenna[A, 3, 0]
{A40, tildeA40} === BuildAntenna[A, 4, 0]
B40 === BuildAntenna[B, 4, 0]
C40 === BuildAntenna[C, 4, 0]
```

## Known Limitations

- The package now runs the full current target A-type public-route set, so the
  remaining issues are about runtime and user ergonomics rather than missing
  A-type coverage.
- Final two-loop A22 public integration is now routed through the combined
  contribution layer rather than a single mixed basis family.  The default
  four-component public object is assembled from the `TwoLoopTree`
  `{Leading, Subleading, Nf}` T object together with the separate
  `OneLoopSelf` `Breve` T object.  The route is implemented, but the
  underlying two-loop/tree reductions remain expensive and should still be run
  deliberately.
- Expensive IBP reductions should be launched deliberately from a Wolfram
  session, preferably component by component with diagnostics or checkpoints.
  In particular, avoid treating full A31/X40 reductions as lightweight
  notebook evaluations.
- Full X40 antenna integrations are implemented and validated, but some of
  them are operationally very heavy.  In particular, the current
  `A40 Subleading` object-first public integration takes about 10 minutes on a
  MacBook Pro M4 after the shared X40 basis reorder, and should still be
  launched deliberately.
- Full A31 component integrations are computationally heavy.  The X31 direct
  reduction and master mapping infrastructure is present, but long reductions
  should be run deliberately in a Mathematica session with diagnostics.
- A22 source production is experimental and potentially expensive.  Component
  routing, two-loop/tree and one-loop/self production hooks, and 0403057
  T-term targets exist.  The bounded `Contribution -> OneLoopSelf` route
  builds the color-free `breveA22` source slot without generating two-loop
  diagrams.  The IBP router resolves that source to the `A22OneLoopSelf`
  profile, reduces it to a single factorised two-bubble master, and reproduces
  the 0403057 one-loop self-interference T bracket.  The bounded
  `Contribution -> TwoLoopTree` route loads the generated `A22TwoLoopTree`
  basis family and reduces the tree-side components with zero unmatched terms.
  The `Leading` route is matched through topology-specific master
  substitution, and the public `BuildAndIntegrateAntenna[A, 2, 2]` call now combines
  the separately integrated `breveA22` route with the tree-side calls to
  return the historical four-slot A22 object.  Full default-list validation
  remains expensive and should still be run deliberately from a Wolfram
  session.
- Massive PaVe convention conversion is not implemented.
- The disabled `RunA21PaXAsIsPatch` block is for understanding the A21
  Package-X convention patch, not for production.
