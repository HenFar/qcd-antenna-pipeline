(* ::Section:: *)
(* Physics-aware validation scaffold *)

(* Communicates with:
   - src/interface/integration_router.wl, whose integrated diagnostics and
     public BuildAndIntegrateAntenna[...] route supply the computed objects
     being validated here.
   - src/engines/integrated_antenna_extraction.wl and
     src/interface/paper_targets.wl, whose encoded target series furnish the
     first exact pole-structure checks.
   - src/interface/runtime_reports.wl, whose SupportedMasslessReleaseRouteQ[...]
     helper identifies the public release routes this layer can summarize.

   Why this file exists:
   The release verification script answers "does this checkout run?"  This file
   begins the separate, physics-aware question: "what exact structural checks
   do we currently know how to enforce, and which routes still need more
   validation work?" *)

AntennaPhysicsValidationReport::usage =
  "AntennaPhysicsValidationReport[type, numFinalParticles, loopOrder] runs the current physics-aware validation layer for one public route and returns a structured report.";

RunSupportedMasslessPhysicsValidation::usage =
  "RunSupportedMasslessPhysicsValidation[] runs AntennaPhysicsValidationReport[...] across the supported integrated massless release routes and returns an association of route reports.";

IntegratedPoleCoefficientAssociation::usage =
  "IntegratedPoleCoefficientAssociation[expr] returns the Laurent coefficients from epsilon^-4 through epsilon^0 used by the current integrated pole-structure checks.";

PhysicsValidationStatusCounts::usage =
  "PhysicsValidationStatusCounts[report] summarizes how many route reports landed in each validation status.";

IntegratedPoleCoefficientAssociation[expr_] :=
  Module[{eps, truncated},
    eps = FeynCalc`Epsilon;
    truncated =
      Quiet[
        Check[
          Normal[Series[expr, {eps, 0, 0}]],
          expr
        ],
        {SeriesData::sdatv, Series::esss}
      ];
    Association @ Table[
      power -> SafeIntegratedResidualSimplify[Coefficient[truncated, eps, power]],
      {power, -4, 0}
    ]
  ];

IntegratedPoleCoefficientAssociation[expr_List] :=
  IntegratedPoleCoefficientAssociation /@ expr;

ValidationComponentLabels[{a_Symbol /; SymbolName[a] === "A", 3, 1}] :=
  {"Leading", "Subleading", "Nf"};

ValidationComponentLabels[{a_Symbol /; SymbolName[a] === "A", 2, 2}] :=
  {"Leading", "Subleading", "Nf", "Breve"};

ValidationComponentLabels[_] :=
  {"Value"};

IntegratedPoleValidationTarget[{a_Symbol /; SymbolName[a] === "A", 2, 1},
   order_Integer, component_] :=
  IntegratedAntennaSeries[A21IntegratedPaper, order];

IntegratedPoleValidationTarget[{a_Symbol /; SymbolName[a] === "A", 3, 0},
   order_Integer, component_] :=
  IntegratedA30SubtractionSeries[order];

IntegratedPoleValidationTarget[{a_Symbol /; SymbolName[a] === "A", 3, 1},
   order_Integer, component_] :=
  If[component === All,
    A31IntegratedAntennaTargets[order]
    ,
    A31IntegratedAntennaTargetForComponent[component, order]
  ];

IntegratedPoleValidationTarget[{a_Symbol /; SymbolName[a] === "A", 2, 2},
   order_Integer, component_] :=
  If[component === All,
    A22TTermTargets[order]
    ,
    A22TTermTargetForComponent[component, order]
  ];

IntegratedPoleValidationTarget[_, _, _] :=
  Missing["NoIntegratedPoleTargetAvailable"];

PhysicsValidationTargetAvailabilityProfile[{a_Symbol /; SymbolName[a] === "A",
    2, 1}] :=
  <|
    "ValidationFamily" -> "IntegratedPoleStructure",
    "Availability" -> "ExactPoleTargetAvailable",
    "ExpectedStatus" -> "PassExpected",
    "Note" -> "Exact integrated literature target is encoded for A21."
  |>;

PhysicsValidationTargetAvailabilityProfile[{a_Symbol /; SymbolName[a] === "A",
    3, 0}] :=
  <|
    "ValidationFamily" -> "IntegratedPoleStructure",
    "Availability" -> "ExactPoleTargetAvailable",
    "ExpectedStatus" -> "PassExpected",
    "Note" -> "Exact integrated literature target is encoded for A30."
  |>;

PhysicsValidationTargetAvailabilityProfile[{a_Symbol /; SymbolName[a] === "A",
    3, 1}] :=
  <|
    "ValidationFamily" -> "IntegratedPoleStructure",
    "Availability" -> "ExactPoleTargetAvailable",
    "ExpectedStatus" -> "KnownIssuePendingTask5b",
    "Note" -> "Exact A31 integrated targets are encoded, but remaining residual mismatches are an explicitly tracked known issue."
  |>;

PhysicsValidationTargetAvailabilityProfile[{a_Symbol /; SymbolName[a] === "A",
    2, 2}] :=
  <|
    "ValidationFamily" -> "IntegratedPoleStructure",
    "Availability" -> "ExactPoleTargetAvailable",
    "ExpectedStatus" -> "PassExpected",
    "Note" -> "Exact A22 integrated targets are encoded through the current T-term/final-output identification."
  |>;

PhysicsValidationTargetAvailabilityProfile[{a_Symbol /; SymbolName[a] === "A",
    4, 0}] :=
  <|
    "ValidationFamily" -> "IntegratedPoleStructure",
    "Availability" -> "NoExactPoleTargetYet",
    "ExpectedStatus" -> "NotAvailableYet",
    "Note" -> "Integrated A40 exact pole targets are not yet encoded in the public validation layer."
  |>;

PhysicsValidationTargetAvailabilityProfile[{b_Symbol /; SymbolName[b] === "B",
    4, 0}] :=
  <|
    "ValidationFamily" -> "IntegratedPoleStructure",
    "Availability" -> "NoExactPoleTargetYet",
    "ExpectedStatus" -> "NotAvailableYet",
    "Note" -> "Integrated B40 exact pole targets are not yet encoded in the public validation layer."
  |>;

PhysicsValidationTargetAvailabilityProfile[{c_Symbol /; SymbolName[c] === "C",
    4, 0}] :=
  <|
    "ValidationFamily" -> "IntegratedPoleStructure",
    "Availability" -> "NoExactPoleTargetYet",
    "ExpectedStatus" -> "NotAvailableYet",
    "Note" -> "Integrated C40 exact pole targets are not yet encoded in the public validation layer."
  |>;

PhysicsValidationTargetAvailabilityProfile[_] :=
  <|
    "ValidationFamily" -> "IntegratedPoleStructure",
    "Availability" -> "OutsideCurrentValidationScope",
    "ExpectedStatus" -> "NotAvailableYet",
    "Note" -> "No integrated pole-structure validation target is currently registered for this route."
  |>;

PhysicsValidationComponentAssociation[key_List, values_List] :=
  AssociationThread[ValidationComponentLabels[key], values];

PhysicsValidationComponentAssociation[_, value_] :=
  value;

ZeroPoleCoefficientAssociationQ[assoc_Association] :=
  And @@ (TrueQ[# === 0]& /@ Values[assoc]);

ZeroPoleCoefficientAssociationQ[values_List] :=
  And @@ (ZeroPoleCoefficientAssociationQ[#]& /@ values);

ZeroPoleCoefficientAssociationQ[value_] :=
  TrueQ[value === 0];

PhysicsValidationStatusFromResidual[key_List, zeroQ_] :=
  Module[{availability},
    availability = PhysicsValidationTargetAvailabilityProfile[key];
    Which[
      availability["ExpectedStatus"] === "NotAvailableYet",
        "NotAvailableYet"
      ,
      TrueQ[zeroQ],
        "Pass"
      ,
      availability["ExpectedStatus"] === "KnownIssuePendingTask5b",
        "KnownIssue"
      ,
      True,
        "Fail"
    ]
  ];

IntegratedPoleValidationDiagnosticSummary[key_List, diagnostics_Association] :=
  Module[{},
    Switch[key,
      {a_Symbol /; SymbolName[a] === "A", 2, 1},
        KeyTake[diagnostics, {"PaVeResidualIsZero", "IntegratedResidualIsZero"}]
      ,
      {a_Symbol /; SymbolName[a] === "A", 3, 0},
        KeyTake[diagnostics, {"IntegratedResidualIsZero"}]
      ,
      {a_Symbol /; SymbolName[a] === "A", 3, 1},
        KeyTake[diagnostics, {"TTermResidualsAreZero",
          "IntegratedAntennaResidualsAreZero"}]
      ,
      {a_Symbol /; SymbolName[a] === "A", 2, 2},
        KeyTake[diagnostics, {"TTermResidualsAreZero",
          "IntegratedAntennaResidualsAreZero"}]
      ,
      _,
        KeyTake[diagnostics, {"PaperCheckAvailable",
          "FinalAntennaExtractionImplemented"}]
    ]
  ];

BuildIntegratedPoleValidationReport[key_List, result_, diagnostics_Association,
   component_, order_Integer] :=
  Module[{availability, target, observedPoles, targetPoles, residual,
     residualPoles, residualZeroQ, validationStatus},
    availability = PhysicsValidationTargetAvailabilityProfile[key];
    target = IntegratedPoleValidationTarget[key, order, component];
    If[MissingQ[target],
      Return[
        <|
          "ValidationFamily" -> availability["ValidationFamily"],
          "Availability" -> availability["Availability"],
          "ValidationStatus" -> "NotAvailableYet",
          "ExpectedStatus" -> availability["ExpectedStatus"],
          "Note" -> availability["Note"],
          "ObservedPoleCoefficients" ->
            PhysicsValidationComponentAssociation[key,
              IntegratedPoleCoefficientAssociation[result]],
          "TargetPoleCoefficients" -> Missing["NotAvailable"],
          "ResidualPoleCoefficients" -> Missing["NotAvailable"],
          "ResidualIsZero" -> Missing["NotAvailable"]
        |>
      ]
    ];
    residual =
      If[ListQ[result] && ListQ[target],
        MapThread[SafeIntegratedResidualSimplify[#1 - #2]&, {result, target}]
        ,
        SafeIntegratedResidualSimplify[result - target]
      ];
    observedPoles =
      PhysicsValidationComponentAssociation[key,
        IntegratedPoleCoefficientAssociation[result]];
    targetPoles =
      PhysicsValidationComponentAssociation[key,
        IntegratedPoleCoefficientAssociation[target]];
    residualPoles =
      PhysicsValidationComponentAssociation[key,
        IntegratedPoleCoefficientAssociation[residual]];
    residualZeroQ =
      If[ListQ[residual],
        And @@ (TrueQ[# === 0]& /@ residual)
        ,
        TrueQ[residual === 0]
      ];
    validationStatus = PhysicsValidationStatusFromResidual[key, residualZeroQ];
    <|
      "ValidationFamily" -> availability["ValidationFamily"],
      "Availability" -> availability["Availability"],
      "ValidationStatus" -> validationStatus,
      "ExpectedStatus" -> availability["ExpectedStatus"],
      "Note" -> availability["Note"],
      "ObservedPoleCoefficients" -> observedPoles,
      "TargetPoleCoefficients" -> targetPoles,
      "ResidualPoleCoefficients" -> residualPoles,
      "ResidualIsZero" -> residualZeroQ
    |>
  ];

Options[AntennaPhysicsValidationReport] = {
  quarkMass -> 0,
  "ExpansionOrder" -> 0,
  Component -> All,
  "EvaluateUnavailableRoutes" -> False,
  "UseStoredResults" -> True,
  "StoreResults" -> False,
  "RefreshStoredResults" -> False,
  "ResultsCacheRoot" -> Automatic,
  "ApplyFeynCalcMS" -> True,
  "PaVeEvaluation" -> "PaXEvaluate",
  "KinematicScale" -> q2,
  "NormalizeKinematicScale" -> True,
  "LoopMomentum" -> l,
  "ApplyDimReg" -> True,
  "BasisFamily" -> Automatic,
  "BasisRoot" -> Automatic,
  "GenerateMissingBases" -> False,
  "DetailedTimingDiagnostics" -> False
};

AntennaPhysicsValidationReport[type_, numFinalParticles_Integer,
   loopOrder_Integer, OptionsPattern[]] :=
  Module[{key, component, expansionOrder, result, diagnostics,
     integratedValidation, supportQ, availability},
    key = {type, numFinalParticles, loopOrder};
    component = OptionValue[Component];
    expansionOrder = OptionValue["ExpansionOrder"];
    supportQ = SupportedMasslessReleaseRouteQ[key];
    availability = PhysicsValidationTargetAvailabilityProfile[key];
    If[availability["ExpectedStatus"] === "NotAvailableYet" &&
        !TrueQ[OptionValue["EvaluateUnavailableRoutes"]],
      Return[
        <|
          "Key" -> key,
          "Component" -> CanonicalAntennaComponentName[component],
          "SupportedMasslessReleaseRoute" -> supportQ,
          "ValidationInput" -> <|
            "quarkMass" -> OptionValue[quarkMass],
            "ExpansionOrder" -> expansionOrder,
            "Component" -> CanonicalAntennaComponentName[component]
          |>,
          "ValidationFamily" -> availability["ValidationFamily"],
          "Availability" -> availability["Availability"],
          "ValidationStatus" -> "NotAvailableYet",
          "ExpectedStatus" -> availability["ExpectedStatus"],
          "Note" -> availability["Note"],
          "RouteDiagnosticsSummary" -> <||>,
          "ObservedPoleCoefficients" -> Missing["SkippedUnavailableRoute"],
          "TargetPoleCoefficients" -> Missing["NotAvailable"],
          "ResidualPoleCoefficients" -> Missing["NotAvailable"],
          "ResidualIsZero" -> Missing["NotAvailable"]
        |>
      ]
    ];
    result =
      BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder,
        quarkMass -> OptionValue[quarkMass],
        "ExpansionOrder" -> expansionOrder,
        Component -> component,
        "UseStoredResults" -> OptionValue["UseStoredResults"],
        "StoreResults" -> OptionValue["StoreResults"],
        "RefreshStoredResults" -> OptionValue["RefreshStoredResults"],
        "ResultsCacheRoot" -> OptionValue["ResultsCacheRoot"],
        "ApplyFeynCalcMS" -> OptionValue["ApplyFeynCalcMS"],
        "PaVeEvaluation" -> OptionValue["PaVeEvaluation"],
        "KinematicScale" -> OptionValue["KinematicScale"],
        "NormalizeKinematicScale" -> OptionValue["NormalizeKinematicScale"],
        "LoopMomentum" -> OptionValue["LoopMomentum"],
        "ApplyDimReg" -> OptionValue["ApplyDimReg"],
        "BasisFamily" -> OptionValue["BasisFamily"],
        "BasisRoot" -> OptionValue["BasisRoot"],
        "GenerateMissingBases" -> OptionValue["GenerateMissingBases"],
        "DetailedTimingDiagnostics" -> OptionValue["DetailedTimingDiagnostics"],
        ReturnDiagnostics -> True
      ];
    If[!MatchQ[result, {_, _Association}],
      Return[
        <|
          "Key" -> key,
          "Component" -> CanonicalAntennaComponentName[component],
          "SupportedMasslessReleaseRoute" -> supportQ,
          "ValidationStatus" -> "RouteEvaluationFailed",
          "Result" -> result
        |>
      ]
    ];
    {result, diagnostics} = result;
    If[result === $Failed,
      Return[
        <|
          "Key" -> key,
          "Component" -> CanonicalAntennaComponentName[component],
          "SupportedMasslessReleaseRoute" -> supportQ,
          "ValidationInput" -> <|
            "quarkMass" -> OptionValue[quarkMass],
            "ExpansionOrder" -> expansionOrder,
            "Component" -> CanonicalAntennaComponentName[component]
          |>,
          "ValidationFamily" -> availability["ValidationFamily"],
          "Availability" -> availability["Availability"],
          "ValidationStatus" -> "RouteEvaluationFailed",
          "ExpectedStatus" -> availability["ExpectedStatus"],
          "Note" -> availability["Note"],
          "RouteDiagnosticsSummary" -> IntegratedPoleValidationDiagnosticSummary[
            key, diagnostics],
          "FailureReason" -> Lookup[diagnostics, "Reason",
            Missing["UnknownReason"]],
          "ObservedPoleCoefficients" -> Missing["RouteEvaluationFailed"],
          "TargetPoleCoefficients" -> Missing["NotAvailable"],
          "ResidualPoleCoefficients" -> Missing["NotAvailable"],
          "ResidualIsZero" -> Missing["NotAvailable"]
        |>
      ]
    ];
    integratedValidation =
      BuildIntegratedPoleValidationReport[key, result, diagnostics, component,
        expansionOrder];
    Join[
      <|
        "Key" -> key,
        "Component" -> CanonicalAntennaComponentName[component],
        "SupportedMasslessReleaseRoute" -> supportQ,
        "ValidationInput" -> <|
          "quarkMass" -> OptionValue[quarkMass],
          "ExpansionOrder" -> expansionOrder,
          "Component" -> CanonicalAntennaComponentName[component]
        |>,
        "RouteDiagnosticsSummary" ->
          IntegratedPoleValidationDiagnosticSummary[key, diagnostics]
      |>,
      integratedValidation
    ]
  ];

Options[RunSupportedMasslessPhysicsValidation] =
  Options[AntennaPhysicsValidationReport];

RunSupportedMasslessPhysicsValidation[OptionsPattern[]] :=
  Association[
    "A21" -> AntennaPhysicsValidationReport[A, 2, 1,
      quarkMass -> OptionValue[quarkMass],
      "ExpansionOrder" -> OptionValue["ExpansionOrder"],
      Component -> OptionValue[Component],
      "UseStoredResults" -> OptionValue["UseStoredResults"],
      "StoreResults" -> OptionValue["StoreResults"],
      "RefreshStoredResults" -> OptionValue["RefreshStoredResults"],
      "ResultsCacheRoot" -> OptionValue["ResultsCacheRoot"],
      "ApplyFeynCalcMS" -> OptionValue["ApplyFeynCalcMS"],
      "PaVeEvaluation" -> OptionValue["PaVeEvaluation"],
      "KinematicScale" -> OptionValue["KinematicScale"],
      "NormalizeKinematicScale" -> OptionValue["NormalizeKinematicScale"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "BasisFamily" -> OptionValue["BasisFamily"],
      "BasisRoot" -> OptionValue["BasisRoot"],
      "GenerateMissingBases" -> OptionValue["GenerateMissingBases"],
      "DetailedTimingDiagnostics" -> OptionValue["DetailedTimingDiagnostics"]],
    "A30" -> AntennaPhysicsValidationReport[A, 3, 0,
      quarkMass -> OptionValue[quarkMass],
      "ExpansionOrder" -> OptionValue["ExpansionOrder"],
      Component -> OptionValue[Component],
      "UseStoredResults" -> OptionValue["UseStoredResults"],
      "StoreResults" -> OptionValue["StoreResults"],
      "RefreshStoredResults" -> OptionValue["RefreshStoredResults"],
      "ResultsCacheRoot" -> OptionValue["ResultsCacheRoot"],
      "ApplyFeynCalcMS" -> OptionValue["ApplyFeynCalcMS"],
      "PaVeEvaluation" -> OptionValue["PaVeEvaluation"],
      "KinematicScale" -> OptionValue["KinematicScale"],
      "NormalizeKinematicScale" -> OptionValue["NormalizeKinematicScale"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "BasisFamily" -> OptionValue["BasisFamily"],
      "BasisRoot" -> OptionValue["BasisRoot"],
      "GenerateMissingBases" -> OptionValue["GenerateMissingBases"],
      "DetailedTimingDiagnostics" -> OptionValue["DetailedTimingDiagnostics"]],
    "A31" -> AntennaPhysicsValidationReport[A, 3, 1,
      quarkMass -> OptionValue[quarkMass],
      "ExpansionOrder" -> OptionValue["ExpansionOrder"],
      Component -> OptionValue[Component],
      "UseStoredResults" -> OptionValue["UseStoredResults"],
      "StoreResults" -> OptionValue["StoreResults"],
      "RefreshStoredResults" -> OptionValue["RefreshStoredResults"],
      "ResultsCacheRoot" -> OptionValue["ResultsCacheRoot"],
      "ApplyFeynCalcMS" -> OptionValue["ApplyFeynCalcMS"],
      "PaVeEvaluation" -> OptionValue["PaVeEvaluation"],
      "KinematicScale" -> OptionValue["KinematicScale"],
      "NormalizeKinematicScale" -> OptionValue["NormalizeKinematicScale"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "BasisFamily" -> OptionValue["BasisFamily"],
      "BasisRoot" -> OptionValue["BasisRoot"],
      "GenerateMissingBases" -> OptionValue["GenerateMissingBases"],
      "DetailedTimingDiagnostics" -> OptionValue["DetailedTimingDiagnostics"]],
    "A22" -> AntennaPhysicsValidationReport[A, 2, 2,
      quarkMass -> OptionValue[quarkMass],
      "ExpansionOrder" -> OptionValue["ExpansionOrder"],
      Component -> OptionValue[Component],
      "UseStoredResults" -> OptionValue["UseStoredResults"],
      "StoreResults" -> OptionValue["StoreResults"],
      "RefreshStoredResults" -> OptionValue["RefreshStoredResults"],
      "ResultsCacheRoot" -> OptionValue["ResultsCacheRoot"],
      "ApplyFeynCalcMS" -> OptionValue["ApplyFeynCalcMS"],
      "PaVeEvaluation" -> OptionValue["PaVeEvaluation"],
      "KinematicScale" -> OptionValue["KinematicScale"],
      "NormalizeKinematicScale" -> OptionValue["NormalizeKinematicScale"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "BasisFamily" -> OptionValue["BasisFamily"],
      "BasisRoot" -> OptionValue["BasisRoot"],
      "GenerateMissingBases" -> OptionValue["GenerateMissingBases"],
      "DetailedTimingDiagnostics" -> OptionValue["DetailedTimingDiagnostics"]],
    "A40Leading" -> AntennaPhysicsValidationReport[A, 4, 0,
      quarkMass -> OptionValue[quarkMass],
      "ExpansionOrder" -> OptionValue["ExpansionOrder"],
      Component -> Leading,
      "UseStoredResults" -> OptionValue["UseStoredResults"],
      "StoreResults" -> OptionValue["StoreResults"],
      "RefreshStoredResults" -> OptionValue["RefreshStoredResults"],
      "ResultsCacheRoot" -> OptionValue["ResultsCacheRoot"],
      "ApplyFeynCalcMS" -> OptionValue["ApplyFeynCalcMS"],
      "PaVeEvaluation" -> OptionValue["PaVeEvaluation"],
      "KinematicScale" -> OptionValue["KinematicScale"],
      "NormalizeKinematicScale" -> OptionValue["NormalizeKinematicScale"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "BasisFamily" -> OptionValue["BasisFamily"],
      "BasisRoot" -> OptionValue["BasisRoot"],
      "GenerateMissingBases" -> OptionValue["GenerateMissingBases"],
      "DetailedTimingDiagnostics" -> OptionValue["DetailedTimingDiagnostics"]],
    "B40" -> AntennaPhysicsValidationReport[B, 4, 0,
      quarkMass -> OptionValue[quarkMass],
      "ExpansionOrder" -> OptionValue["ExpansionOrder"],
      Component -> OptionValue[Component],
      "UseStoredResults" -> OptionValue["UseStoredResults"],
      "StoreResults" -> OptionValue["StoreResults"],
      "RefreshStoredResults" -> OptionValue["RefreshStoredResults"],
      "ResultsCacheRoot" -> OptionValue["ResultsCacheRoot"],
      "ApplyFeynCalcMS" -> OptionValue["ApplyFeynCalcMS"],
      "PaVeEvaluation" -> OptionValue["PaVeEvaluation"],
      "KinematicScale" -> OptionValue["KinematicScale"],
      "NormalizeKinematicScale" -> OptionValue["NormalizeKinematicScale"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "BasisFamily" -> OptionValue["BasisFamily"],
      "BasisRoot" -> OptionValue["BasisRoot"],
      "GenerateMissingBases" -> OptionValue["GenerateMissingBases"],
      "DetailedTimingDiagnostics" -> OptionValue["DetailedTimingDiagnostics"]],
    "C40" -> AntennaPhysicsValidationReport[C, 4, 0,
      quarkMass -> OptionValue[quarkMass],
      "ExpansionOrder" -> OptionValue["ExpansionOrder"],
      Component -> OptionValue[Component],
      "UseStoredResults" -> OptionValue["UseStoredResults"],
      "StoreResults" -> OptionValue["StoreResults"],
      "RefreshStoredResults" -> OptionValue["RefreshStoredResults"],
      "ResultsCacheRoot" -> OptionValue["ResultsCacheRoot"],
      "ApplyFeynCalcMS" -> OptionValue["ApplyFeynCalcMS"],
      "PaVeEvaluation" -> OptionValue["PaVeEvaluation"],
      "KinematicScale" -> OptionValue["KinematicScale"],
      "NormalizeKinematicScale" -> OptionValue["NormalizeKinematicScale"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "BasisFamily" -> OptionValue["BasisFamily"],
      "BasisRoot" -> OptionValue["BasisRoot"],
      "GenerateMissingBases" -> OptionValue["GenerateMissingBases"],
      "DetailedTimingDiagnostics" -> OptionValue["DetailedTimingDiagnostics"]]
  ];

PhysicsValidationStatusCounts[report_Association] :=
  Counts[Lookup[Values[report], "ValidationStatus", Missing["UnknownStatus"]]];
