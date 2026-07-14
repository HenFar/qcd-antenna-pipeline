(* ::Section:: *)
(* Amplitude-level Ward-identity validation *)

(* This module consumes an unsquared FeynCalc amplitude before any spin or
   polarization sum. It therefore tests the Ward replacement itself, not a
   property inferred from an extracted or integrated antenna. *)

VerifyWardIdentity::usage =
  "VerifyWardIdentity[] prints the verified massless tree-level Ward-validation suite. VerifyWardIdentity[type, numFinalParticles, loopOrder] prints the amplitude-level result for one route; use ReturnDiagnostics -> True to obtain its structured association.";

GluonLeg::usage =
  "GluonLeg is an option for VerifyWardIdentity that selects All, one external-gluon leg number, or a list of external-gluon leg numbers.";

Options[VerifyWardIdentity] = {GluonLeg -> All, ReturnDiagnostics -> False};

WardIdentityMomentumForLeg[leg_Integer] :=
  Symbol["k" <> ToString[leg]];

WardIdentitySelectedLegs[selection_, availableLegs_List] :=
  Module[{requested},
    requested = Replace[selection, {
        All -> availableLegs,
        leg_Integer :> {leg},
        legs_List :> DeleteDuplicates[legs],
        _ :> $Failed
      }];
    If[ListQ[requested] && VectorQ[requested, IntegerQ] &&
        SubsetQ[availableLegs, requested],
      requested,
      $Failed
    ]
  ];

WardIdentityPolarizationCount[expression_, momentum_] :=
  Count[
    expression,
    HoldPattern[Momentum[Polarization[momentum, ___], ___]],
    Infinity
  ];

WardIdentityReplacePolarization[expression_, momentum_] :=
  expression /. HoldPattern[Momentum[Polarization[momentum, ___], dimension___]] :>
    Momentum[momentum, dimension];

WardIdentityCanonicalizeKinematics[expression_, numFinalParticles_Integer] :=
  Switch[numFinalParticles,
    3,
      expression /. s123 -> s12 + s13 + s23
    ,
    4,
      expression /. {
        s123 -> s12 + s13 + s23,
        s124 -> s12 + s14 + s24,
        s134 -> s13 + s14 + s34,
        s234 -> s23 + s24 + s34
      }
    ,
    _,
      expression
  ];

WardIdentityApplyExternalTransversality[expression_, gluonLegs_List] :=
  Fold[
    Function[{current, leg},
      With[{momentum = WardIdentityMomentumForLeg[leg]},
        current /. HoldPattern[Polarization[momentum, phase_]] :>
          Polarization[momentum, phase, Transversality -> True]
      ]
    ],
    expression,
    gluonLegs
  ];

WardIdentitySimplifyResidual[expression_, numFinalParticles_Integer,
   physicalGluonLegs_List] :=
  Quiet[
    Check[
      TimeConstrained[
        expression // Contract // DiracSimplify //
          SUNSimplify[#, Explicit -> True, SUNNToCACF -> False]& //
          Calc // ApplyFeynCalcRules[#, numFinalParticles]& //
          WardIdentityCanonicalizeKinematics[#, numFinalParticles]& //
          WardIdentityApplyExternalTransversality[#, physicalGluonLegs]& //
          Contract // DiracSimplify[#, DiracOrder -> True]& //
          SUNSimplify[#, Explicit -> True, SUNNToCACF -> False]& //
          WardIdentityApplyExternalTransversality[#, physicalGluonLegs]& //
          Simplify,
        120,
        $Aborted
      ],
      $Failed
    ]
  ];

WardIdentityLegReport[amplitude_, numFinalParticles_Integer, leg_Integer,
   physicalGluonLegs_List] :=
  Module[{momentum, polarizationCount, replacedAmplitude, residual},
    momentum = WardIdentityMomentumForLeg[leg];
    polarizationCount = WardIdentityPolarizationCount[amplitude, momentum];
    If[polarizationCount === 0,
      Return[
        <|
          "Leg" -> leg,
          "Momentum" -> momentum,
          "ValidationStatus" -> "RouteEvaluationFailed",
          "FailureReason" -> "SelectedPolarizationNotFound",
          "PolarizationOccurrenceCount" -> 0
        |>
      ]
    ];
    KinematicRules[numFinalParticles];
    replacedAmplitude = WardIdentityReplacePolarization[amplitude, momentum];
    (* A one-leg Ward test keeps all other external gluons physical. The cached
       source amplitude does not carry FCFAConvert's transversality annotation,
       so enforce k . epsilon(k) = 0 explicitly at this validation boundary. *)
    replacedAmplitude = WardIdentityApplyExternalTransversality[
      replacedAmplitude,
      DeleteCases[physicalGluonLegs, leg]
    ];
    residual = WardIdentitySimplifyResidual[
      replacedAmplitude,
      numFinalParticles,
      DeleteCases[physicalGluonLegs, leg]
    ];
    <|
      "Leg" -> leg,
      "Momentum" -> momentum,
      "PolarizationOccurrenceCount" -> polarizationCount,
      "SimplificationStatus" -> Which[
        residual === $Aborted, "TimedOut",
        residual === $Failed, "EvaluationFailed",
        True, "Completed"
      ],
      "Residual" -> residual,
      "PassQ" -> TrueQ[residual === 0],
      "ValidationStatus" -> Which[
        residual === 0, "Pass",
        MemberQ[{$Aborted, $Failed}, residual], "RouteEvaluationFailed",
        True, "Fail"
      ]
    |>
  ];

WardIdentityStatusLabel[status_] :=
  Switch[status,
    "Pass", "PASS",
    "Fail", "FAIL",
    "RouteEvaluationFailed", "ERROR",
    "NotApplicable", "N/A",
    "NotAvailableYet", "PENDING",
    _, ToUpperCase[ToString[status]]
  ];

WardIdentityResidualSummary[residual_] :=
  Which[
    residual === 0, "0",
    residual === $Aborted, "timed out",
    residual === $Failed, "evaluation failed",
    True, "non-zero (" <> ToString[LeafCount[residual]] <> " leaves)"
  ];

WardIdentityPrintReport[routeName_String, report_Association] :=
  Module[{legReports, status},
    legReports = Lookup[report, "LegReports", <||>];
    status = Lookup[report, "ValidationStatus", "RouteEvaluationFailed"];
    If[AssociationQ[legReports] && Length[legReports] > 0,
      KeyValueMap[
        Function[{leg, legReport},
          Print[
            "  " <> routeName <> "   k" <> ToString[leg] <> "   " <>
              WardIdentityStatusLabel[
                Lookup[legReport, "ValidationStatus", status]] <>
              "   residual: " <>
              WardIdentityResidualSummary[
                Lookup[legReport, "Residual", $Failed]]
          ]
        ],
        legReports
      ],
      Print["  " <> routeName <> "        " <> WardIdentityStatusLabel[status]]
    ]
  ];

WardIdentityPrintSuite[reports_Association] :=
  Module[{allLegReports, passCount, totalCount, overallPassQ},
    Print["=== WARD-IDENTITY VALIDATION ==="];
    Print["  Route  Leg  Status  Residual"];
    KeyValueMap[WardIdentityPrintReport, reports];
    allLegReports = Flatten[
      Values /@ Lookup[Values[reports], "LegReports", <||>]
    ];
    passCount = Count[
      Lookup[allLegReports, "ValidationStatus", "Unknown"],
      "Pass"
    ];
    totalCount = Length[allLegReports];
    overallPassQ = AllTrue[
      Values[reports],
      Lookup[#, "ValidationStatus", "Failed"] === "Pass" &
    ];
    Print["----------------------------------------"];
    Print[
      "Overall: " <> If[overallPassQ, "PASS", "FAIL"] <> " (" <>
        ToString[passCount] <> "/" <> ToString[totalCount] <>
        " gluon checks passed)"
    ];
  ];

WardIdentityRouteReport[type_Symbol, numFinalParticles_Integer,
   loopOrder_Integer, OptionsPattern[{GluonLeg -> All}]] :=
  Module[{key, profile, availableLegs, selectedLegs, amplitude, legReports,
     statuses, overallStatus},
    key = {type, numFinalParticles, loopOrder};
    profile = AntennaWardIdentityProfile[key];
    availableLegs = Lookup[profile, "ExternalGluonLegs", {}];
    Which[
      profile["Availability"] === "NotApplicable",
        Return[
          <|
            "Key" -> key,
            "ValidationFamily" -> "WardIdentity",
            "Availability" -> "NotApplicable",
            "ValidationStatus" -> "NotApplicable",
            "Note" -> "This initial Ward validator applies only to massless A-type routes with external gluons."
          |>
        ]
      ,
      profile["Availability"] === "NotAvailableYet",
        Return[
          <|
            "Key" -> key,
            "ValidationFamily" -> "WardIdentity",
            "Availability" -> "NotAvailableYet",
            "ValidationStatus" -> "NotAvailableYet",
            "Note" -> Lookup[profile, "Note", "This route is outside the initial Ward-validation scope."]
          |>
        ]
    ];
    selectedLegs = WardIdentitySelectedLegs[OptionValue[GluonLeg], availableLegs];
    If[selectedLegs === $Failed,
      Return[
        <|
          "Key" -> key,
          "ValidationFamily" -> "WardIdentity",
          "Availability" -> "Applicable",
          "ValidationStatus" -> "RouteEvaluationFailed",
          "FailureReason" -> "InvalidGluonLegSelection",
          "RequestedGluonLeg" -> OptionValue[GluonLeg],
          "AvailableGluonLegs" -> availableLegs
        |>
      ]
    ];
    amplitude = Quiet[Check[AntennaAmplitude[key], $Failed]];
    If[amplitude === $Failed,
      Return[
        <|
          "Key" -> key,
          "ValidationFamily" -> "WardIdentity",
          "Availability" -> "Applicable",
          "ValidationStatus" -> "RouteEvaluationFailed",
          "FailureReason" -> "AmplitudeGenerationFailed",
          "CheckedGluonLegs" -> selectedLegs
        |>
      ]
    ];
    legReports = Association @ Table[
      ToString[leg] -> WardIdentityLegReport[
        amplitude,
        numFinalParticles,
        leg,
        availableLegs
      ],
      {leg, selectedLegs}
    ];
    statuses = Lookup[Values[legReports], "ValidationStatus", "RouteEvaluationFailed"];
    overallStatus = Which[
      AllTrue[statuses, # === "Pass" &], "Pass",
      MemberQ[statuses, "RouteEvaluationFailed"], "RouteEvaluationFailed",
      True, "Fail"
    ];
    <|
      "Key" -> key,
      "ValidationFamily" -> "WardIdentity",
      "Availability" -> "Applicable",
      "ValidationStatus" -> overallStatus,
      "ExpectedStatus" -> "PassExpected",
      "CheckedGluonLegs" -> selectedLegs,
      "LegReports" -> legReports,
      "AmplitudeLeafCount" -> LeafCount[amplitude],
      "Note" -> "Each selected external-gluon polarization is replaced by its own momentum on the unsquared massless tree amplitude."
    |>
  ];

WardIdentitySuiteReport[] :=
  <|
    "A30" -> WardIdentityRouteReport[A, 3, 0],
    "A40" -> WardIdentityRouteReport[A, 4, 0]
  |>;

VerifyWardIdentity[type_Symbol, numFinalParticles_Integer, loopOrder_Integer,
   OptionsPattern[]] :=
  Module[{report, routeName},
    report = WardIdentityRouteReport[
      type,
      numFinalParticles,
      loopOrder,
      GluonLeg -> OptionValue[GluonLeg]
    ];
    If[TrueQ[OptionValue[ReturnDiagnostics]],
      report,
      routeName = ToString[type] <> ToString[numFinalParticles] <>
        ToString[loopOrder];
      Print["=== WARD-IDENTITY VALIDATION ==="];
      Print["  Route  Leg  Status  Residual"];
      WardIdentityPrintReport[routeName, report];
      Null
    ]
  ];

VerifyWardIdentity[OptionsPattern[]] :=
  Module[{reports = WardIdentitySuiteReport[]},
    If[TrueQ[OptionValue[ReturnDiagnostics]],
      reports,
      WardIdentityPrintSuite[reports];
      Null
    ]
  ];
