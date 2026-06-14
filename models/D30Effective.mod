(* Repo-local classes model for the D30 effective source process. *)

M$ModelName = "D30Effective";

IndexRange[Index[Gluon]] = NoUnfold[Range[8]];

M$ClassesDescription = {
  F[1] == {
    SelfConjugate -> True,
    Indices -> {},
    Mass -> MNeu,
    PropagatorLabel -> "\\chi",
    PropagatorType -> Straight,
    PropagatorArrow -> None
  },

  F[2] == {
    SelfConjugate -> True,
    Indices -> {Index[Gluon]},
    Mass -> MGl,
    PropagatorLabel -> ComposedChar["g", Null, Null, "\\tilde"],
    PropagatorType -> Straight,
    PropagatorArrow -> None
  },

  V[1] == {
    SelfConjugate -> True,
    Indices -> {Index[Gluon]},
    Mass -> 0,
    QuantumNumbers -> {Sqrt[3] ColorCharge},
    PropagatorLabel -> "g",
    PropagatorType -> Cycles,
    PropagatorArrow -> None
  }
};

MNeu[_] = MNeu;
MGl[_] = MGl;

FAGaugeXi[V[1]] = FAGaugeXi[G];

M$CouplingMatrices = {
  C[V[1, {g1}], V[1, {g2}], V[1, {g3}]] ==
    FAGS * {{FASUNF[g1, g2, g3]}},

  C[F[2, {g1}], F[2, {g2}], V[1, {g3}]] ==
    -FAGS FASUNF[g1, g2, g3] *
      {{1}, {1}, {0}, {0}},

  C[F[1], F[2, {g1}], V[1, {g2}]] ==
    IndexDelta[g1, g2] *
      {{0}, {0}, {D30SourceL}, {D30SourceR}},

  C[F[1], F[2, {g1}], V[1, {g2}], V[1, {g3}]] ==
    I FAGS FASUNF[g1, g2, g3] *
      {{D30SourceL}, {D30SourceR}}
};
