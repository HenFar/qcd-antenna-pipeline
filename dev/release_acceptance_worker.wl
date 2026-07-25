(* One fresh-kernel case of the supported massless release gate.  The shell
   driver starts this file in a separate kernel for every case. *)

repoRoot = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{repoRoot, "AntennaPipeline.wl"}]];

ClearAll[caseLabel, cases, route, runTimed, buildRules, integrationRules,
  validationEvidence, evidenceStatus, validationContract, validationReport,
  validationStatus, comparisonReport, routeAcceptance, rratioAcceptance,
  report, outputPath];

caseLabel = Environment["ANTCALC_ACCEPTANCE_CASE"];

cases = <|
  "A20" -> <|"Key" -> {A, 2, 0}, "Integration" -> False|>,
  "A21" -> <|"Key" -> {A, 2, 1}, "Integration" -> True|>,
  "A30" -> <|"Key" -> {A, 3, 0}, "Integration" -> True|>,
  "A31All" -> <|"Key" -> {A, 3, 1}, "Integration" -> True|>,
  "A22All" -> <|"Key" -> {A, 2, 2}, "Integration" -> True|>,
  "A22Leading" -> <|"Key" -> {A, 2, 2}, "Component" -> Leading,
    "Integration" -> True|>,
  "A22Breve" -> <|"Key" -> {A, 2, 2}, "Component" -> Breve,
    "Integration" -> True|>,
  "A40Leading" -> <|"Key" -> {A, 4, 0}, "Component" -> Leading,
    "Integration" -> True|>,
  "A40Subleading" -> <|"Key" -> {A, 4, 0}, "Component" -> Subleading,
    "Integration" -> True|>,
  "B40" -> <|"Key" -> {B, 4, 0}, "Integration" -> True|>,
  "C40" -> <|"Key" -> {C, 4, 0}, "Integration" -> True|>
  |>;

runTimed[thunk_] := Module[{seconds, value},
  (* Do not wrap a public route in Check[..., $Failed].  Check treats any
     emitted message as a failed computation, even where the route returns a
     valid result and diagnostics (for example the four-parton heavy-route
     advisory).  Public route failures are represented explicitly as $Failed
     and are classified by routeAcceptance below. *)
  {seconds, value} = AbsoluteTiming[Quiet[thunk[]]];
  <|"Seconds" -> N[seconds], "Value" -> value|>
  ];

buildRules[spec_Association] :=
  Join[{UseStoredResults -> False, StoreResults -> False},
    If[KeyExistsQ[spec, "Component"], {Component -> spec["Component"]}, {}]];

integrationRules[spec_Association] :=
  Join[buildRules[spec],
    If[spec["Key"] === {A, 3, 1}, {ExpansionOrder -> -2},
      {ExpansionOrder -> 0}]];

(*
  Evidence is deliberately declared by release case.  A completed route or an
  empty diagnostics association is never evidence of physics correctness.

  ExternalLiterature means that the required Boolean comes from a target with
  a documented literature/convention mapping.  InternalConsistency means that
  the route is checked only against its reduction/reconstruction contract: it
  may be healthy, but it is not eligible for a validated release pass.
*)
validationContract = <|
  "A20" -> <|"Tier" -> "ExternalLiterature",
    "Scope" -> "PublicBuild",
    "Required" -> {"ExactMatchQ"}|>,
  "A21" -> <|"Tier" -> "ExternalLiterature",
    "Scope" -> "PublicBuildAndIntegratedOutput",
    "Required" -> {"ExactMatchQ", "IntegratedResidualIsZero"}|>,
  "A30" -> <|"Tier" -> "ExternalLiterature",
    "Scope" -> "PublicBuildAndIntegratedOutput",
    "Required" -> {"ExactMatchQ", "IntegratedResidualIsZero"}|>,
  "A40Leading" -> <|"Tier" -> "ExternalLiterature",
    "Scope" -> "PublicBuild;IntegrationComposition",
    "Required" -> {"A40ExactMatchQ", "tA40ExactMatchQ"}|>,
  "A40Subleading" -> <|"Tier" -> "ExternalLiterature",
    "Scope" -> "PublicBuild;IntegrationComposition",
    "Required" -> {"A40ExactMatchQ", "tA40ExactMatchQ"}|>,
  "B40" -> <|"Tier" -> "ExternalLiterature",
    "Scope" -> "PublicBuild;IntegrationComposition",
    "Required" -> {"ExactMatchQ"}|>,
  "C40" -> <|"Tier" -> "ExternalLiterature",
    "Scope" -> "PublicBuild;IntegrationComposition",
    "Required" -> {"ExactMatchQ"}|>,
  "A31All" -> <|"Tier" -> "InternalConsistency",
    "Scope" -> "IntegratedTTermAndOutput",
    "Required" -> {"TTermResidualsAreZero",
      "IntegratedAntennaResidualsAreZero"}|>,
  "A22All" -> <|"Tier" -> "InternalConsistency",
    "Scope" -> "IntegratedTTermAndOutput",
    "Required" -> {"TTermResidualsAreZero",
      "IntegratedAntennaResidualsAreZero"}|>,
  "A22Leading" -> <|"Tier" -> "InternalConsistency",
    "Scope" -> "IntegratedTTermAndOutput",
    "Required" -> {"TTermResidualsAreZero",
      "IntegratedAntennaResidualsAreZero"}|>,
  "A22Breve" -> <|"Tier" -> "InternalConsistency",
    "Scope" -> "IntegratedTTermAndOutput",
    "Required" -> {"TTermResidualIsZero",
      "IntegratedAntennaResidualIsZero"}|>
  |>;

validationEvidence[diagnostics_, key_String] :=
  (* Associations do not reliably expose their internal Rule expressions to
     a generic Cases[..., Rule[...], Infinity] traversal. Match every nested
     association itself and perform the key lookup there. *)
  Cases[diagnostics,
    association_?AssociationQ :> Lookup[association, key, Nothing],
    {0, Infinity}
  ];

evidenceStatus[values_List] := Which[
  MemberQ[values, False], "Fail",
  MemberQ[values, True], "Pass",
  True, "Missing"
  ];

validationReport[case_String, diagnostics_] :=
  Module[{contract, required, observed, statuses},
    contract = Lookup[validationContract, case,
      <|"Tier" -> "NoDeclaredEvidence", "Scope" -> "None",
        "Required" -> {}|>];
    required = contract["Required"];
    observed = AssociationMap[validationEvidence[diagnostics, #] &, required];
    statuses = AssociationMap[evidenceStatus[observed[#]] &, required];
    <|"Tier" -> contract["Tier"], "Scope" -> contract["Scope"],
      "Required" -> required,
      "Observed" -> observed, "Checks" -> statuses|>
  ];

validationStatus[validation_Association] := Module[{checks, tier},
  checks = Values[validation["Checks"]];
  tier = validation["Tier"];
  Which[
    MemberQ[checks, "Fail"], "Failed",
    MemberQ[checks, "Missing"], "Unvalidated",
    tier === "ExternalLiterature", "Validated",
    tier === "InternalConsistency", "Unvalidated",
    True, "Unvalidated"
  ]
  ];

comparisonReport[left_, right_] :=
  If[SameQ[left, right],
    <|"Method" -> "ExactSameQ", "Passed" -> True|>,
    <|"Method" -> "ExactSameQ", "Passed" -> False|>
  ];

routeAcceptance[spec_Association] :=
  Module[{key, build, integrableBuild, directIntegration, oneShot, buildValue,
     buildDiagnostics, object, directValue, directDiagnostics, oneShotValue,
     oneShotDiagnostics, integrationQ, validation, status, comparison,
     structuralPassQ, executionPassQ},
    key = spec["Key"];
    integrationQ = TrueQ[spec["Integration"]];
    build = runTimed[Function[
      BuildAntenna @@ Join[key, {ReturnDiagnostics -> True,
        RunPaperCheck -> True}, buildRules[spec]]]];
    If[MatchQ[build["Value"], {_, _Association}],
      {buildValue, buildDiagnostics} = build["Value"],
      buildValue = build["Value"]; buildDiagnostics = <||>
    ];
    If[!integrationQ,
      validation = validationReport[caseLabel, buildDiagnostics];
      status = If[buildValue === $Failed, "Failed", validationStatus[validation]];
      Return[<|
        "Case" -> caseLabel, "Key" -> ToString[key, InputForm],
        "Status" -> status,
        "Build" -> <|"Seconds" -> build["Seconds"], "Succeeded" -> buildValue =!= $Failed|>,
        "Validation" -> validation,
        "Comparison" -> <|"Method" -> "NotApplicable", "Passed" -> True|>
        |>]
    ];
    integrableBuild = runTimed[Function[
      BuildAntenna @@ Join[key, {IntegrableForm -> True,
        ReturnDiagnostics -> True}, buildRules[spec]]]];
    If[MatchQ[integrableBuild["Value"], {_, _Association}],
      object = First[integrableBuild["Value"]], object = $Failed
    ];
    directIntegration = runTimed[Function[
      If[object === $Failed, $Failed,
        IntegrateAntenna[object, ReturnDiagnostics -> True,
          Sequence @@ integrationRules[spec]]]]];
    If[ListQ[object] && ListQ[directIntegration["Value"]] &&
        And @@ (MatchQ[#, {_, _Association}]& /@ directIntegration["Value"]),
      directValue = First /@ directIntegration["Value"];
      directDiagnostics = <|"ComponentDiagnostics" -> Last /@ directIntegration["Value"]|>,
      If[MatchQ[directIntegration["Value"], {_, _Association}],
      {directValue, directDiagnostics} = directIntegration["Value"],
      directValue = directIntegration["Value"]; directDiagnostics = <||>
      ]
    ];
    oneShot = runTimed[Function[
      BuildAndIntegrateAntenna @@ Join[key, {ReturnDiagnostics -> True},
        integrationRules[spec]]]];
    If[MatchQ[oneShot["Value"], {_, _Association}],
      {oneShotValue, oneShotDiagnostics} = oneShot["Value"],
      oneShotValue = oneShot["Value"]; oneShotDiagnostics = <||>
    ];
    comparison = comparisonReport[directValue, oneShotValue];
    structuralPassQ = buildValue =!= $Failed && object =!= $Failed &&
      directValue =!= $Failed && oneShotValue =!= $Failed &&
      TrueQ[comparison["Passed"]];
    validation = validationReport[caseLabel,
      {buildDiagnostics, directDiagnostics, oneShotDiagnostics}];
    executionPassQ = structuralPassQ && validationStatus[validation] =!= "Failed";
    status = Which[
      !structuralPassQ, "Failed",
      validationStatus[validation] === "Failed", "Failed",
      validationStatus[validation] === "Validated", "Validated",
      True, "Unvalidated"
      ];
    <|
      "Case" -> caseLabel, "Key" -> ToString[key, InputForm],
      "Component" -> ToString[Lookup[spec, "Component", All], InputForm],
      "Status" -> status,
      "ExecutionSucceeded" -> executionPassQ,
      "Build" -> <|"Seconds" -> build["Seconds"], "Succeeded" -> buildValue =!= $Failed|>,
      "IntegrableBuild" -> <|"Seconds" -> integrableBuild["Seconds"], "Succeeded" -> object =!= $Failed|>,
      "DirectIntegration" -> <|"Seconds" -> directIntegration["Seconds"], "Succeeded" -> directValue =!= $Failed|>,
      "OneShot" -> <|"Seconds" -> oneShot["Seconds"], "Succeeded" -> oneShotValue =!= $Failed|>,
      "Comparison" -> comparison,
      "Validation" -> validation
      |>
  ];

rratioAcceptance[order_] :=
  Module[{call, result, diagnostics, passed, referenceAgreement, checkStatus,
    validation, status},
    If[order === NNLO,
      call = runTimed[Function[
        BuildRRatioPhysicsValidationReport[
          "UseStoredResults" -> False,
          "StoreResults" -> False]]];
      result = call["Value"];
      passed = AssociationQ[result] &&
        Lookup[result, "ValidationStatus", "Fail"] === "Pass";
      validation = <|"Tier" -> "ExternalLiterature",
        "Scope" -> "RawLaurentPoleAndFiniteOutput",
        "Required" -> {"RawLaurentPoleAndFiniteTarget"},
        "Observed" -> <|"RawLaurentPoleAndFiniteTarget" -> {passed}|>,
        "Checks" -> <|"RawLaurentPoleAndFiniteTarget" ->
          If[passed, "Pass", "Fail"]|>|>;
      Return[<|"Case" -> caseLabel, "Key" -> "BuildRRatio[SMQCD]",
        "RequestedOrder" -> "NNLO",
        "Status" -> If[passed, "Validated", "Failed"],
        "BuildRRatio" -> <|"Seconds" -> call["Seconds"], "Succeeded" -> passed|>,
        "Comparison" -> <|"Method" -> "RawLaurentPoleAndFiniteTarget",
          "Passed" -> passed|>,
        "Validation" -> validation,
        "ValidationStatus" -> ToString[Lookup[result, "ValidationStatus",
          Missing["NotAvailable"]], InputForm]|>]
    ];
    call = runTimed[Function[
      BuildRRatio[SMQCD, quarkMass -> 0, maxOrder -> order,
        ReturnDiagnostics -> True, UseStoredResults -> False,
        StoreResults -> False]]];
    If[MatchQ[call["Value"], {_, _Association}],
      {result, diagnostics} = call["Value"], result = call["Value"]; diagnostics = <||>
    ];
    referenceAgreement = Lookup[diagnostics, "ReferenceAgreementQ",
      Missing["NotReported"]];
    passed = result =!= $Failed && TrueQ[referenceAgreement];
    checkStatus = Which[
      TrueQ[referenceAgreement], "Pass",
      referenceAgreement === False, "Fail",
      True, "Missing"
    ];
    validation = <|"Tier" -> "ExternalLiterature",
      "Scope" -> "ComputedFiniteCoefficient",
      "Required" -> {"ReferenceFiniteTargetAgreementQ"},
      "Observed" -> <|"ReferenceFiniteTargetAgreementQ" ->
        {referenceAgreement}|>,
      "Checks" -> <|"ReferenceFiniteTargetAgreementQ" -> checkStatus|>|>;
    status = If[result === $Failed, "Failed", validationStatus[validation]];
    <|"Case" -> caseLabel, "Key" -> "BuildRRatio[SMQCD]",
      "RequestedOrder" -> ToString[order, InputForm],
      "Status" -> status,
      "BuildRRatio" -> <|"Seconds" -> call["Seconds"], "Succeeded" -> result =!= $Failed|>,
      "IncludedIngredients" -> ToString[Lookup[diagnostics, "IncludedIngredients", Missing["NotAvailable"]], InputForm],
      "Comparison" -> <|"Method" -> "ComputedFiniteCoefficientVsReferenceTarget",
        "Passed" -> passed|>,
      "Validation" -> validation
      |>
  ];

report = Which[
  KeyExistsQ[cases, caseLabel], routeAcceptance[cases[caseLabel]],
  caseLabel === "RRatioLO", rratioAcceptance[LO],
  caseLabel === "RRatioNLO", rratioAcceptance[NLO],
  caseLabel === "RRatioNNLO", rratioAcceptance[NNLO],
  True, <|"Case" -> caseLabel, "Status" -> "Failed",
    "Reason" -> "UnknownAcceptanceCase"|>
  ];

report = Join[<|"GeneratedAt" -> DateString[{"ISODate", "T", "Time"}],
  "FreshKernel" -> True, "UseStoredResults" -> False,
  "StoreResults" -> False|>, report];

outputPath = Environment["ANTCALC_ACCEPTANCE_OUTPUT"];
If[StringQ[outputPath] && StringLength[StringTrim[outputPath]] > 0,
  Export[outputPath, report, "RawJSON"]
];
Print[ExportString[report, "RawJSON"]];
Exit[Switch[report["Status"],
  "Validated", 0,
  "Unvalidated", 3,
  _, 1
  ]];
