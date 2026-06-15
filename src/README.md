`src/` is the canonical runtime source tree for the package. This directory is
organized as a pipeline, not just as a folder split. The code is arranged so
that each layer answers a different question:

- `core/`: What are the shared conventions, profiles, normalization rules,
  diagnostics, and cache policies?
- `engines/`: How do we actually generate amplitudes, form interferences,
  reduce loop objects, and extract antenna structures?
- `routes/`: Which sequence of engine calls corresponds to each physical
  antenna family?
- `interface/`: What should a user-facing call return, and how do we preserve
  enough metadata to inspect or reuse the result later?

The most important architectural decision in the package is that these layers
are intentionally separate. The low-level symbolic physics operations are not
mixed directly with public return formatting, caching, or route-specific
exceptions. That separation keeps two things manageable at once:

1. The physics logic stays readable in its own terms.
2. The public API can stay uniform even when different antenna families require
   very different internal workflows.

## The Four Main Public Functions

Most of the runtime is organized around four public functions in
`src/interface/`:

- `BuildAntenna[type, n, loopOrder, ...]`
- `BuildAntennaObject[type, n, loopOrder, ...]`
- `IntegrateAntenna[obj, ...]`
- `BuildAndIntegrateAntenna[type, n, loopOrder, ...]`

These four functions define the package’s user-facing story.

`BuildAntenna[...]` is the public constructor for unintegrated antenna
expressions. It is the right entry point when the user wants the symbolic
antenna itself, optionally with diagnostics, intermediate steps, or a run
record.

`BuildAntennaObject[...]` exists because integration needs more than a bare
expression. It packages the selected antenna together with the antenna key, the
full build result, the selected component, and contribution metadata. In other
words, it preserves the context that `IntegrateAntenna[...]` needs in order to
make backend and route decisions correctly.

`IntegrateAntenna[...]` consumes an `AntennaObject` and performs the integrated
route: backend selection, PaVe or IBP evaluation, T-term construction, final
integrated-antenna extraction, optional master-combination return, and
diagnostics assembly.

`BuildAndIntegrateAntenna[...]` is the one-shot route. It exists for usability:
many users care about the final integrated object and do not want to manually
thread a build object through a second call. Internally it still respects the
same layered design and simply composes `BuildAntennaObject[...]` with
`IntegrateAntenna[...]`.

## End-To-End Data Flow

The full runtime story from diagram input to integrated antenna output is:

1. A public interface call identifies an antenna family by key
   `{type, numFinalParticles, loopOrder}`.
2. `src/core/profiles.wl` resolves that key into profile metadata: source type,
   number of particles, reduction backend, component structure, benchmark
   availability, and implementation status.
3. A route function in `src/routes/` uses that profile to choose a workflow.
4. Engine functions in `src/engines/` perform the actual symbolic work:
   amplitude generation, interference construction, extraction, PaVe
   evaluation, IBP reduction, or integrated-antenna post-processing.
5. The route layer repackages those engine outputs into a stable association
   with fields such as `"Profile"`, `"Interferences"`, `"Components"`,
   `"Diagnostics"`, and, when relevant, `"NormalizedInterference"`.
6. The interface layer converts that route association into a public result:
   plain expression, selected component, `AntennaObject`, or
   `AntennaRunRecord`.
7. For integration, the interface sends the `AntennaObject` back through the
   integration routes, which pick the backend, integrate the selected antenna,
   extract T-terms and the final integrated antenna, and then format the final
   public result.

That means the public pipeline is not “interface calls engines directly.”
Instead it is:

`interface -> routes -> engines -> routes -> interface`

This is deliberate. The route layer is where antenna-family-specific physics
choices belong. The interface layer should not need to know how A40 color
ordering differs from A31 IBP reduction, and the engine layer should not need
to know anything about cache labels or run records.

## How Build-Side Data Moves

The build pipeline begins in `src/interface/build_router.wl`.

`BuildAntenna[...]` normalizes options, checks stored-result policy, and then
delegates route construction to `BuildAntennaData[...]`. That function is a
thin public bridge into `src/routes/build_workflows.wl`, especially
`BuildRouteBuildData[...]` and `BuildTreeRouteData[...]`.

At the route layer, the key decision is the production mode encoded in the
profile:

- self-interference routes build one amplitude and interfere it with itself
- sector-split routes first decompose the amplitude into physical sectors
- color-ordered routes derive ordered antenna objects from a full-color parent
- loop routes build tree/loop or two-loop/one-loop combinations and then pass
  them through loop-specific extraction logic

The engine layer is where the real symbolic physics happens:

- `src/engines/amplitudes_tree.wl` and `src/engines/amplitudes_loop.wl`
  generate amplitudes
- `src/engines/interference_tree.wl` and
  `src/engines/interference_loop.wl` form the relevant squared or mixed
  interferences
- `src/engines/extraction_tree.wl` and `src/engines/extraction_loop.wl`
  divide by the appropriate born normalization and split the answer into the
  package’s public component structure
- `src/engines/color_ordered_a40.wl` handles the special A40 color-ordering
  story

Once a route has built its association, `BuildAntennaResult[...]` in
`src/interface/build_router.wl` translates the route-owned `"Components"`
association into the package’s canonical public shape. This step exists so
route-specific internal names do not leak into the external API.

`BuildAntennaObject[...]` then wraps that built result with the build metadata
needed later by integration. This is why `AntennaObject` stores both
`"Antenna"` and `"FullAntenna"`: the first is the currently selected view, and
the second preserves the full result for later component re-selection and
inspection.

## How Integration Data Moves

The integration pipeline begins in `src/interface/integration_router.wl`.

`IntegrateAntenna[...]` receives an `AntennaObject`, resolves the integration
profile, and then delegates the actual route orchestration to
`src/routes/integration_workflows.wl`. The integration layer has to solve a
different problem from the build layer: it is not enough to generate an
expression, because the package must also choose a backend and decide how much
post-processing is needed before the result matches an integrated antenna
convention.

There are two main backend paths:

- `src/engines/integration_pave.wl` for PaVe-based one-loop-style integration
- `src/engines/integration_ibp.wl` for basis-driven IBP reduction and master
  substitution

Those backend outputs are not yet the final public answer. The next step is
`src/engines/integrated_antenna_extraction.wl`, which constructs the T-term
representation and then extracts the final integrated antenna object in the
package’s conventions.

This separation is important physically. The backend computes an integrated
representation of the symbolic object, but the package still needs to identify
the integrated antenna itself, often component by component and order by order
in epsilon. That is why the public integration route stores:

- the raw integrated object
- the T-terms
- the final integrated antenna
- the selected component
- backend diagnostics

all separately.

## Why `BuildAntennaObject` Exists

It can look redundant at first glance, because `BuildAntenna[...]` already
returns the symbolic antenna. But integration needs more than the expression:

- the antenna key to resolve the integration profile
- the selected component and contribution
- the full build-side result for later re-selection or stitching
- route provenance for diagnostics and run-record replay

If `IntegrateAntenna[...]` accepted only a bare expression, it would have to
guess the family, component structure, normalization story, and backend route.
That would be fragile both physically and in software terms. `AntennaObject`
exists to avoid that ambiguity.

## Special Routes and Why They Are Isolated

Several files exist because one family does not cleanly fit the generic path.

### Massive A30

The massive A30 route is split across:

- `src/routes/massive_a30_unintegrated.wl`
- `src/routes/massive_a30_reconstruction.wl`
- `src/routes/massive_a30_integrated.wl`

The unintegrated massive route cannot simply reuse the massless tree path,
because the heavy-quark kinematics and normalization bridge must be kept
explicit. The integrated massive route is even more special: today it is a
provenance-rich bridge between an encoded literature expression and the
package’s runtime basis. That is why it lives outside the generic PaVe/IBP
pipeline and records the bridge logic openly rather than hiding it.

### A22

The two-loop A22 route is stitched from physically different sources:

- tree/two-loop interference for the leading, subleading, and `Nf` pieces
- one-loop/self interference for the breve piece

This is why both `src/interface/build_router.wl` and
`src/interface/integration_router.wl` contain explicit A22 combination logic.
The package does not pretend that A22 is produced by one uniform route when it
is actually a composite object.

### A40, B40, and C40

The four-parton tree families require additional handling beyond a simple
self-interference:

- A40 has a full-color object and a color-ordered subleading structure
- B40 and C40 are tied to color-ordering and sector-specific route choices

Those route-specific choices live in `src/routes/build_workflows.wl` and
`src/engines/color_ordered_a40.wl`, while the public interface presents the
results through the same `BuildAntenna[...]` contract.

## What Lives in `core/`

The `core/` directory contains the package-wide assumptions that every higher
layer depends on.

- `setup.wl` and `notebook_patches.wl` establish the runtime environment.
- `kinematics_and_utilities.wl` defines the invariant and simplification tools
  used everywhere else.
- `profiles.wl` defines the antenna and integration profiles, which are the
  package’s routing table in physics form.
- `production_assignments.wl` and `d30_effective_model.wl` provide specialized
  source-model support.
- `diagnostics.wl` centralizes benchmark and paper-check logic.
- `result_cache.wl` defines stored-result keys, labels, replay, and persistence
  policy.

The reason this material is centralized is consistency. If normalization,
profiles, or cache rules were redefined locally in each route, the package
would become impossible to reason about after enough special cases accumulated.

## What Lives in `routes/`

The `routes/` directory is the package’s workflow layer.

- `build_workflows.wl` owns the tree-level build stories and the route-level
  selection between ordinary and special branches.
- `integration_workflows.wl` owns integration orchestration, backend routing,
  and build-and-integrate composition.
- `route_catalog.wl` stores human-readable route stories that are attached to
  diagnostics and records.
- the massive A30 and D30 files isolate special provenance-heavy stories that
  do not belong inside the generic workflows.

This layer exists because the same engines can be reused in different physical
stories. A route file explains which story applies for which antenna family.

## What Lives in `interface/`

The `interface/` directory is the public shell around everything else.

- `build_router.wl` exposes build-time public functions and object wrappers
- `integration_router.wl` exposes integration-time public functions
- `paper_targets.wl` stores benchmark formulas used by diagnostics
- `rratio_driver.wl` shows how integrated antenna results are assembled into a
  higher-level observable

The interface layer is where return-shape design decisions live. That includes:

- whether the user gets a scalar, a component list, an object, or a record
- how intermediate steps are requested and printed
- how cache replay is exposed
- how diagnostics are attached without forcing every call to return them

## Why the Cache Lives Above the Engines

Stored results are keyed and replayed at the interface level rather than inside
individual engines. This is intentional.

Caching at too low a level would be difficult to interpret physically, because
the same low-level engine object can appear in different route contexts with
different normalization or selection semantics. By caching build and integration
results at the public-route level, the package stores objects that already have
clear physical meaning and stable user-facing provenance.

## How to Read the Codebase Later

If you return to this project after a long gap, the most reliable reading order
is:

1. `src/README.md`
2. `src/core/profiles.wl`
3. `src/interface/build_router.wl`
4. `src/routes/build_workflows.wl`
5. the relevant engine file for the build stage
6. `src/interface/integration_router.wl`
7. `src/routes/integration_workflows.wl`
8. the relevant backend engine file

That order mirrors the package architecture. Start with the routing metadata and
public contracts, then drop into the engine details only after you know which
physical workflow you are actually reading.

## Loader Policy

`AntennaPipeline.wl` is the canonical package loader.

`AntennaPipeline_new.wl` remains only as a temporary compatibility alias.

Runtime-owned massive `A30` code lives in `src/`, not in `dev/`.

`dev/` remains provenance, experimentation, and validation space rather than
part of the supported runtime pipeline.
