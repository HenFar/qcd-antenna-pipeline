# Maintaining and adding routes

[Developer index](README.md) · [Architecture](architecture.md) · [Documentation home](../README.md)

## Extension sequence

For a new or repaired route, follow this order:

1. define the route key;
2. add or amend `AntennaProfile[key]`;
3. add or amend `AntennaIntegrationProfile[key]` when integration is needed;
4. teach the build workflow the chosen production/extraction semantics;
5. add a route-specific module only when the branch is genuinely exceptional;
6. expose structured diagnostics and a route story;
7. add fresh-kernel and contaminated-sequence regressions;
8. only then extend the supported-route claim and release verification.

Do not encode family behaviour directly into public interfaces merely because
it is convenient for one route. The profile and workflow layers must remain the
source of the route definition.

## Public, prototype, and experimental paths

The public output is the package-facing convention. Prototype paths are for
provenance and semantic repair; they are not a second public result. In
particular, `BuildOutputBranch -> "Prototype"` is direct-expression inspection
only and must not leak into integration-ready objects without a separately
defined contract.

Experimental routes may expose partial data or `$Failed`, but their diagnostics
must say whether the route is unfinished, bridge-based, or source-model-only.
Do not call a route complete because a stored result or encoded literature
expression matches a target.

## State and caches

All supported routes must be call-order independent. Test a fresh kernel and a
kernel deliberately exercised by relevant prior routes. State isolation must
identify and localise the real mutable source—kinematics, LiteRed basis state,
cache state, or a named global—not clear arbitrary global state blindly.

Stored results replay public outputs. Their identity needs route-semantic and
convention-critical inputs. After a semantics repair, stale entries must not
silently reuse old meaning.

## Convention repairs

Keep these layers distinct in records and documentation:

- raw amplitude/interference;
- colour coefficient;
- public antenna definition;
- phase-space/integration normalisation;
- runtime master basis;
- literature mapping.

For A40, the minus associated with the full-colour subleading coefficient is
external to the public `tilde A4^0` definition. For massive A30, the
paper/runtime second-master bridge remains research work until derived from a
representative reduction rather than inferred backwards from a final result.

## Regression expectations

Every repair should include a route-focused regression that states its evidence
method: exact symbolic equality where feasible; fixed physical points and pole
checks for large expressions; open-master identity and diagnostics for an
unresolved master basis. Heavy-route timeouts are performance evidence, not
physics agreement, unless a fresh equivalent completes within the same limit.
