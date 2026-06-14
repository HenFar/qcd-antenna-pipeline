## Integrated bridge note

This check is the current acceptance gate for the integrated massive `A30`
provenance layer.

### What it checks

1. load the encoded paper target from `dev/massiveA30_sources/integrated.wl`;
2. apply the explicit paper-to-package bridge;
3. load the actual current package master combination from
   `BuildAndIntegrateAntenna[A,3,0,quarkMass->mQ,ReturnRecord->True]`;
4. identify the undotted runtime master with the bridged paper
   `I1^(m,0,m)` master;
5. solve the dotted runtime master against the bridged integrated target;
6. verify that the substituted runtime combination reproduces the bridged
   target exactly.

### What failed before

- the older `MX30I1` and `MX30I2` trial files only enforced the massless
  limit and a derivative-style dotted-master guess;
- that was not enough to reproduce the actual integrated massive
  literature target;
- the paper second master is a numerator master, while the package second
  master is a dotted LiteRed basis master, so a direct identification was
  incorrect.

### What changed

- the exact paper target is now encoded explicitly;
- the target-level normalization bridge is explicit and separate;
- the runtime second master is now marked honestly as a provisional
  bridge-derived object rather than a proven literature master.
