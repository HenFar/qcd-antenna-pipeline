(*************************************************)

(*
  Integration router placeholder.
  The public integration layer should eventually mirror BuildAntenna:
  user-facing calls dispatch through antenna/integration profiles while the
  backend-specific PaVe or IBP details remain hidden inside this router.
*)

(*************************************************)

Options[IntegrateAntenna] = {ApplyFeynCalcMS -> True, quarkMass -> 0,
   PaVeEvaluation -> "PaXEvaluate",
   ExpansionOrder -> Automatic, KinematicScale -> q2, NormalizeKinematicScale ->
    True, ReturnDiagnostics -> False, LoopMomentum -> l, ApplyDimReg ->
    True, BasisFamily -> Automatic, BasisRoot -> Automatic,
   GenerateMissingBases -> False,
   ReturnTTerms -> False, Component -> All, Contribution -> All,
   IntermediateSteps -> {}, PrintIntermediateSteps -> False};

IntegrateAntenna::heavy =
  "This route uses a heavy integration backend and may take a long time: `1`.";

IntegratedResidualListZeroQ[residuals_] :=
  ListQ[residuals] && And @@ (TrueQ[# === 0]& /@ residuals);

CollectIntegrationIntermediateSteps[antenna_, rawIntegrated_, tTerms_,
   finalIntegrated_, selectedIntegrated_, backendDiagnostics_, diagnostics_,
   steps_List] :=
  Module[{collected = <||>},
    If[RequestedIntermediateStepQ[steps, "InputAntenna"],
      collected = Join[collected, <|"InputAntenna" -> antenna|>]
    ];
    If[RequestedIntermediateStepQ[steps, "RawIntegrated"],
      collected = Join[collected, <|"RawIntegrated" -> rawIntegrated|>]
    ];
    If[RequestedIntermediateStepQ[steps, "TTerms"],
      collected = Join[collected, <|"TTerms" -> tTerms|>]
    ];
    If[RequestedIntermediateStepQ[steps, "FinalIntegrated"],
      collected = Join[collected, <|"FinalIntegrated" -> finalIntegrated|>]
    ];
    If[RequestedIntermediateStepQ[steps, "SelectedIntegrated"],
      collected = Join[collected, <|"SelectedIntegrated" -> selectedIntegrated|>]
    ];
    If[RequestedIntermediateStepQ[steps, "BackendDiagnostics"],
      collected = Join[collected, <|"BackendDiagnostics" -> backendDiagnostics|>]
    ];
    If[RequestedIntermediateStepQ[steps, "IntegrationDiagnostics"],
      collected = Join[collected, <|"IntegrationDiagnostics" -> diagnostics|>]
    ];
    collected
  ];

If[!ValueQ[$AntennaPipelineHeavyRouteNotices],
  $AntennaPipelineHeavyRouteNotices = <||>;
];

HeavyIntegrationRouteQ[key_, component_, contribution_] :=
  Module[{componentName, contributionName},
    componentName = CanonicalAntennaComponentName[component];
    contributionName = CanonicalAntennaComponentName[contribution];
    componentName === "All" &&
      MemberQ[{{A, 3, 1}, {A, 2, 2}, {A, 4, 0}, {B, 4, 0}, {C, 4, 0}},
        key] &&
      MemberQ[{"All", "TwoLoopTree", "OneLoopSelf"}, contributionName]
  ];

HeavyIntegrationRouteLabel[key_, component_, contribution_] :=
  StringJoin[
    ToString[key, InputForm],
    " with Component -> ",
    CanonicalAntennaComponentName[component],
    ", Contribution -> ",
    CanonicalAntennaComponentName[contribution]
  ];

MaybeWarnHeavyIntegrationRoute[key_, component_, contribution_] :=
  Module[{noticeKey, label},
    If[!HeavyIntegrationRouteQ[key, component, contribution],
      Return[Null]
    ];
    noticeKey = StringJoin[
      ToString[key, InputForm],
      "::",
      CanonicalAntennaComponentName[component],
      "::",
      CanonicalAntennaComponentName[contribution]
    ];
    If[TrueQ[Lookup[$AntennaPipelineHeavyRouteNotices, noticeKey, False]],
      Return[Null]
    ];
    label = HeavyIntegrationRouteLabel[key, component, contribution];
    Message[IntegrateAntenna::heavy, label];
    AssociateTo[$AntennaPipelineHeavyRouteNotices, noticeKey -> True];
  ];

A22CombineIntegratedResults[treeResult_List, breveResult_] :=
  Join[treeResult, {breveResult}];

A22CombineIntegratedComponentDiagnostics[treeComponentDiags_Association,
   breveDiag_Association, finalIntegrated_List, selectedComponent_,
   returnTTerms_] :=
  Module[{treeOrder, rawIntegrated, tTerms, tResiduals, antennaResiduals,
     expansionOrder},
    treeOrder = {"Leading", "Subleading", "Nf"};
    expansionOrder =
      Lookup[Lookup[treeComponentDiags, "Leading", <||>], "ExpansionOrder",
        Lookup[breveDiag, "ExpansionOrder", 0]];
    rawIntegrated =
      Join[
        Lookup[Lookup[treeComponentDiags, #, <||>], "RawIntegrated",
          Missing["NotAvailable"]]& /@ treeOrder,
        {Lookup[breveDiag, "RawIntegrated", Missing["NotAvailable"]]}
      ];
    tTerms =
      Join[
        Lookup[Lookup[treeComponentDiags, #, <||>], "TTerms",
          Missing["NotAvailable"]]& /@ treeOrder,
        {Lookup[breveDiag, "TTerms", Missing["NotAvailable"]]}
      ];
    tResiduals = A22TTermResiduals[tTerms, expansionOrder];
    antennaResiduals =
      If[TrueQ[returnTTerms],
        Missing["NotAvailable"]
        ,
        A22IntegratedResiduals[finalIntegrated, expansionOrder]
      ];
    <|"CombinedA22ContributionQ" -> True,
      "Contribution" -> "All",
      "SelectedComponent" -> selectedComponent,
      "BuildComponent" -> All,
      "RawIntegrated" -> rawIntegrated,
      "TTerms" -> tTerms,
      "TTermResiduals" -> tResiduals,
      "TTermResidualsAreZero" -> IntegratedResidualListZeroQ[tResiduals],
      "IntegratedAntennaResiduals" -> antennaResiduals,
      "IntegratedAntennaResidualsAreZero" ->
        IntegratedResidualListZeroQ[antennaResiduals],
      "FinalAntennaExtractionImplemented" -> True,
      "ComponentDiagnostics" -> <|"TwoLoopTree" -> treeComponentDiags,
        "OneLoopSelf" -> breveDiag|>|>
  ];

IntegrateAntenna[antenna_, integrationMethod:(PaVe | IBP),
   OptionsPattern[]] :=
  Module[{ApplyFeynCalcOpt, quarkMassOpt, profile, output,
     intermediateSteps, collectedSteps},
    ApplyFeynCalcOpt = OptionValue["ApplyFeynCalcMS"];
    quarkMassOpt = OptionValue["quarkMass"];
    intermediateSteps = NormalizeIntermediateSteps[OptionValue[
      "IntermediateSteps"]];
    profile = <|"DefaultBackend" -> integrationMethod, "PaVeFamily" ->
       "MasslessTwoPartonVertex", "KinematicScale" -> OptionValue[
        "KinematicScale"], "ExpansionOrder" -> If[OptionValue[
        "ExpansionOrder"] === Automatic, 2, OptionValue["ExpansionOrder"]]
        |>;
    output =
      Switch[integrationMethod,
        PaVe,
          IntegrateViaPaVe[antenna, profile, True,
            ApplyFeynCalcOpt, quarkMassOpt, PaVeEvaluation -> OptionValue[
             "PaVeEvaluation"], ExpansionOrder -> profile["ExpansionOrder"],
            KinematicScale -> OptionValue["KinematicScale"],
            NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"
             ], LoopMomentum -> OptionValue["LoopMomentum"], ApplyDimReg ->
             OptionValue["ApplyDimReg"]]
        ,
        IBP,
          IntegrateViaIBP[antenna, ExpansionOrder -> profile[
            "ExpansionOrder"], BasisFamily -> OptionValue["BasisFamily"],
            BasisRoot -> OptionValue["BasisRoot"], GenerateMissingBases ->
             OptionValue["GenerateMissingBases"], ReturnDiagnostics ->
             OptionValue["ReturnDiagnostics"]]
        ,
        _,
          Print["Unsupported integration backend: ", integrationMethod,
            ". Aborting..."];
          $Failed
      ];
    output = SelectAntennaComponent[output, Missing["DirectIntegratedObject"],
      OptionValue["Component"]];
    collectedSteps = CollectIntegrationIntermediateSteps[antenna,
      Missing["NotAvailable"], Missing["NotAvailable"], output, output,
      <||>, <||>, intermediateSteps];
    If[TrueQ[OptionValue["PrintIntermediateSteps"]] && Length[
        collectedSteps] > 0,
      PrintIntermediateStepsAssociation[collectedSteps]
    ];
    If[Length[collectedSteps] > 0,
      {output, collectedSteps}
      ,
      output
    ]
  ];

Options[BuildAndIntegrateAntenna] =
  Options[IntegrateAntenna];

IntegrateAntenna[obj_AntennaObject, OptionsPattern[]] :=
  Module[{data, key, profile, contributionInput, contribution,
     componentInput, componentName, storedComponent, backend, antenna,
     diagnostics, output, ibpResult,
     backendDiagnostics = <||>, rawIntegrated, tTerms, finalIntegrated,
     selectedIntegrated, expansionOrder, leadingCall, subleadingCall,
     nfCall, breveCall, leadingResult, subleadingResult, nfResult,
     breveResult, leadingDiag, subleadingDiag, nfDiag, breveDiag,
     treeDiags, intermediateSteps, collectedSteps},
    If[!AntennaObjectQ[obj],
      Print["IntegrateAntenna expected a valid AntennaObject. Aborting..."];
      Return[
        If[OptionValue["ReturnDiagnostics"] === True,
          {$Failed, <|"Failed" -> True,
            "Reason" -> "InvalidAntennaObject"|>}
          ,
          $Failed
        ]
      ]
    ];
    data = AntennaObjectData[obj];
    intermediateSteps = NormalizeIntermediateSteps[OptionValue[
      "IntermediateSteps"]];
    key = Lookup[data, "Key", Missing["UnknownKey"]];
    If[key === Missing["UnknownKey"],
      Print["Antenna object is missing its antenna key. Aborting..."];
      Return[
        If[OptionValue["ReturnDiagnostics"] === True,
          {$Failed, <|"Failed" -> True,
            "Reason" -> "MissingAntennaObjectKey"|>}
          ,
          $Failed
        ]
      ]
    ];
    MaybeWarnHeavyIntegrationRoute[key, Lookup[data, "SelectedComponent", All],
      Lookup[data, "Contribution", All]];
    profile = AntennaIntegrationProfile[key];
    contributionInput =
      If[OptionValue["Contribution"] === All,
        Lookup[data, "Contribution", All]
        ,
        OptionValue["Contribution"]
      ];
    contribution = CanonicalAntennaComponentName[contributionInput];
    componentInput =
      If[OptionValue["Component"] === All,
        Lookup[data, "SelectedComponent", All]
        ,
        OptionValue["Component"]
      ];
    componentName = CanonicalAntennaComponentName[componentInput];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] &&
        contribution === "OneLoopSelf",
      profile = Join[profile, <|"BasisFamily" -> "A22OneLoopSelf",
          "ImplementationStatus" -> "ExperimentalOneLoopSelfOnly"|>]
    ];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] &&
        contribution === "TwoLoopTree",
      profile = Join[profile, <|"BasisFamily" -> "A22TwoLoopTree",
          "ImplementationStatus" -> "ExperimentalTwoLoopTree"|>]
    ];
    expansionOrder =
      If[OptionValue["ExpansionOrder"] === Automatic,
        Lookup[profile, "ExpansionOrder", 0]
        ,
        OptionValue["ExpansionOrder"]
      ];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] &&
        contribution === "All",
      Switch[componentName,
        "Leading" | "Subleading" | "Nf",
          Return[
            IntegrateAntenna[
              AntennaObjectWithSelection[obj, componentInput, TwoLoopTree],
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> OptionValue["ReturnDiagnostics"],
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> All,
              Contribution -> TwoLoopTree]
          ]
        ,
        "Breve",
          Return[
            IntegrateAntenna[
              AntennaObjectWithSelection[obj, Breve, OneLoopSelf],
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> OptionValue["ReturnDiagnostics"],
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> All,
              Contribution -> OneLoopSelf]
          ]
        ,
        "All",
          leadingCall =
            IntegrateAntenna[
              AntennaObjectWithSelection[obj, Leading, TwoLoopTree],
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> True,
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> All,
              Contribution -> TwoLoopTree];
          subleadingCall =
            IntegrateAntenna[
              AntennaObjectWithSelection[obj, Subleading, TwoLoopTree],
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> True,
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> All,
              Contribution -> TwoLoopTree];
          nfCall =
            IntegrateAntenna[
              AntennaObjectWithSelection[obj, Nf, TwoLoopTree],
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> True,
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> All,
              Contribution -> TwoLoopTree];
          breveCall =
            IntegrateAntenna[
              AntennaObjectWithSelection[obj, Breve, OneLoopSelf],
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> True,
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> All,
              Contribution -> OneLoopSelf];
          {leadingResult, leadingDiag} = leadingCall;
          {subleadingResult, subleadingDiag} = subleadingCall;
          {nfResult, nfDiag} = nfCall;
          {breveResult, breveDiag} = breveCall;
          If[MemberQ[{leadingResult, subleadingResult, nfResult, breveResult},
              $Failed],
            Return[
              If[OptionValue["ReturnDiagnostics"] === True,
                {$Failed, <|"Failed" -> True,
                  "Reason" -> "A22CombinedContributionIntegrationFailed",
                  "ComponentDiagnostics" -> <|"TwoLoopTree" -> <|
                      "Leading" -> leadingDiag,
                      "Subleading" -> subleadingDiag,
                      "Nf" -> nfDiag|>,
                    "OneLoopSelf" -> breveDiag|>|>}
                ,
                $Failed
              ]
            ]
          ];
          finalIntegrated = A22CombineIntegratedResults[
            {leadingResult, subleadingResult, nfResult}, breveResult];
          treeDiags = <|"Leading" -> leadingDiag,
            "Subleading" -> subleadingDiag, "Nf" -> nfDiag|>;
          diagnostics = A22CombineIntegratedComponentDiagnostics[
            treeDiags, breveDiag, finalIntegrated, componentInput,
            OptionValue["ReturnTTerms"]];
          Return[
            If[OptionValue["ReturnDiagnostics"] === True,
              {finalIntegrated, diagnostics}
              ,
              finalIntegrated
            ]
          ]
      ]
    ];
    If[Lookup[profile, "ImplementationStatus", "Implemented"] ===
        "ScaffoldOnly",
      diagnostics = <|"Failed" -> True,
        "Reason" -> "IntegratedAntennaNotImplemented",
        "Profile" -> profile, "Contribution" -> contributionInput|>;
      Return[
        If[OptionValue["ReturnDiagnostics"] === True,
          {$Failed, diagnostics}
          ,
          $Failed
        ]
      ]
    ];
    backend = profile["DefaultBackend"];
    storedComponent = Lookup[data, "SelectedComponent", All];
    antenna = Lookup[data, "Antenna", $Failed];
    rawIntegrated =
      Switch[backend,
        PaVe,
          IntegrateViaPaVe[antenna, profile, True, OptionValue[
            "ApplyFeynCalcMS"], OptionValue[
            "quarkMass"], PaVeEvaluation -> OptionValue["PaVeEvaluation"],
            ExpansionOrder -> expansionOrder, KinematicScale -> Lookup[
             profile, "KinematicScale", OptionValue["KinematicScale"]],
            NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"
             ], LoopMomentum -> OptionValue["LoopMomentum"], ApplyDimReg ->
             OptionValue["ApplyDimReg"]]
        ,
        IBP,
          ibpResult =
            IntegrateViaIBP[antenna, NumFinalParticles -> key[[2]],
              NumLoops -> key[[3]], BasisFamily -> If[OptionValue[
                "BasisFamily"] === Automatic, Lookup[profile, "BasisFamily",
                Automatic], OptionValue["BasisFamily"]], BasisRoot ->
               OptionValue["BasisRoot"], GenerateMissingBases -> OptionValue[
                "GenerateMissingBases"], ExpansionOrder -> expansionOrder,
              ReturnDiagnostics -> OptionValue["ReturnDiagnostics"]];
          If[OptionValue["ReturnDiagnostics"] === True,
            backendDiagnostics = ibpResult[[2]];
            ibpResult[[1]]
            ,
            backendDiagnostics = <||>;
            ibpResult
          ]
        ,
        _,
          Print["Unsupported integration backend for antenna ", key, ": ",
             backend, ". Aborting..."];
          $Failed
      ];
    tTerms =
      If[rawIntegrated === $Failed,
        $Failed
        ,
        IntegratedAntennaTTerms[key, rawIntegrated, ExpansionOrder ->
          expansionOrder, Component -> storedComponent]
      ];
    finalIntegrated =
      If[rawIntegrated === $Failed,
        $Failed
        ,
        If[OptionValue["ReturnTTerms"] === True,
          tTerms
          ,
          ExtractIntegratedAntenna[key, tTerms, ExpansionOrder ->
            expansionOrder]
        ]
      ];
    selectedIntegrated =
      SelectAntennaComponent[finalIntegrated, key,
        If[storedComponent === All, componentInput, All]];
    diagnostics = Join[
      IntegratedAntennaDiagnostics[key, antenna, finalIntegrated, profile,
        <|"RawIntegrated" -> rawIntegrated, "TTerms" -> tTerms,
          "ReturnTTerms" -> OptionValue["ReturnTTerms"],
          "ExpansionOrder" -> expansionOrder, "SelectedComponent" ->
           componentInput, "BuildComponent" -> storedComponent|>],
      If[AssociationQ[backendDiagnostics] && Length[backendDiagnostics] >
          0,
        <|"BackendDiagnostics" -> backendDiagnostics|>
        ,
        <||>
      ]
    ];
    collectedSteps = CollectIntegrationIntermediateSteps[antenna,
      rawIntegrated, tTerms, finalIntegrated, selectedIntegrated,
      backendDiagnostics, diagnostics, intermediateSteps];
    If[TrueQ[OptionValue["PrintIntermediateSteps"]] && Length[
        collectedSteps] > 0,
      PrintIntermediateStepsAssociation[collectedSteps]
    ];
    output =
      If[OptionValue["ReturnDiagnostics"] === True,
        {selectedIntegrated, Join[diagnostics, <|"SelectedComponent" ->
            componentInput, "BuildComponent" -> storedComponent,
            "RawIntegrated" -> rawIntegrated, "TTerms" -> tTerms|>,
          If[Length[collectedSteps] > 0,
            <|"IntermediateSteps" -> collectedSteps|>,
            <||>
          ]]}
        ,
        If[Length[collectedSteps] > 0,
          {selectedIntegrated, collectedSteps}
          ,
          selectedIntegrated
        ]
      ];
    output
  ];

BuildAndIntegrateAntenna[type_, numFinalParticles_Integer, loopOrder_Integer,
   OptionsPattern[]] :=
  Module[{key, profile, contribution, componentName, antennaObject,
     buildComponent, selectionComponent,
     diagnostics, expansionOrder,
     leadingCall, subleadingCall, nfCall, breveCall,
     leadingResult, subleadingResult, nfResult, breveResult,
     leadingDiag, subleadingDiag, nfDiag, breveDiag, treeDiags},
    key = {type, numFinalParticles, loopOrder};
    MaybeWarnHeavyIntegrationRoute[key, OptionValue["Component"],
      OptionValue["Contribution"]];
    profile = AntennaIntegrationProfile[key];
    contribution = CanonicalAntennaComponentName[OptionValue[
       "Contribution"]];
    componentName = CanonicalAntennaComponentName[OptionValue["Component"]];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] && contribution === "OneLoopSelf",
      profile = Join[profile, <|"BasisFamily" -> "A22OneLoopSelf",
          "ImplementationStatus" -> "ExperimentalOneLoopSelfOnly"|>]
    ];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] && contribution === "TwoLoopTree",
      profile = Join[profile, <|"BasisFamily" -> "A22TwoLoopTree",
          "ImplementationStatus" -> "ExperimentalTwoLoopTree"|>]
    ];
    expansionOrder =
      If[OptionValue["ExpansionOrder"] === Automatic,
        Lookup[profile, "ExpansionOrder", 0]
        ,
        OptionValue["ExpansionOrder"]
      ];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] &&
        contribution === "All",
      Switch[componentName,
        "Leading" | "Subleading" | "Nf",
          Return[
            BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder,
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> OptionValue["ReturnDiagnostics"],
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> OptionValue["Component"],
              Contribution -> TwoLoopTree]
          ]
        ,
        "Breve",
          Return[
            BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder,
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> OptionValue["ReturnDiagnostics"],
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> Breve,
              Contribution -> OneLoopSelf]
          ]
        ,
        "All",
          leadingCall =
            BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder,
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> True,
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> Leading,
              Contribution -> TwoLoopTree];
          subleadingCall =
            BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder,
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> True,
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> Subleading,
              Contribution -> TwoLoopTree];
          nfCall =
            BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder,
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> True,
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> Nf,
              Contribution -> TwoLoopTree];
          breveCall =
            BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder,
              ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
              quarkMass -> OptionValue["quarkMass"],
              PaVeEvaluation -> OptionValue["PaVeEvaluation"],
              ExpansionOrder -> OptionValue["ExpansionOrder"],
              KinematicScale -> OptionValue["KinematicScale"],
              NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
              ReturnDiagnostics -> True,
              LoopMomentum -> OptionValue["LoopMomentum"],
              ApplyDimReg -> OptionValue["ApplyDimReg"],
              BasisFamily -> OptionValue["BasisFamily"],
              BasisRoot -> OptionValue["BasisRoot"],
              GenerateMissingBases -> OptionValue["GenerateMissingBases"],
              ReturnTTerms -> OptionValue["ReturnTTerms"],
              IntermediateSteps -> OptionValue["IntermediateSteps"],
              PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
              Component -> Breve,
              Contribution -> OneLoopSelf];
          {leadingResult, leadingDiag} = leadingCall;
          {subleadingResult, subleadingDiag} = subleadingCall;
          {nfResult, nfDiag} = nfCall;
          {breveResult, breveDiag} = breveCall;
          If[MemberQ[{leadingResult, subleadingResult, nfResult, breveResult}, $Failed],
            Return[
              If[OptionValue["ReturnDiagnostics"] === True,
                {$Failed, <|"Failed" -> True,
                  "Reason" -> "A22CombinedContributionIntegrationFailed",
                  "ComponentDiagnostics" -> <|"TwoLoopTree" -> <|
                      "Leading" -> leadingDiag,
                      "Subleading" -> subleadingDiag,
                      "Nf" -> nfDiag|>,
                    "OneLoopSelf" -> breveDiag|>|>}
                ,
                $Failed
              ]
            ]
          ];
          finalIntegrated = A22CombineIntegratedResults[
            {leadingResult, subleadingResult, nfResult}, breveResult];
          treeDiags = <|"Leading" -> leadingDiag,
            "Subleading" -> subleadingDiag, "Nf" -> nfDiag|>;
          diagnostics = A22CombineIntegratedComponentDiagnostics[treeDiags, breveDiag,
            finalIntegrated, OptionValue["Component"], OptionValue["ReturnTTerms"]];
          Return[
            If[OptionValue["ReturnDiagnostics"] === True,
              {finalIntegrated, diagnostics}
              ,
              finalIntegrated
            ]
          ]
      ]
    ];
    If[Lookup[profile, "ImplementationStatus", "Implemented"] ===
        "ScaffoldOnly",
      diagnostics = <|"Failed" -> True,
        "Reason" -> "IntegratedAntennaNotImplemented",
        "Profile" -> profile, "Contribution" -> OptionValue[
          "Contribution"]|>;
      Return[
        If[OptionValue["ReturnDiagnostics"] === True,
          {$Failed, diagnostics}
          ,
          $Failed
        ]
      ]
    ];
    buildComponent =
      If[OptionValue["Component"] === All,
        All
        ,
        OptionValue["Component"]
      ];
    selectionComponent =
      If[buildComponent === All,
        OptionValue["Component"]
        ,
        All
      ];
    antennaObject = BuildAntennaObject[type, numFinalParticles, loopOrder,
      ApplyDimReg -> OptionValue["ApplyDimReg"],
      LoopMomentum -> OptionValue["LoopMomentum"],
      Component -> buildComponent, Contribution -> OptionValue[
       "Contribution"]];
    If[antennaObject === $Failed,
      Return[
        If[OptionValue["ReturnDiagnostics"] === True,
          {$Failed, <|"Failed" -> True,
            "Reason" -> "InvalidComponentSelection",
            "SelectedComponent" -> OptionValue["Component"],
            "Contribution" -> OptionValue["Contribution"]|>}
          ,
          $Failed
        ]
      ]
    ];
    IntegrateAntenna[antennaObject,
      ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
      quarkMass -> OptionValue["quarkMass"],
      PaVeEvaluation -> OptionValue["PaVeEvaluation"],
      ExpansionOrder -> OptionValue["ExpansionOrder"],
      KinematicScale -> OptionValue["KinematicScale"],
      NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
      ReturnDiagnostics -> OptionValue["ReturnDiagnostics"],
      LoopMomentum -> OptionValue["LoopMomentum"],
      ApplyDimReg -> OptionValue["ApplyDimReg"],
      BasisFamily -> OptionValue["BasisFamily"],
      BasisRoot -> OptionValue["BasisRoot"],
      GenerateMissingBases -> OptionValue["GenerateMissingBases"],
      ReturnTTerms -> OptionValue["ReturnTTerms"],
      IntermediateSteps -> OptionValue["IntermediateSteps"],
      PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
      Component -> selectionComponent,
      Contribution -> OptionValue["Contribution"]]
  ];

Options[LegacyIntegrateAntenna] =
  Options[BuildAndIntegrateAntenna];

LegacyIntegrateAntenna[type_, numFinalParticles_Integer, loopOrder_Integer,
   OptionsPattern[]] :=
  BuildAndIntegrateAntenna[type, numFinalParticles, loopOrder,
    ApplyFeynCalcMS -> OptionValue["ApplyFeynCalcMS"],
    quarkMass -> OptionValue["quarkMass"],
    PaVeEvaluation -> OptionValue["PaVeEvaluation"],
    ExpansionOrder -> OptionValue["ExpansionOrder"],
    KinematicScale -> OptionValue["KinematicScale"],
    NormalizeKinematicScale -> OptionValue["NormalizeKinematicScale"],
    ReturnDiagnostics -> OptionValue["ReturnDiagnostics"],
    LoopMomentum -> OptionValue["LoopMomentum"],
    ApplyDimReg -> OptionValue["ApplyDimReg"],
    BasisFamily -> OptionValue["BasisFamily"],
    BasisRoot -> OptionValue["BasisRoot"],
    GenerateMissingBases -> OptionValue["GenerateMissingBases"],
    ReturnTTerms -> OptionValue["ReturnTTerms"],
    IntermediateSteps -> OptionValue["IntermediateSteps"],
    PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
    Component -> OptionValue["Component"],
    Contribution -> OptionValue["Contribution"]];
IntegratedAntennaDiagnostics[key_, unintegrated_, integrated_, profile_Association,
   context_:<||>] :=
  Module[{paVeTarget, integratedTarget, integratedResidual, diagnostics,
     expansionOrder, tTerms, tTargets, antennaTargets, tResiduals,
     antennaResiduals},
    expansionOrder = Lookup[context, "ExpansionOrder", Lookup[profile,
       "ExpansionOrder", 0]];
    diagnostics =
      Switch[key,
        {a_Symbol /; SymbolName[a] === "A", 2, 1},
          paVeTarget = A21PaperPaVe /. D -> 4 - 2 Epsilon;
          integratedTarget = A21IntegratedPaper;
          integratedResidual =
            integrated - integratedTarget //
            FunctionExpand //
            FullSimplify;
          <|"PaVeResidualIsZero" -> TrueQ[Simplify[unintegrated -
              paVeTarget] === 0], "IntegratedResidualIsZero" -> TrueQ[
             integratedResidual === 0], "IntegratedResidual" ->
            integratedResidual, "Profile" -> profile|>
        ,
        {a_Symbol /; SymbolName[a] === "A", 3, 0},
          integratedTarget = 1/FeynCalc`Epsilon^2 + 3/(2 FeynCalc`Epsilon
            ) + 19/4 - 7 Pi^2/12;
          integratedResidual =
            integrated - integratedTarget //
            FunctionExpand //
            FullSimplify;
          <|"IntegratedResidualIsZero" -> TrueQ[integratedResidual ===
             0], "IntegratedResidual" -> integratedResidual, "Profile" ->
              profile|>
        ,
        {a_Symbol /; SymbolName[a] === "A", 4, 0},
          <|"IntegratedBackendAvailable" -> True,
            "FinalAntennaExtractionImplemented" -> True,
            "IntegratedComponentOrder" -> {Leading, Subleading},
            "PaperCheckAvailable" -> False,
            "Profile" -> profile|>
        ,
        {b_Symbol /; SymbolName[b] === "B", 4, 0},
          <|"IntegratedBackendAvailable" -> True,
            "FinalAntennaExtractionImplemented" -> True,
            "PaperCheckAvailable" -> False,
            "Profile" -> profile|>
        ,
        {c_Symbol /; SymbolName[c] === "C", 4, 0},
          <|"IntegratedBackendAvailable" -> True,
            "FinalAntennaExtractionImplemented" -> True,
            "PaperCheckAvailable" -> False,
            "Profile" -> profile|>
        ,
        {a_Symbol /; SymbolName[a] === "A", 3, 1},
          tTerms = Lookup[context, "TTerms", Missing["NotAvailable"]];
          tTargets = A31TTermTargets[expansionOrder];
          antennaTargets = A31IntegratedAntennaTargets[expansionOrder];
          tResiduals =
            If[ListQ[tTerms],
              A31IntegratedResiduals[tTerms, tTargets]
              ,
              Missing["NotAvailable"]
            ];
          antennaResiduals =
            If[ListQ[integrated] && !TrueQ[Lookup[context, "ReturnTTerms",
                False]],
              A31IntegratedResiduals[integrated, antennaTargets]
              ,
              Missing["NotAvailable"]
            ];
          <|"TTermResiduals" -> tResiduals, "TTermResidualsAreZero" ->
            IntegratedResidualListZeroQ[tResiduals],
            "IntegratedAntennaResiduals" -> antennaResiduals,
            "IntegratedAntennaResidualsAreZero" ->
              IntegratedResidualListZeroQ[antennaResiduals],
            "Profile" -> profile|>
        ,
        {a_Symbol /; SymbolName[a] === "A", 2, 2},
          tTerms = Lookup[context, "TTerms", Missing["NotAvailable"]];
          tResiduals =
            If[ListQ[tTerms],
              A22TTermResiduals[tTerms, expansionOrder]
              ,
              If[tTerms === Missing["NotAvailable"],
                Missing["NotAvailable"]
                ,
                A22TTermResiduals[tTerms, Lookup[context, "BuildComponent",
                  Lookup[context, "SelectedComponent", All]],
                  expansionOrder]
              ]
            ];
          antennaResiduals =
            If[Lookup[context, "ReturnTTerms", False] === True,
              Missing["NotAvailable"]
              ,
              If[ListQ[integrated],
                A22IntegratedResiduals[integrated, expansionOrder]
                ,
                A22IntegratedResiduals[integrated,
                  Lookup[context, "BuildComponent",
                    Lookup[context, "SelectedComponent", All]],
                  expansionOrder]
              ]
            ];
          <|"TTermResiduals" -> tResiduals,
            "TTermResidualsAreZero" ->
              IntegratedResidualListZeroQ[tResiduals],
            "TTermResidualIsZero" -> TrueQ[tResiduals === 0],
            "IntegratedAntennaResiduals" -> antennaResiduals,
            "IntegratedAntennaResidualsAreZero" ->
              IntegratedResidualListZeroQ[antennaResiduals],
            "IntegratedAntennaResidualIsZero" -> TrueQ[antennaResiduals === 0],
            "FinalAntennaExtractionImplemented" -> True,
            "Profile" -> profile|>
        ,
        _,
          <|"PaperCheckAvailable" -> False, "Profile" -> profile|>
      ];
    diagnostics
  ];
