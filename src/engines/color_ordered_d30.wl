(* ::Section:: *)
(* Ordered color-stripped D30 construction *)

(* Communicates with:
   - src/core/d30_effective_model.wl through the effective-source amplitudes
     and bridge helpers used to convert the neutralino-decay source into the
     package D30 convention.
   - src/engines/color_ordered_a40.wl through the generic color-ordered helper
     utilities reused here, such as ExpandUnsquaredColor and
     ColorStrippedInterference.
   - src/interface/paper_targets.wl for the ordered and symmetrized D30
     literature benchmarks.

   Why this file exists:
   The D30 literature object is defined at the level of ordered
   color-stripped neutralino-decay partial amplitudes, not from the fully
   color-reduced source self-interference.  This module extracts that ordered
   kinematic partial from the repo-local effective model, builds the exchanged
   ordering explicitly, and compares both to the encoded 0505111 targets. *)

D30OrderedColorTensorFreeQ::usage =
  "D30OrderedColorTensorFreeQ[expr] returns True when a proposed D30 ordered partial is free of explicit color tensors.";

ExtractD30OrderedPartial::usage =
  "ExtractD30OrderedPartial[amp3] extracts the single color-stripped ordered D30 partial from the unsquared neutralino-decay source amplitude.";

D30OrderedPartialSectorAssociation::usage =
  "D30OrderedPartialSectorAssociation[] returns the D30 ordered-partial sector split used to build the literature-shaped neutralino-decay partial.";

D30OrderedPartialCandidateAssociation::usage =
  "D30OrderedPartialCandidateAssociation[coeffTerms, fullCoeff] returns the current family of ordered-partial candidates scanned by the D30 ordered route.";

D30OrderedTermOrbitAssociation::usage =
  "D30OrderedTermOrbitAssociation[coeffTerms] reports the nearest raw k2 <-> k3 swap partner of each unsquared D30 coefficient term, including whether the best match is direct or sign-flipped.";

D30OrderedTermSignature::usage =
  "D30OrderedTermSignature[term] returns a lightweight topology signature for one unsquared D30 coefficient term, exposing its propagator, polarization, scalar-product, and Dirac-chain skeleton.";

D30OrderedTermSignatureAssociation::usage =
  "D30OrderedTermSignatureAssociation[coeffTerms] returns the D30 term signatures keyed by unsquared term index.";

D30OrderedTermClusterAssociation::usage =
  "D30OrderedTermClusterAssociation[coeffTerms] groups unsquared D30 term indices by shared topology signature.";

D30OrderedFamilySignature::usage =
  "D30OrderedFamilySignature[term] returns the reduced D30 unsquared-term signature with the chiral projector distinction removed, so left/right copies of the same physical topology fall into one family.";

D30OrderedFamilyAssociation::usage =
  "D30OrderedFamilyAssociation[coeffTerms] groups the raw D30 unsquared terms into reduced physical families.";

D30OrderedResidualScore::usage =
  "D30OrderedResidualScore[residual] returns the ordering used to rank D30 ordered-partial candidates by reconstruction quality.";

ExtractD30BornColorStrippedPartial::usage =
  "ExtractD30BornColorStrippedPartial[amp2] extracts the color-stripped Born partial used to normalize the ordered D30 construction.";

SwapD30OrderedPartial::usage =
  "SwapD30OrderedPartial[expr] exchanges the two final-state gluons in a D30 ordered partial, producing the partner ordered contribution.";

SwapD30OrderedLabelsRaw::usage =
  "SwapD30OrderedLabelsRaw[expr] applies the bare k2 <-> k3 label exchange used by the D30 ordered-partial route before any further canonicalization.";

ColorOrderedD30Antenna::usage =
  "ColorOrderedD30Antenna[amp3, bornAmp, numFinalParticles, spec] builds the ordered and symmetrized D30 antenna objects from color-stripped neutralino-decay partial amplitudes.";

D30OrderedInterferencePair::usage =
  "D30OrderedInterferencePair[leftTerm, rightTerm, numFinalParticles] evaluates one interference contribution between two color-stripped D30 ordered-partial terms.";

D30OrderedColorStrippedInterference::usage =
  "D30OrderedColorStrippedInterference[ampLeft, ampRight, numFinalParticles] evaluates the spin-summed ordered-partial interference term by term to avoid the expensive monolithic D30 square.";

SafeD30AntennaExactMatchQ::usage =
  "SafeD30AntennaExactMatchQ[target, candidate, numFinalParticles] runs the exact D30 comparison with a time limit and returns Missing when it does not finish.";

SafeD30AntennaNumericResidual::usage =
  "SafeD30AntennaNumericResidual[target, candidate, numFinalParticles] runs the numeric D30 residual check with a time limit and returns Missing when it does not finish.";

D30NormalizeOrderedUnsquared::usage =
  "D30NormalizeOrderedUnsquared[expr] applies the D30 unsquared-amplitude canonicalization used when comparing ordered partial candidates under gluon exchange.";

D30OrderedCandidateFixedProbeRules::usage =
  "D30OrderedCandidateFixedProbeRules[] returns the fixed numeric substitutions used to compare D30 ordered-partial candidates cheaply and reproducibly.";

D30OrderedCandidateScan::usage =
  "D30OrderedCandidateScan[amp3, bornAmp, spec] evaluates the current D30 ordered-partial candidate family, returning reconstruction and fixed-point probe diagnostics for each candidate.";

D30OrderedPreferredCandidateLabels::usage =
  "D30OrderedPreferredCandidateLabels[candidates] returns the candidate labels preferred by the D30 ordered route before falling back to the full heuristic pool.";

D30FinalizeOrderedAntenna::usage =
  "D30FinalizeOrderedAntenna[expr] applies the final D30 antenna-level cleanup after the ordered square-to-Born ratio, removing any surviving polarization and parity-odd trace artifacts before comparison.";

D30FinalPolarizationCleanupRules::usage =
  "D30FinalPolarizationCleanupRules[] returns the explicit D30 antenna-level cleanup rules that collapse the surviving final-state polarization remnants after the ordered ratio has been formed.";

D30OrderedNumeratorCandidateAssociation::usage =
  "D30OrderedNumeratorCandidateAssociation[candidates] returns the narrowed D30 ordered-numerator basis used by the cleaned ordered-paper fitter.";

D30OrderedFineNumeratorCandidateAssociation::usage =
  "D30OrderedFineNumeratorCandidateAssociation[coeffTerms] returns the finer D30 gluon-sector numerator basis built from the raw ordered terms inside families 6-10.";

D30OrderedNumeratorProbeResidual::usage =
  "D30OrderedNumeratorProbeResidual[candidate, bornSquare] returns the multi-point fixed-probe residuals of one cleaned ordered D30 numerator candidate against the ordered 0505111 target.";

D30OrderedNumeratorResidualDiagnostics::usage =
  "D30OrderedNumeratorResidualDiagnostics[candidate, bornSquare] returns both the exact symbolic residual score and the fixed-point probe residuals for one cleaned D30 ordered numerator candidate.";

D30OrderedNumeratorProbeRules::usage =
  "D30OrderedNumeratorProbeRules[] returns the fixed kinematic probe points used to discriminate cleaned D30 ordered numerator candidates.";

D30SelectOrderedNumeratorCandidate::usage =
  "D30SelectOrderedNumeratorCandidate[candidates, bornSquare] picks the D30 ordered numerator candidate by cleaned ordered-paper residual instead of by pre-square symmetry heuristics.";

D30OrderedNumeratorCandidateBuildableQ::usage =
  "D30OrderedNumeratorCandidateBuildableQ[candidate] returns True when the proposed D30 ordered numerator candidate survives the cheap square-level buildability probe.";

D30OrderedNumeratorPreferredLabels::usage =
  "D30OrderedNumeratorPreferredLabels[] returns the deterministic D30 tie-break preference among ordered numerator candidates that land in the same ordered-paper residual class.";

D30OrderedColorTensorFreeQ[expr_] :=
  FreeQ[expr, _SUNTF | _SUNF | _SUNFDelta | _SUNDelta | _SUNTrace];

D30OrderedNumeratorProbeRules[] :=
  {
    <|
      s12 -> 2,
      s13 -> 3,
      s23 -> 5,
      q2 -> 10,
      SUNN -> 3,
      SMP["g_s"] -> 1,
      D30SourceL -> 1,
      D30SourceR -> 0
    |>,
    <|
      s12 -> 3,
      s13 -> 5,
      s23 -> 7,
      q2 -> 15,
      SUNN -> 3,
      SMP["g_s"] -> 1,
      D30SourceL -> 1,
      D30SourceR -> 0
    |>,
    <|
      s12 -> 5,
      s13 -> 7,
      s23 -> 11,
      q2 -> 23,
      SUNN -> 3,
      SMP["g_s"] -> 1,
      D30SourceL -> 1,
      D30SourceR -> 0
    |>
  };

D30FinalPolarizationCleanupRules[] :=
  {
    Momentum[Polarization[-mom_, phase_.], dim_.] :>
      Momentum[Polarization[mom, phase], dim],
    Polarization[-mom_, phase_.] :>
      Polarization[mom, phase],
    Pair[Momentum[k2, _], Momentum[Polarization[k2, _], _]] -> 0,
    Pair[Momentum[k3, _], Momentum[Polarization[k3, _], _]] -> 0,
    Pair[Momentum[p, _], Momentum[Polarization[k2, _], _]] ->
      Pair[Momentum[k1 + k2 + k3, D], Momentum[Polarization[k2, I], D]],
    Pair[Momentum[p, _], Momentum[Polarization[k3, _], _]] ->
      Pair[Momentum[k1 + k2 + k3, D], Momentum[Polarization[k3, I], D]]
  };

D30FinalizeOrderedAntenna[expr_] :=
  Module[{baseline, cleaned},
    baseline =
      expr //
      ReplaceAll[D30SourceParityOddTraceRules[]] //
      ReplaceAll[D30SourceCanonicalKinematicRules[3]] //
      ReplaceAll[D30SourceMassRules[]] //
      ReplaceAll[CasimirSubs] //
      ReplaceAll[Epsilon -> 0] //
      Together;
    TimeConstrained[
      (
        KinematicRules[3];
        cleaned =
          baseline //
          ReplaceAll[D30FinalPolarizationCleanupRules[]] //
          ReplaceAll[{
            Pair[Momentum[k1 + k2 + k3, _], Momentum[Polarization[k2, phase_.], _]] :>
              Pair[Momentum[k1, D], Momentum[Polarization[k2, phase], D]] +
              Pair[Momentum[k3, D], Momentum[Polarization[k2, phase], D]],
            Pair[Momentum[k1 + k2 + k3, _], Momentum[Polarization[k3, phase_.], _]] :>
              Pair[Momentum[k1, D], Momentum[Polarization[k3, phase], D]] +
              Pair[Momentum[k2, D], Momentum[Polarization[k3, phase], D]]
          }] //
          DiracSigmaExplicit //
          Calc //
          ApplyFeynCalcRules[#, 3]& //
          ReplaceAll[D30SourceCanonicalKinematicRules[3]] //
          ReplaceAll[D30SourceMassRules[]] //
          ReplaceAll[D30SourceParityOddTraceRules[]] //
          ReplaceAll[CasimirSubs] //
          ReplaceAll[Epsilon -> 0] //
          Together;
        TimeConstrained[
          cleaned // Contract // DiracSimplify // Simplify // Expand,
          120,
          cleaned
        ]
      ),
      180,
      baseline
    ]
  ];

D30OrderedNumeratorCandidateAssociation[candidates_Association] :=
  Association @ KeySelect[
    Join[
      <|
        "Family10Only" -> Lookup[candidates, "Family10", Missing["NotBuilt"]],
        "Family10Plus6" ->
          Lookup[candidates, "Family10", 0] + Lookup[candidates, "Family6", 0],
        "Family10Plus7" ->
          Lookup[candidates, "Family10", 0] + Lookup[candidates, "Family7", 0],
        "Family10Plus8" ->
          Lookup[candidates, "Family10", 0] + Lookup[candidates, "Family8", 0],
        "Family10Plus9" ->
          Lookup[candidates, "Family10", 0] + Lookup[candidates, "Family9", 0],
        "Family10Plus67" ->
          Lookup[candidates, "Family10", 0] + Lookup[candidates, "Family6", 0] +
          Lookup[candidates, "Family7", 0],
        "Family10Plus89" ->
          Lookup[candidates, "Family10", 0] + Lookup[candidates, "Family8", 0] +
          Lookup[candidates, "Family9", 0],
        "Family10Plus6789" ->
          Lookup[candidates, "Family10", 0] + Lookup[candidates, "Family6", 0] +
          Lookup[candidates, "Family7", 0] + Lookup[candidates, "Family8", 0] +
          Lookup[candidates, "Family9", 0]
      |>,
      <|
        "FamilyGluonExchange" ->
          Lookup[candidates, "FamilyGluonExchange", Missing["NotBuilt"]],
        "FamilySymGluonPairs" ->
          Lookup[candidates, "FamilySymGluonPairs", Missing["NotBuilt"]],
        "FamilyAsymGluonPairs" ->
          Lookup[candidates, "FamilyAsymGluonPairs", Missing["NotBuilt"]]
      |>
    ],
    !MissingQ[Lookup[candidates, #, Missing["Missing"]]] || StringStartsQ[#, "Family10"]&
  ];

D30OrderedFineNumeratorCandidateAssociation[coeffTerms_List] :=
  Module[{families, gluonFamilies, gluonFamilyIndices,
     familySumCandidates, familyDifferenceCandidates, firstMemberIndices,
     secondMemberIndices, memberLayerCandidates},
    families = D30OrderedFamilyAssociation[coeffTerms];
    gluonFamilyIndices = {6, 7, 8, 9, 10};
    gluonFamilies =
      Select[
        Association @ KeyTake[families, gluonFamilyIndices],
        AssociationQ
      ];
    If[gluonFamilies === <||>,
      Return[<||>]
    ];
    familySumCandidates =
      Association @ KeyValueMap[
        Function[{familyIndex, entry},
          "FineFamily" <> ToString[familyIndex] <>
            "Sum" -> Total[coeffTerms[[Lookup[entry, "TermIndices", {}]]]]
        ],
        gluonFamilies
      ];
    familyDifferenceCandidates =
      Association @ KeyValueMap[
        Function[{familyIndex, entry},
          With[{termIndices = Lookup[entry, "TermIndices", {}]},
            If[Length[termIndices] =!= 2,
              Nothing,
              "FineFamily" <> ToString[familyIndex] <> "Difference" ->
                (coeffTerms[[termIndices[[1]]]] - coeffTerms[[termIndices[[2]]]])
            ]
          ]
        ],
        gluonFamilies
      ];
    firstMemberIndices =
      DeleteMissing[
        Map[
          With[{termIndices = Lookup[gluonFamilies, #, <||>]["TermIndices"] /. Missing[__] -> {}},
            If[Length[termIndices] >= 1, First[termIndices], Missing["NoFirstMember"]]
          ]&,
          gluonFamilyIndices
        ]
      ];
    secondMemberIndices =
      DeleteMissing[
        Map[
          With[{termIndices = Lookup[gluonFamilies, #, <||>]["TermIndices"] /. Missing[__] -> {}},
            If[Length[termIndices] >= 2, termIndices[[2]], Missing["NoSecondMember"]]
          ]&,
          gluonFamilyIndices
        ]
      ];
    memberLayerCandidates =
      <|
        "GluonFirstMembers" -> Total[coeffTerms[[firstMemberIndices]]],
        "GluonSecondMembers" -> Total[coeffTerms[[secondMemberIndices]]]
      |>;
    Join[
      familySumCandidates,
      familyDifferenceCandidates,
      memberLayerCandidates
    ]
  ];

D30OrderedNumeratorResidualDiagnostics[candidate_, bornSquare_] :=
  Module[{orderedSquare, orderedAntenna, orderedTarget, residual, probeRules},
    orderedSquare = TimeConstrained[
      Quiet[
        Check[
          D30SourceBridgeExpression[
            D30OrderedColorStrippedInterference[candidate, candidate, 3],
            3
          ],
          $Failed,
          {
            FermionSpinSum::spinorsleft,
            DoPolarizationSums::failmsg
          }
        ],
        {
          FermionSpinSum::spinorsleft,
          DoPolarizationSums::failmsg
        }
      ],
      240,
      Missing["TimedOut"]
    ];
    If[orderedSquare === $Failed || orderedSquare === Missing["TimedOut"],
      Return[Missing["InvalidCandidate"]]
    ];
    orderedAntenna =
      D30FinalizeOrderedAntenna[
        Together[
          (orderedSquare /
            (bornSquare GluonColourBasisNorm[1]^2 SUNN SMP["g_s"]^2)) /.
          q2 -> (s12 + s13 + s23)
        ]
      ];
    orderedTarget =
      D30OrderedPaperTerm[s12, s13, s23] /. q2 -> (s12 + s13 + s23);
    residual = Together[orderedAntenna - orderedTarget];
    probeRules = D30OrderedNumeratorProbeRules[];
    <|
      "ResidualScore" -> D30OrderedResidualScore[residual],
      "ProbeResiduals" ->
        Association @ MapIndexed[
          First[#2] ->
            TimeConstrained[
              N[
                residual /. Normal[#1],
                30
              ],
              60,
              Missing["TimedOut"]
            ]&,
          probeRules
        ]
    |>
  ];

D30OrderedNumeratorProbeResidual[candidate_, bornSquare_] :=
  Module[{diagnostics},
    diagnostics = D30OrderedNumeratorResidualDiagnostics[candidate, bornSquare];
    If[!AssociationQ[diagnostics],
      Return[diagnostics]
    ];
    diagnostics["ProbeResiduals"]
  ];

D30OrderedNumeratorCandidateBuildableQ[candidate_] :=
  Module[{probe},
    probe = TimeConstrained[
      Quiet[
        Check[
          D30OrderedColorStrippedInterference[candidate, candidate, 3],
          $Failed,
          {
            FermionSpinSum::spinorsleft,
            DoPolarizationSums::failmsg
          }
        ],
        {
          FermionSpinSum::spinorsleft,
          DoPolarizationSums::failmsg
        }
      ],
      20,
      Missing["TimedOut"]
    ];
    probe =!= $Failed && !MissingQ[probe]
  ];

D30OrderedNumeratorPreferredLabels[] :=
  {
    "FineFamily10Sum",
    "FineFamily10Difference",
    "GluonSecondMembers",
    "Family10Only",
    "Family10Plus89",
    "Family10Plus6789",
    "Family10Plus67",
    "Family10Plus9",
    "Family10Plus8",
    "Family10Plus7",
    "Family10Plus6",
    "FamilySymGluonPairs",
    "FamilyGluonExchange",
    "FamilyAsymGluonPairs"
  };

D30SelectOrderedNumeratorCandidate[
  candidates_Association,
  bornSquare_,
  coeffTerms_: Automatic
] :=
  Module[{coarseBasis, fineBasis, basis, buildableBasis, scoredLabels, scoreKey,
     preferredLabels, labelOrder, bestLabel},
    coarseBasis = D30OrderedNumeratorCandidateAssociation[candidates];
    fineBasis =
      If[ListQ[coeffTerms],
        D30OrderedFineNumeratorCandidateAssociation[coeffTerms],
        <||>
      ];
    basis = Join[fineBasis, coarseBasis];
    If[basis === <||>,
      Return[Missing["NoCandidates"]]
    ];
    buildableBasis =
      Association @ KeySelect[
        basis,
        D30OrderedNumeratorCandidateBuildableQ[basis[#]]&
      ];
    If[buildableBasis === <||>,
      buildableBasis = coarseBasis;
      If[buildableBasis === <||>,
        Return[Missing["NoBuildableCandidates"]]
      ]
    ];
    scoredLabels =
      Association @ KeyValueMap[
        #1 -> D30OrderedNumeratorResidualDiagnostics[#2, bornSquare]&,
        buildableBasis
      ];
    scoreKey[label_] :=
      Module[{entry, residualScore, values},
        entry = Lookup[scoredLabels, label, Missing["TimedOut"]];
        If[!AssociationQ[entry],
          Return[{Infinity}]
        ];
        residualScore = Lookup[entry, "ResidualScore", {Infinity}];
        values = Values[Lookup[entry, "ProbeResiduals", <||>]];
        If[AnyTrue[values, MissingQ],
          Return[{Infinity}]
        ];
        Join[residualScore, {Total[Abs[values]]}, Abs[values]]
      ];
    preferredLabels = D30OrderedNumeratorPreferredLabels[];
    labelOrder[label_] :=
      Module[{pos},
        pos = FirstPosition[preferredLabels, label, {Infinity}];
        First[pos]
      ];
    bestLabel =
      First @ MinimalBy[
        Keys[buildableBasis],
        {scoreKey[#], labelOrder[#]}&
      ];
    <|
      "SelectedLabel" -> bestLabel,
      "SelectedCandidate" -> buildableBasis[bestLabel],
      "ProbeResidualAssociation" -> scoredLabels,
      "CandidateAssociation" -> buildableBasis
    |>
  ];

D30OrderedPreferredCandidateLabels[candidates_Association] :=
  Select[
    {
      "FamilyGluonExchange",
      "FamilySymGluonPairs",
      "FamilySymGluinos",
      "FamilyContactPlus12",
      "FamilyContactPlus13",
      "FamilyGluino12",
      "FamilyGluino13",
      "FamilyContact",
      "FamilyAsymGluonPairs",
      "FamilyAsymGluinos",
      "Family1",
      "Family2",
      "Family3",
      "Family4",
      "Family5",
      "Family6",
      "Family7",
      "Family8",
      "Family9",
      "Family10"
    },
    KeyExistsQ[candidates, #]&
  ];

D30NormalizeOrderedUnsquared[expr_] :=
  Module[{normalized},
    normalized =
      expr //
      D30SourcePolarizationCanonicalize //
      ReplaceAll[{
        Momentum[p, dim_.] :> Momentum[k1 + k2 + k3, dim],
        Momentum[-p, dim_.] :> Momentum[-k1 - k2 - k3, dim]
      }] //
      FeynCalc`DiracSigmaExplicit //
      Expand;
    normalized =
      TimeConstrained[
        Quiet[
          Check[
            normalized //
            FeynCalc`DiracSimplify //
            Expand //
            FeynCalc`ChangeDimension[#, 4]& //
            FeynCalc`Contract //
            FeynCalc`DiracSimplify //
            Expand
            ,
            normalized
          ],
          {DiracEquation::failmsg}
        ],
        30,
        normalized
      ];
    normalized
  ];

D30OrderedCandidateFixedProbeRules[] :=
  {
    D30SourceL -> 1,
    D30SourceR -> 0,
    SMP["g_s"] -> 1,
    s12 -> 2,
    s13 -> 3,
    s23 -> 5,
    q2 -> 10
  };

SwapD30OrderedLabelsRaw[expr_] :=
  Module[{tempMom = Unique["d30SwapMom"], tempPol = Unique["d30SwapPol"],
     tempInv = Unique["d30SwapInv"], swapped},
    swapped =
      expr /. {
        Momentum[k2, dim_] :> Momentum[tempMom, dim],
        Polarization[k2, args___] :> Polarization[tempPol, args],
        s12 -> tempInv
      };
    swapped =
      swapped /. {
        Momentum[k3, dim_] :> Momentum[k2, dim],
        Polarization[k3, args___] :> Polarization[k2, args],
        s13 -> s12
      };
    swapped = swapped /. {
      Momentum[tempMom, dim_] :> Momentum[k3, dim],
      Polarization[tempPol, args___] :> Polarization[k3, args],
      tempInv -> s13
    };
    D30SourcePolarizationCanonicalize[swapped]
  ];

D30OrderedPartialSectorAssociation[] :=
  Module[{amp3, ordered, structures, coeff, coeffTerms},
    amp3 = D30EffectiveSourceAmplitude[3];
    ordered = ExpandUnsquaredColor[amp3];
    structures = DeleteDuplicates[Cases[ordered, _SUNF, Infinity]];
    If[Length[structures] =!= 1,
      Return[$Failed]
    ];
    coeff = Simplify[Coefficient[ordered, First[structures]]];
    coeffTerms = List @@ Expand[coeff];
    <|
      "ContactHalf" -> coeffTerms[[1]] / 2,
      "GluinoExchangeOrdered" -> coeffTerms[[2]],
      "GluonExchangeOrdered" -> Total[coeffTerms[[4 ;; 8]]]
    |>
  ];

D30OrderedResidualScore[Missing["TimedOut"]] :=
  {Infinity, Infinity};

D30OrderedResidualScore[expr_] /; TrueQ[expr === 0] :=
  {0, 0};

D30OrderedResidualScore[expr_] :=
  {1, LeafCount[expr]};

D30OrderedTermSignature[term_] :=
  Module[{canonical, diracLabels, sigmaLabels, pairLabels, denominatorLabels,
     polarizationLabels, sourceCouplings},
    canonical =
      term /. {
        Momentum[x_, ___] :> x,
        Polarization[x_, ___] :> HoldForm[pol[x]],
        Pair[left_, right_] :> HoldForm[pair[left, right]],
        FeynAmpDenominator[args___] :> HoldForm[den[args]],
        PropagatorDenominator[mom_, mass_] :> HoldForm[prop[mom, mass]]
      };
    diracLabels =
      Sort @ DeleteDuplicates @ Cases[
        canonical,
        DiracGamma[arg_, ___] :> HoldForm[gamma[arg]],
        Infinity
      ];
    sigmaLabels =
      Sort @ DeleteDuplicates @ Cases[
        canonical,
        DiracSigma[left_, right_] :> HoldForm[sigma[left, right]],
        Infinity
      ];
    pairLabels =
      Sort @ DeleteDuplicates @ Cases[
        canonical,
        HoldForm[pair[left_, right_]] :> HoldForm[pair[left, right]],
        Infinity
      ];
    denominatorLabels =
      Sort @ DeleteDuplicates @ Cases[
        canonical,
        HoldForm[den[args___]] :> HoldForm[den[args]],
        Infinity
      ];
    polarizationLabels =
      Sort @ DeleteDuplicates @ Cases[
        canonical,
        HoldForm[pol[arg_]] :> HoldForm[pol[arg]],
        Infinity
      ];
    sourceCouplings =
      Sort @ DeleteDuplicates @ Cases[
        term,
        D30SourceL | D30SourceR | SMP["g_s"],
        Infinity
      ];
    <|
      "Denominators" -> denominatorLabels,
      "Polarizations" -> polarizationLabels,
      "Pairs" -> pairLabels,
      "DiracGammas" -> diracLabels,
      "DiracSigmas" -> sigmaLabels,
      "SourceCouplings" -> sourceCouplings
    |>
  ];

D30OrderedTermSignatureAssociation[coeffTerms_List] :=
  Association @ Table[
    index -> D30OrderedTermSignature[coeffTerms[[index]]],
    {index, Length[coeffTerms]}
  ];

D30OrderedTermClusterAssociation[coeffTerms_List] :=
  Module[{signatures, grouped},
    signatures = D30OrderedTermSignatureAssociation[coeffTerms];
    grouped =
      GatherBy[
        Keys[signatures],
        signatures[#]&
      ];
    Association @ MapIndexed[
      First[#2] -> <|
        "Signature" -> signatures[First[#1]],
        "TermIndices" -> #1
      |>&,
      grouped
    ]
  ];

D30OrderedFamilySignature[term_] :=
  D30OrderedTermSignature[term] /. {
    HoldForm[gamma[6]] -> HoldForm[chiralGamma],
    HoldForm[gamma[7]] -> HoldForm[chiralGamma],
    D30SourceL -> HoldForm[chiralCoupling],
    D30SourceR -> HoldForm[chiralCoupling]
  };

D30OrderedFamilyAssociation[coeffTerms_List] :=
  Module[{signatures, grouped},
    signatures =
      Association @ Table[
        index -> D30OrderedFamilySignature[coeffTerms[[index]]],
        {index, Length[coeffTerms]}
      ];
    grouped =
      GatherBy[
        Keys[signatures],
        signatures[#]&
      ];
    Association @ MapIndexed[
      First[#2] -> <|
        "Signature" -> signatures[First[#1]],
        "TermIndices" -> #1,
        "FamilySum" -> Total[coeffTerms[[#1]]]
      |>&,
      grouped
    ]
  ];

D30OrderedTermOrbitAssociation[coeffTerms_List] :=
  Module[{scorePair, choosePartner},
    scorePair[left_, right_] :=
      Module[{directResidual, flippedResidual, directScore, flippedScore},
        directResidual = TimeConstrained[
          Together @ Simplify @ Expand[left - right],
          30,
          Missing["TimedOut"]
        ];
        flippedResidual = TimeConstrained[
          Together @ Simplify @ Expand[left + right],
          30,
          Missing["TimedOut"]
        ];
        directScore = D30OrderedResidualScore[directResidual];
        flippedScore = D30OrderedResidualScore[flippedResidual];
        If[OrderedQ[{directScore, flippedScore}],
          <|
            "Sign" -> 1,
            "Residual" -> directResidual,
            "Score" -> directScore
          |>,
          <|
            "Sign" -> -1,
            "Residual" -> flippedResidual,
            "Score" -> flippedScore
          |>
        ]
      ];
    choosePartner[index_] :=
      Module[{swapped, matches, best},
        swapped = SwapD30OrderedLabelsRaw[coeffTerms[[index]]];
        matches =
          Association @ Table[
            candidateIndex -> scorePair[swapped, coeffTerms[[candidateIndex]]],
            {candidateIndex, Length[coeffTerms]}
          ];
        best =
          First @ MinimalBy[
            Keys[matches],
            matches[#]["Score"]&
          ];
        <|
          "TermIndex" -> index,
          "BestPartnerIndex" -> best,
          "BestPartnerSign" -> matches[best]["Sign"],
          "BestResidualScore" -> matches[best]["Score"],
          "BestResidual" -> matches[best]["Residual"]
        |>
      ];
    Association @ Table[
      index -> choosePartner[index],
      {index, Length[coeffTerms]}
    ]
  ];

D30OrderedPartialCandidateAssociation[coeffTerms_List, fullCoeff_] :=
  Module[{contact, gluino12, gluino13, gluonTerms, gluonBlock, gluonAB,
     gluonCD, gluonACE, gluonBDE, rawSwap, symPart, antiPart, splitDefault,
     splitBothGluinos, families, familySums, familySpecs, specs, label},
    contact = coeffTerms[[1]];
    gluino12 = coeffTerms[[2]];
    gluino13 = coeffTerms[[3]];
    gluonTerms = coeffTerms[[4 ;; 8]];
    gluonBlock = Total[gluonTerms];
    gluonAB = gluonTerms[[1]] + gluonTerms[[2]];
    gluonCD = gluonTerms[[3]] + gluonTerms[[4]];
    gluonACE = gluonTerms[[1]] + gluonTerms[[3]] + gluonTerms[[5]];
    gluonBDE = gluonTerms[[2]] + gluonTerms[[4]] + gluonTerms[[5]];
    rawSwap = SwapD30OrderedLabelsRaw[fullCoeff];
    symPart = Together[Simplify[(fullCoeff + rawSwap) / 2]];
    antiPart = Together[Simplify[(fullCoeff - rawSwap) / 2]];
    families = D30OrderedFamilyAssociation[coeffTerms];
    familySums =
      Association @ KeyValueMap[
        "Family" <> ToString[#1] -> #2["FamilySum"]&,
        families
      ];
    splitDefault =
      Simplify[contact/2 + gluino12 + gluonBlock];
    splitBothGluinos =
      Simplify[contact/2 + gluino12 + gluino13 + gluonBlock];
    familySpecs = <|
      "FamilyContact" -> Lookup[familySums, "Family1", 0],
      "FamilyGluino12" ->
        Lookup[familySums, "Family2", 0] + Lookup[familySums, "Family3", 0],
      "FamilyGluino13" ->
        Lookup[familySums, "Family4", 0] + Lookup[familySums, "Family5", 0],
      "FamilyGluonExchange" ->
        Total[Lookup[familySums,
          {"Family6", "Family7", "Family8", "Family9", "Family10"},
          0
        ]],
      "FamilyContactPlus12" ->
        Total[Lookup[familySums, {"Family1", "Family2", "Family3"}, 0]],
      "FamilyContactPlus13" ->
        Total[Lookup[familySums, {"Family1", "Family4", "Family5"}, 0]],
      "FamilyAsymGluinos" ->
        Lookup[familySums, "Family2", 0] + Lookup[familySums, "Family3", 0] -
        Lookup[familySums, "Family4", 0] - Lookup[familySums, "Family5", 0],
      "FamilySymGluinos" ->
        Lookup[familySums, "Family2", 0] + Lookup[familySums, "Family3", 0] +
        Lookup[familySums, "Family4", 0] + Lookup[familySums, "Family5", 0],
      "FamilyAsymGluonPairs" ->
        Lookup[familySums, "Family6", 0] - Lookup[familySums, "Family9", 0] +
        Lookup[familySums, "Family8", 0] - Lookup[familySums, "Family7", 0],
      "FamilySymGluonPairs" ->
        Lookup[familySums, "Family6", 0] + Lookup[familySums, "Family9", 0] +
        Lookup[familySums, "Family8", 0] + Lookup[familySums, "Family7", 0] +
        Lookup[familySums, "Family10", 0]
    |>;
    specs = {
      {"SplitDefault", 1/2, 1, 0, 1},
      {"SplitBothGluinos", 1/2, 1, 1, 1},
      {"ContactOffBothGluinos", 0, 1, 1, 1},
      {"ContactFullBothGluinos", 1, 1, 1, 1},
      {"HalfCoefficient", 1/2, 1/2, 1/2, 1/2},
      {"SplitDefaultHalfGluon", 1/2, 1, 0, 1/2},
      {"SplitBothGluinosHalfGluon", 1/2, 1, 1, 1/2},
      {"ContactOffDefaultHalfGluon", 0, 1, 0, 1/2},
      {"ContactFullDefaultHalfGluon", 1, 1, 0, 1/2},
      {"SplitDefaultGluonAB", 1/2, 1, 0, gluonAB},
      {"SplitDefaultGluonCD", 1/2, 1, 0, gluonCD},
      {"SplitDefaultGluonACE", 1/2, 1, 0, gluonACE},
      {"SplitDefaultGluonBDE", 1/2, 1, 0, gluonBDE},
      {"SplitBothGluinosGluonAB", 1/2, 1, 1, gluonAB},
      {"SplitBothGluinosGluonCD", 1/2, 1, 1, gluonCD},
      {"SplitBothGluinosGluonACE", 1/2, 1, 1, gluonACE},
      {"SplitBothGluinosGluonBDE", 1/2, 1, 1, gluonBDE},
      {"ContactOffBothGluinosNoGluon", 0, 1, 1, 0},
      {"AntiPart", antiPart, Missing["Direct"], Missing["Direct"],
        Missing["Direct"]},
      {"SymPart", symPart, Missing["Direct"], Missing["Direct"],
        Missing["Direct"]},
      {"SplitDefaultPlusSymHalf", splitDefault + symPart/2,
        Missing["Direct"], Missing["Direct"], Missing["Direct"]},
      {"SplitDefaultMinusSymHalf", splitDefault - symPart/2,
        Missing["Direct"], Missing["Direct"], Missing["Direct"]},
      {"SplitBothGluinosPlusSymHalf", splitBothGluinos + symPart/2,
        Missing["Direct"], Missing["Direct"], Missing["Direct"]},
      {"SplitBothGluinosMinusSymHalf", splitBothGluinos - symPart/2,
        Missing["Direct"], Missing["Direct"], Missing["Direct"]},
      {"Gluino12Only", 0, 1, 0, 0},
      {"Gluino13Only", 0, 0, 1, 0},
      {"FullCoefficient", Missing["Direct"], Missing["Direct"],
        Missing["Direct"], Missing["Direct"]}
    };
    Join[
      Association @ Table[
        label = spec[[1]];
        label ->
          If[label === "FullCoefficient",
            fullCoeff,
            If[MemberQ[{
                "AntiPart",
                "SymPart",
                "SplitDefaultPlusSymHalf",
                "SplitDefaultMinusSymHalf",
                "SplitBothGluinosPlusSymHalf",
                "SplitBothGluinosMinusSymHalf"
              }, label],
              spec[[2]],
            Simplify[
              spec[[2]] contact +
              spec[[3]] gluino12 +
              spec[[4]] gluino13 +
              If[NumericQ[spec[[5]]] || IntegerQ[spec[[5]]] || RationalQ[spec[[5]]],
                spec[[5]] gluonBlock,
                spec[[5]]
              ]
            ]
            ]
          ],
        {spec, specs}
      ],
      familySums,
      familySpecs
    ]
  ];

ExtractD30OrderedPartial[amp3_] :=
  Module[{ordered, structures, coeff, coeffTerms, sectors, candidates,
     candidateResiduals, bornAmp, bornData, bornSquareRaw, bornSquare,
     numeratorSelection, candidateLabelPool, bestLabel, candidate,
     orderingResidual, reconstruction},
    ordered = ExpandUnsquaredColor[amp3];
    structures = DeleteDuplicates[Cases[ordered, _SUNF, Infinity]];
    If[Length[structures] =!= 1,
      Print["Ordered D30 route: expected one unsquared structure constant, found ",
        Length[structures]];
      Return[$Failed]
    ];
    coeff = Simplify[Coefficient[ordered, First[structures]]];
    reconstruction = Simplify[Expand[ordered - First[structures] coeff]];
    If[!TrueQ[reconstruction === 0],
      Print["Ordered D30 route: unsquared color reconstruction failed."];
      Return[$Failed]
    ];
    coeffTerms = List @@ Expand[coeff];
    sectors = D30OrderedPartialSectorAssociation[];
    If[sectors === $Failed,
      Print["Ordered D30 route: could not build the stripped sector split."];
      Return[$Failed]
    ];
    candidates = D30OrderedPartialCandidateAssociation[coeffTerms, coeff];
    candidateResiduals =
      Association @ KeyValueMap[
        #1 ->
          TimeConstrained[
            Together @ Simplify @ Expand[
              (#2 - SwapD30OrderedLabelsRaw[#2]) - coeff
            ],
            60,
            Missing["TimedOut"]
          ]&,
        candidates
      ];
    bornAmp = D30EffectiveSourceAmplitude[2];
    bornData = ExtractD30BornColorStrippedPartial[bornAmp];
    numeratorSelection =
      If[AssociationQ[bornData],
        bornSquareRaw = D30OrderedColorStrippedInterference[
          bornData["Coefficient"],
          bornData["Coefficient"],
          2
        ];
        bornSquare =
          If[bornSquareRaw === $Failed,
            Missing["NotBuilt"],
            D30SourceBridgeExpression[bornSquareRaw, 2]
          ];
        If[bornSquare === Missing["NotBuilt"],
          Missing["NotBuilt"],
          D30SelectOrderedNumeratorCandidate[candidates, bornSquare, coeffTerms]
        ],
        Missing["NotBuilt"]
      ];
    candidateLabelPool = D30OrderedPreferredCandidateLabels[candidates];
    If[candidateLabelPool === {},
      candidateLabelPool = Keys[candidates]
    ];
    bestLabel =
      If[AssociationQ[numeratorSelection],
        numeratorSelection["SelectedLabel"],
        First @ MinimalBy[
          candidateLabelPool,
          D30OrderedResidualScore[candidateResiduals[#]]&
        ]
      ];
    candidate =
      If[AssociationQ[numeratorSelection],
        numeratorSelection["SelectedCandidate"],
        candidates[bestLabel]
      ];
    orderingResidual = candidateResiduals[bestLabel];
    If[!D30OrderedColorTensorFreeQ[candidate],
      Print["Ordered D30 route: extracted ordered partial still contains color tensors."];
      Return[$Failed]
    ];
    <|
      "ColorFactor" -> First[structures],
      "Coefficient" -> candidate,
      "FullSUNFCoefficient" -> coeff,
      "SectorAssociation" -> sectors,
      "CandidateAssociation" -> candidates,
      "SelectedCandidateLabel" -> bestLabel,
      "NumeratorSelection" -> numeratorSelection,
      "CandidateResidualAssociation" -> candidateResiduals,
      "OrderedAmplitude" -> ordered,
      "ReconstructionResidual" -> reconstruction,
      "OrderingResidual" -> orderingResidual
    |>
  ];

ExtractD30BornColorStrippedPartial[amp2_] :=
  Module[{ordered, deltas, coeff},
    ordered = ExpandUnsquaredColor[amp2];
    deltas = DeleteDuplicates[Cases[ordered, _SUNDelta | _SUNFDelta, Infinity]];
    If[Length[deltas] =!= 1,
      Print["Ordered D30 route: expected one Born color delta, found ",
        Length[deltas]];
      Return[$Failed]
    ];
    coeff = Simplify[Coefficient[ordered, First[deltas]]];
    If[!D30OrderedColorTensorFreeQ[coeff],
      Print["Ordered D30 route: Born partial still contains color tensors."];
      Return[$Failed]
    ];
    <|"ColorDelta" -> First[deltas], "Coefficient" -> coeff|>
  ];

SwapD30OrderedPartial[expr_] :=
  SwapD30OrderedLabelsRaw[expr];

D30OrderedInterferencePair[leftTerm_, rightTerm_, numFinalParticles_] :=
  Module[{bare, summed, polarized, expanded, evaluated, final},
    KinematicRules[numFinalParticles];
    bare = ComplexConjugate[leftTerm] rightTerm;
    summed =
      bare //
      FermionSpinSum;
    polarized =
      D30SourcePolarizationSum[
        D30SourcePolarizationCanonicalize[summed],
        numFinalParticles
      ];
    expanded = DiracSigmaExplicit[polarized];
    evaluated = Calc[expanded];
    final =
      evaluated //
      ApplyFeynCalcRules[#, numFinalParticles]& //
      ReplaceAll[D30SourceCanonicalKinematicRules[numFinalParticles]] //
      ReplaceAll[D30SourceMassRules[]] //
      ReplaceAll[CasimirSubs] //
      ReplaceAll[D -> 4 - 2 Epsilon] //
      SUNSimplify //
      ReplaceAll[CasimirSubs] //
      Together;
    final
  ];

D30OrderedColorStrippedInterference[ampLeft_, ampRight_, numFinalParticles_] :=
  Module[{leftTerms, rightTerms, diagonal, offDiagonal, result},
    leftTerms = List @@ Expand[ampLeft];
    rightTerms = List @@ Expand[ampRight];
    If[ampLeft === ampRight,
      diagonal =
        Sum[
          D30OrderedInterferencePair[leftTerms[[i]], leftTerms[[i]],
            numFinalParticles],
          {i, Length[leftTerms]}
        ];
      offDiagonal =
        Sum[
          D30OrderedInterferencePair[leftTerms[[i]], leftTerms[[j]],
            numFinalParticles] +
          D30OrderedInterferencePair[leftTerms[[j]], leftTerms[[i]],
            numFinalParticles],
          {i, 1, Length[leftTerms] - 1},
          {j, i + 1, Length[leftTerms]}
        ];
      result = diagonal + offDiagonal;
      Return[Together[result] // Simplify]
    ];
    result =
      Sum[
        D30OrderedInterferencePair[leftTerms[[i]], rightTerms[[j]],
          numFinalParticles],
        {i, Length[leftTerms]},
        {j, Length[rightTerms]}
      ];
    Together[result] // Simplify
  ];

D30OrderedCandidateScan[amp3_, bornAmp_, spec_Association : <||>] :=
  Module[{ordered, structures, fullCoeff, coeffTerms, candidates, bornData,
     bornSquareRaw, bornSquare, target, probeRules, normalization,
     scanOne},
    ordered = ExpandUnsquaredColor[amp3];
    structures = DeleteDuplicates[Cases[ordered, _SUNF, Infinity]];
    If[Length[structures] =!= 1,
      Return[$Failed]
    ];
    fullCoeff = Simplify[Coefficient[ordered, First[structures]]];
    coeffTerms = List @@ Expand[fullCoeff];
    candidates = D30OrderedPartialCandidateAssociation[coeffTerms, fullCoeff];
    bornData = ExtractD30BornColorStrippedPartial[bornAmp];
    If[bornData === $Failed,
      Return[$Failed]
    ];
    bornSquareRaw = D30OrderedColorStrippedInterference[
      bornData["Coefficient"],
      bornData["Coefficient"],
      2
    ];
    If[bornSquareRaw === $Failed,
      Return[$Failed]
    ];
    bornSquare = D30SourceBridgeExpression[bornSquareRaw, 2];
    normalization = GluonColourBasisNorm[Lookup[spec, "NumGluons", 1]]^2;
    target = D30OrderedPaperTerm[s12, s13, s23] // Together // Simplify;
    probeRules = D30OrderedCandidateFixedProbeRules[];
    scanOne[label_, candidate_] :=
      Module[{orderingResidual, orderedSquareRaw, orderedSquare, antenna,
         targetProbe, candidateProbe},
        orderingResidual = TimeConstrained[
          Together @ Simplify @ Expand[
            (candidate - SwapD30OrderedLabelsRaw[candidate]) - fullCoeff
          ],
          60,
          Missing["TimedOut"]
        ];
        orderedSquareRaw = TimeConstrained[
          D30OrderedColorStrippedInterference[candidate, candidate, 3],
          180,
          Missing["TimedOut"]
        ];
        If[orderedSquareRaw === $Failed || orderedSquareRaw === Missing["TimedOut"],
          Return[
            <|
              "Label" -> label,
              "OrderingResidual" -> orderingResidual,
              "OrderingResidualScore" -> D30OrderedResidualScore[orderingResidual],
              "OrderedSquareBuilt" -> False
            |>
          ]
        ];
        orderedSquare = D30SourceBridgeExpression[orderedSquareRaw, 3];
        antenna =
          Together[orderedSquare / (bornSquare normalization)] // Simplify;
        targetProbe = TimeConstrained[N[target /. probeRules, 30], 30,
          Missing["TimedOut"]];
        candidateProbe = TimeConstrained[N[antenna /. probeRules, 30], 30,
          Missing["TimedOut"]];
        <|
          "Label" -> label,
          "OrderingResidual" -> orderingResidual,
          "OrderingResidualScore" -> D30OrderedResidualScore[orderingResidual],
          "OrderedSquareBuilt" -> True,
          "CandidateProbeValue" -> candidateProbe,
          "TargetProbeValue" -> targetProbe,
          "ProbeDifference" ->
            If[Or[targetProbe === Missing["TimedOut"],
                candidateProbe === Missing["TimedOut"]],
              Missing["TimedOut"],
              candidateProbe - targetProbe
            ]
        |>
      ];
    Association @ KeyValueMap[#1 -> scanOne[#1, #2] &, candidates]
  ];

SafeD30AntennaExactMatchQ[target_, candidate_, numFinalParticles_] :=
  Module[{result},
    result = TimeConstrained[
      TrueQ[TestEqualAntennaeQ[target, candidate, numFinalParticles]],
      120,
      Missing["TimedOut"]
    ];
    result
  ];

SafeD30AntennaNumericResidual[target_, candidate_, numFinalParticles_] :=
  Module[{result},
    result = TimeConstrained[
      ExactNumericResidual[target, candidate, numFinalParticles],
      120,
      Missing["TimedOut"]
    ];
    result
  ];

ColorOrderedD30Antenna[amp3_, bornAmp_, numFinalParticles_, spec_Association] :=
  Module[{numGluons, orderedData, bornData, exchangedCoefficient,
     orderedSquareRaw, exchangedSquareRaw, bornSquareRaw, orderedSquare,
     exchangedSquare, bornSquare, normalization, orderedAntenna,
     exchangedAntenna, antenna, orderedTarget, exchangedTarget, fullTarget,
     diagnostics},
    numGluons = Lookup[spec, "NumGluons", 1];
    orderedData = ExtractD30OrderedPartial[amp3];
    If[orderedData === $Failed,
      Return[$Failed]
    ];
    bornData = ExtractD30BornColorStrippedPartial[bornAmp];
    If[bornData === $Failed,
      Return[$Failed]
    ];
    exchangedCoefficient = SwapD30OrderedPartial[orderedData["Coefficient"]];
    orderedSquareRaw = D30OrderedColorStrippedInterference[
      orderedData["Coefficient"],
      orderedData["Coefficient"],
      numFinalParticles
    ];
    exchangedSquareRaw = D30OrderedColorStrippedInterference[
      exchangedCoefficient,
      exchangedCoefficient,
      numFinalParticles
    ];
    bornSquareRaw = D30OrderedColorStrippedInterference[
      bornData["Coefficient"],
      bornData["Coefficient"],
      2
    ];
    If[MemberQ[{orderedSquareRaw, exchangedSquareRaw, bornSquareRaw}, $Failed],
      Return[$Failed]
    ];
    orderedSquare = D30SourceBridgeExpression[orderedSquareRaw, 3];
    exchangedSquare = D30SourceBridgeExpression[exchangedSquareRaw, 3];
    bornSquare = D30SourceBridgeExpression[bornSquareRaw, 2];
    normalization = GluonColourBasisNorm[numGluons]^2 SUNN SMP["g_s"]^2;
    orderedAntenna = TimeConstrained[
      Together[orderedSquare / (bornSquare normalization)] // Simplify,
      180,
      Together[orderedSquare / (bornSquare normalization)]
    ];
    orderedAntenna = orderedAntenna /. q2 -> (s12 + s13 + s23);
    orderedAntenna = D30FinalizeOrderedAntenna[orderedAntenna];
    exchangedAntenna = TimeConstrained[
      Together[exchangedSquare / (bornSquare normalization)] // Simplify,
      180,
      Together[exchangedSquare / (bornSquare normalization)]
    ];
    exchangedAntenna = exchangedAntenna /. q2 -> (s12 + s13 + s23);
    exchangedAntenna = D30FinalizeOrderedAntenna[exchangedAntenna];
    antenna = TimeConstrained[
      Together[orderedAntenna + exchangedAntenna] // Simplify,
      180,
      Together[orderedAntenna + exchangedAntenna]
    ];
    antenna = D30FinalizeOrderedAntenna[antenna];
    orderedTarget = D30OrderedPaperTerm[s12, s13, s23] // Together // Simplify;
    exchangedTarget =
      D30OrderedPaperTerm[s13, s12, s23] // Together // Simplify;
    fullTarget = D30Paper // Together // Simplify;
    diagnostics = <|
      "OrderedAntennaExactMatchQ" ->
        SafeD30AntennaExactMatchQ[orderedTarget, orderedAntenna, 3],
      "OrderedAntennaNumericResidual" ->
        SafeD30AntennaNumericResidual[orderedTarget, orderedAntenna, 3],
      "ExchangedOrderedAntennaExactMatchQ" ->
        SafeD30AntennaExactMatchQ[exchangedTarget, exchangedAntenna, 3],
      "ExchangedOrderedAntennaNumericResidual" ->
        SafeD30AntennaNumericResidual[exchangedTarget, exchangedAntenna, 3],
      "FullAntennaExactMatchQ" ->
        SafeD30AntennaExactMatchQ[fullTarget, antenna, 3],
      "FullAntennaNumericResidual" ->
        SafeD30AntennaNumericResidual[fullTarget, antenna, 3],
      "UnsquaredReconstructionResidual" ->
        orderedData["ReconstructionResidual"],
      "OrderingResidual" -> orderedData["OrderingResidual"],
      "SelectedCandidateLabel" -> orderedData["SelectedCandidateLabel"],
      "NumeratorSelection" ->
        Lookup[orderedData, "NumeratorSelection", Missing["NotBuilt"]],
      "CandidateResidualAssociation" ->
        orderedData["CandidateResidualAssociation"]
    |>;
    <|
      "OrderedPartial" -> orderedData["Coefficient"],
      "ExchangedOrderedPartial" -> exchangedCoefficient,
      "BornPartial" -> bornData["Coefficient"],
      "OrderedSquare" -> orderedSquare,
      "ExchangedOrderedSquare" -> exchangedSquare,
      "BornSquare" -> bornSquare,
      "OrderedAntenna" -> orderedAntenna,
      "ExchangedOrderedAntenna" -> exchangedAntenna,
      "Antenna" -> antenna,
      "ColorFactor" -> orderedData["ColorFactor"],
      "BornColorDelta" -> bornData["ColorDelta"],
      "Normalization" -> normalization,
      "Diagnostics" -> diagnostics
    |>
  ];
