`src/` is the canonical runtime source tree for the package.

Its ownership split is:

- `core/`: setup, kinematics, profiles, cache, shared package helpers
- `engines/`: direct FeynArts/FeynCalc/LiteRed/Package-X operations
- `routes/`: readable antenna workflows and route story metadata
- `interface/`: public API, records/objects, diagnostics, caching, return formatting

Current layout policy:

- `AntennaPipeline.wl` is the canonical package loader
- `AntennaPipeline_new.wl` remains only as a temporary compatibility alias
- runtime-owned massive `A30` code lives here, not in `dev/`
- `dev/` remains provenance and validation only

The current architecture keeps the validated low-level algorithms intact while
separating engine work, route workflows, and public interface plumbing more
cleanly than the old flat layout.
