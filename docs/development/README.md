# AntCalc developer documentation

[Documentation home](../README.md) · [Manual](../manual/index.md) · [Reference guide](../reference/README.md)

These pages describe how to modify AntCalc without weakening its public physics
contract. They are for route maintainers and thesis/research readers, not a
substitute for the user manual.

- [Architecture](architecture.md)
- [Maintaining and adding routes](route-maintenance.md)
- [Runtime masters and literature provenance](runtime-masters-and-provenance.md)
- [Research-status ledger](research-status.md)

The governing rule is simple: an experimental route may expose honest records
and diagnostics, but it must not be promoted through a stored result, an
encoded target, or undocumented interface behaviour.
