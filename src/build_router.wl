(*************************************************)

(*
  Internal one-loop build object.
  This association is for routing and diagnostics.  The public BuildAntenna
  wrapper below converts it back to the natural expression/list returned to
  the user.
*)

(*************************************************)

Options[BuildLoopAntennaData] = {printDiagram -> False, prefactor -> 
  1, ApplyStripCouplings -> AllCouplings, ApplyCasimirSubstitution -> True,
   ApplyDimReg -> True, LoopMomentum -> l, ReductionBackend -> None};

Options[BuildTwoLoopAntennaData] = {printDiagram -> False, prefactor ->
  1, ApplyStripCouplings -> AllCouplings, ApplyCasimirSubstitution -> True,
   ApplyDimReg -> True, LoopMomenta -> {l1, l2}, Contribution -> All};

BuildLoopAntennaData[key_, OptionsPattern[]] :=
  Module[{profile, treeAmp, loopAmp, interference, context, extraction,
     output},
    profile = AntennaProfile[key];
    treeAmp = profile["TreeAmplitude"];
    loopAmp = MAmpOneLoop[profile["NumFinalParticles"], AntennaType ->
       profile["AntennaType"], LoopMomentum -> OptionValue["LoopMomentum"],
       printDiagram -> OptionValue["printDiagram"], prefactor -> OptionValue[
      "prefactor"], ApplyStripCouplings -> OptionValue["ApplyStripCouplings"
      ]];
    interference = InterfereOneLoopMAmplitudes[treeAmp, loopAmp, profile[
      "NumFinalParticles"], LoopMomentum -> OptionValue["LoopMomentum"], ReductionBackend
       -> OptionValue["ReductionBackend"], ApplyCasimirSubstitution -> OptionValue[
      "ApplyCasimirSubstitution"], ApplyDimReg -> False];
    context = <|"BornInterference" -> profile["BornInterference"]|>;
    extraction = ExtractLoopAntennaComponents[interference, profile, 
      context, ApplyDimReg -> OptionValue["ApplyDimReg"]];
    output = <|"Profile" -> profile, "TreeAmplitude" -> treeAmp, "LoopAmplitude"
       -> loopAmp, "Interferences" -> <|"Production" -> interference|>, "Components"
       -> extraction["Components"], "Diagnostics" -> extraction["Diagnostics"
      ], "NormalizedInterference" -> extraction["NormalizedInterference"]|>
      ;
    output
  ];

(*************************************************)

(*
  Two-loop build scaffold.
  A22 needs two distinct sources, the tree/two-loop interference and the
  one-loop self-interference.  The component and profile plumbing is useful
  before the actual two-loop amplitude machinery exists, but the production
  route must fail explicitly instead of silently reusing one-loop code.
*)

(*************************************************)

BuildTwoLoopAntennaData[key_, OptionsPattern[]] :=
  Module[{profile, contribution, blankComponents, treeAmp, twoLoopAmp,
     oneLoopLeft, oneLoopRight, context, twoLoopTreeInterference,
     oneLoopSelfInterference, twoLoopExtraction, selfExtraction, components,
     diagnostics, interferences},
    profile = AntennaProfile[key];
    contribution = CanonicalAntennaComponentName[OptionValue["Contribution"]];
    blankComponents = <|"Lead" -> $Failed, "SubLead" -> $Failed,
      "QuarkLoop" -> $Failed, "Breve" -> $Failed|>;
    If[key =!= {A, 2, 2},
      Return[
        <|"Profile" -> profile, "Amplitude" -> Missing["NotImplemented"],
          "Interferences" -> <||>, "Components" -> blankComponents,
          "Diagnostics" -> <|"Failed" -> True,
            "Reason" -> "UnsupportedTwoLoopAntenna"|>|>
      ]
    ];
    If[!MemberQ[{"All", "TwoLoopTree", "OneLoopSelf"}, contribution],
      Return[
        <|"Profile" -> profile, "Interferences" -> <||>,
          "Components" -> blankComponents, "Diagnostics" -> <|"Failed" ->
            True, "Reason" -> "UnsupportedTwoLoopContribution",
            "Contribution" -> OptionValue["Contribution"]|>|>
      ]
    ];
    treeAmp = AntennaAmplitude[{A, 2, 0}];
    context = <|"BornInterference" -> profile["BornInterference"]|>;
    components = blankComponents;
    diagnostics = <|"ImplementationStatus" -> Lookup[profile,
        "ImplementationStatus", "Unknown"], "Contribution" -> contribution|>;
    interferences = <||>;
    twoLoopAmp = Missing["NotBuilt"];
    oneLoopLeft = Missing["NotBuilt"];
    oneLoopRight = Missing["NotBuilt"];
    twoLoopExtraction = <||>;
    selfExtraction = <||>;
    If[MemberQ[{"All", "TwoLoopTree"}, contribution],
      twoLoopAmp = MAmpTwoLoop[2, AntennaType -> profile["AntennaType"],
        LoopMomenta -> OptionValue["LoopMomenta"],
        printDiagram -> OptionValue["printDiagram"],
        prefactor -> OptionValue["prefactor"],
        ApplyStripCouplings -> OptionValue["ApplyStripCouplings"]];
      If[twoLoopAmp === $Failed,
        Return[<|"Profile" -> profile, "TreeAmplitude" -> treeAmp,
          "TwoLoopAmplitude" -> $Failed, "Interferences" -> interferences,
          "Components" -> blankComponents,
          "Diagnostics" -> <|"Failed" -> True,
            "Reason" -> "TwoLoopAmplitudeGenerationFailed",
            "Contribution" -> contribution|>|>]
      ];
      twoLoopTreeInterference =
        InterfereTreeTwoLoopMAmplitudes[treeAmp, twoLoopAmp, 2,
          ApplyCasimirSubstitution -> OptionValue["ApplyCasimirSubstitution"],
          ApplyDimReg -> False, LoopMomenta -> OptionValue["LoopMomenta"]];
      If[twoLoopTreeInterference === $Failed,
        Return[<|"Profile" -> profile, "TreeAmplitude" -> treeAmp,
          "TwoLoopAmplitude" -> twoLoopAmp,
          "Interferences" -> <|"TwoLoopTree" -> twoLoopTreeInterference|>,
          "Components" -> blankComponents,
          "Diagnostics" -> <|"Failed" -> True,
            "Reason" -> "TwoLoopTreeInterferenceFailed",
            "Contribution" -> contribution|>|>]
      ];
      twoLoopExtraction =
        ExtractA22TwoLoopTreeComponents[twoLoopTreeInterference, profile,
          context, ApplyDimReg -> OptionValue["ApplyDimReg"]];
      components = Join[components, twoLoopExtraction["Components"]];
      diagnostics = Join[diagnostics, twoLoopExtraction["Diagnostics"]];
      interferences = Join[interferences,
        <|"TwoLoopTree" -> twoLoopTreeInterference|>];
    ];
    If[MemberQ[{"All", "OneLoopSelf"}, contribution],
      oneLoopLeft = MAmpOneLoop[2, AntennaType -> profile["AntennaType"],
        LoopMomentum -> OptionValue["LoopMomenta"][[1]],
        printDiagram -> False, prefactor -> OptionValue["prefactor"],
        ApplyStripCouplings -> OptionValue["ApplyStripCouplings"]];
      oneLoopRight = MAmpOneLoop[2, AntennaType -> profile["AntennaType"],
        LoopMomentum -> OptionValue["LoopMomenta"][[2]],
        printDiagram -> False, prefactor -> OptionValue["prefactor"],
        ApplyStripCouplings -> OptionValue["ApplyStripCouplings"]];
      If[MemberQ[{oneLoopLeft, oneLoopRight}, $Failed],
        Return[<|"Profile" -> profile, "TreeAmplitude" -> treeAmp,
          "OneLoopAmplitudes" -> {oneLoopLeft, oneLoopRight},
          "Interferences" -> interferences,
          "Components" -> blankComponents,
          "Diagnostics" -> <|"Failed" -> True,
            "Reason" -> "OneLoopAmplitudeGenerationFailed",
            "Contribution" -> contribution|>|>]
      ];
      oneLoopSelfInterference =
        InterfereOneLoopSelfMAmplitudes[oneLoopLeft, oneLoopRight, 2,
          ApplyCasimirSubstitution -> OptionValue["ApplyCasimirSubstitution"],
          ApplyDimReg -> False];
      If[oneLoopSelfInterference === $Failed,
        Return[<|"Profile" -> profile, "TreeAmplitude" -> treeAmp,
          "OneLoopAmplitudes" -> {oneLoopLeft, oneLoopRight},
          "Interferences" -> Join[interferences,
            <|"OneLoopSelf" -> oneLoopSelfInterference|>],
          "Components" -> blankComponents,
          "Diagnostics" -> <|"Failed" -> True,
            "Reason" -> "OneLoopSelfInterferenceFailed",
            "Contribution" -> contribution|>|>]
      ];
      selfExtraction =
        ExtractA22OneLoopSelfComponent[oneLoopSelfInterference, profile,
          context, ApplyDimReg -> OptionValue["ApplyDimReg"]];
      components = Join[components, selfExtraction["Components"]];
      diagnostics = Join[diagnostics, selfExtraction["Diagnostics"]];
      interferences = Join[interferences,
        <|"OneLoopSelf" -> oneLoopSelfInterference|>];
    ];
    <|"Profile" -> profile, "TreeAmplitude" -> treeAmp,
      "TwoLoopAmplitude" -> twoLoopAmp,
      "OneLoopAmplitudes" -> {oneLoopLeft, oneLoopRight},
      "Interferences" -> interferences, "Components" -> components,
      "Diagnostics" -> diagnostics,
      "TwoLoopNormalizedInterference" -> Lookup[twoLoopExtraction,
        "TwoLoopNormalizedInterference", Missing["NotBuilt"]],
      "SelfNormalizedInterference" -> Lookup[selfExtraction,
        "SelfNormalizedInterference", Missing["NotBuilt"]]|>
  ];
(*************************************************)

(*
  Internal tree-level build object.
  This assembles amplitudes, sector choices, interferences, and extraction
  diagnostics into one association.  The public BuildAntenna wrapper later
  returns only the natural antenna expression/list unless diagnostics are
  explicitly requested.
*)

(*************************************************)

BuildAntennaData[key_] :=
  Module[{profile, amp, context, fullInterference, fullExtraction, split,
     sectors, sectorInterference, extraction, colorOrderedData, diagnostics,
     referenceSector, referenceProfile, referenceInterference, referenceExtraction,
     output},
    profile = AntennaProfile[key];
    amp = AntennaAmplitude[key];
    context = <|"BornInterference" -> BornInterference[]|>;
    output =
      Switch[profile["Production"],
        "SelfInterference",
          fullInterference = AntennaSelfInterference[key];
          extraction = ExtractAntennaComponents[fullInterference, profile,
             context];
          <|"Profile" -> profile, "Amplitude" -> amp, "Sectors" -> <|
            |>, "Interferences" -> <|"Production" -> fullInterference|>, "Components"
             -> extraction["Components"], "Diagnostics" -> extraction["Diagnostics"
            ]|>
        ,
        "ColorOrderedAntenna",
          fullInterference = AntennaSelfInterference[key];
          fullExtraction = ExtractAntennaComponents[fullInterference,
             profile, context];
          colorOrderedData = ColorOrderedAntenna[amp, AntennaAmplitude[{A,
             2, 0}], profile["NumFinalParticles"], profile["ColorOrderedSpec"
            ]];
          diagnostics =
            If[colorOrderedData === $Failed,
              <|"Failed" -> True, "Reason" -> "ColorOrderedConstructionFailed"
                |>
              ,
              Join[fullExtraction["Diagnostics"], colorOrderedData["Diagnostics"
                ]]
            ];
          <|
            "Profile" -> profile
            ,
            "Amplitude" -> amp
            ,
            "Sectors" -> <||>
            ,
            "Interferences" -> <|"FullColor" -> fullInterference|>
            ,
            "FullColorComponents" -> fullExtraction["Components"]
            ,
            "Components" ->
              If[colorOrderedData === $Failed,
                <|"Antenna" -> $Failed|>
                ,
                <|"Antenna" -> colorOrderedData["Antenna"]|>
              ]
            ,
            "ColorOrderedData" -> colorOrderedData
            ,
            "Diagnostics" -> diagnostics
          |>
        ,
        "SectorSelfInterference",
          fullInterference = AntennaSelfInterference[key];
          fullExtraction = ExtractAntennaComponents[fullInterference,
             profile, context];
          split = SplitAmplitudeBySectors[amp, profile];
          sectors = profile["ProductionSectors"];
          sectorInterference =
            If[split["Diagnostics"][sectors[[1]] <> "Terms"] > 0 && split[
              "Diagnostics"][sectors[[2]] <> "Terms"] > 0,
              InterfereMAmplitudes[split["Parts"][sectors[[1]]], split[
                "Parts"][sectors[[2]]], profile["NumFinalParticles"], AntennaType -> 
                profile["AntennaType"]]
              ,
              $Failed
            ];
          extraction = ExtractAntennaComponents[sectorInterference, profile,
             context];
          diagnostics = Join[split["Diagnostics"], extraction["Diagnostics"
            ]];
          <|"Profile" -> profile, "Amplitude" -> amp, "Sectors" -> split[
            "Parts"], "Interferences" -> <|"Full" -> fullInterference, "Production"
             -> sectorInterference|>, "FullComponents" -> fullExtraction["Components"
            ], "FullDiagnostics" -> fullExtraction["Diagnostics"], "Components" ->
             extraction["Components"], "Diagnostics" -> diagnostics|>
        ,
        "SectorSymmetrizedInterference",
          split = SplitAmplitudeBySectors[amp, profile];
          sectors = profile["ProductionSectors"];
          sectorInterference =
            If[split["Diagnostics"][sectors[[1]] <> "Terms"] > 0 && split[
              "Diagnostics"][sectors[[2]] <> "Terms"] > 0,
              SymmetrizedInterference[split["Parts"][sectors[[1]]], split[
                "Parts"][sectors[[2]]], profile["NumFinalParticles"], profile["AntennaType"
                ]]
              ,
              $Failed
            ];
          extraction = ExtractAntennaComponents[sectorInterference, profile,
             context];
          referenceSector = Lookup[profile, "ReferenceSquareSector", 
            Missing["NotAvailable"]];
          referenceProfile = AntennaProfile[Lookup[profile, "ReferenceSquareProfile",
             key]];
          referenceInterference =
            If[StringQ[referenceSector] && split["Diagnostics"][referenceSector
               <> "Terms"] > 0,
              InterfereMAmplitudes[split["Parts"][referenceSector], split[
                "Parts"][referenceSector], profile["NumFinalParticles"], AntennaType 
                -> profile["AntennaType"]]
              ,
              $Failed
            ];
          referenceExtraction = ExtractAntennaComponents[referenceInterference,
             referenceProfile, context];
          diagnostics = Join[split["Diagnostics"], extraction["Diagnostics"
            ]];
          <|"Profile" -> profile, "Amplitude" -> amp, "Sectors" -> split[
            "Parts"], "Interferences" -> <|"Production" -> sectorInterference, "ReferenceSquare"
             -> referenceInterference|>, "Components" -> extraction["Components"],
             "Diagnostics" -> diagnostics, "ReferenceSquareComponents" -> referenceExtraction[
            "Components"], "ReferenceSquareDiagnostics" -> referenceExtraction["Diagnostics"
            ]|>
        ,
        _,
          <|"Profile" -> profile, "Amplitude" -> amp, "Sectors" -> <|
            |>, "Interferences" -> <||>, "Components" -> <||>, "Diagnostics" -> <|
            "Failed" -> True, "Reason" -> "UnknownProductionMode"|>|>
      ];
    output
  ];
(*************************************************)

(*
  Public antenna builder.
  BuildAntenna[type, n, loopOrder] is the user-facing wrapper.  By default it
  returns the antenna expression (or the natural list of components).  The
  association-valued internals remain available through ReturnBuildData, and
  diagnostics through ReturnDiagnostics.
*)

(*************************************************)

Options[BuildAntenna] = {ReturnDiagnostics -> False, ReturnBuildData
  -> False, ReturnAntennaObject -> False, IntegrableForm -> False,
  RunPaperCheck -> Automatic, Verbose -> False, printDiagram -> False,
  prefactor -> 1, ApplyStripCouplings -> AllCouplings,
  ApplyCasimirSubstitution -> True, ApplyDimReg -> True,
  LoopMomentum -> l, ReductionBackend -> None, Component -> All,
  LoopMomenta -> {l1, l2}, Contribution -> All};

Options[BuildAntennaObject] =
  Options[BuildAntenna];

AntennaComponentOrder[{A, 4, 0}] :=
  {Leading, Subleading, Nf};

AntennaComponentOrder[{A, 3, 1}] :=
  {Leading, Subleading, Nf};

AntennaComponentOrder[{A, 2, 2}] :=
  {Leading, Subleading, Nf, Breve};

AntennaComponentOrder[_] :=
  {Leading};

CanonicalAntennaComponentName[component_] :=
  If[component === All,
    "All"
    ,
    Last[StringSplit[ToString[Unevaluated[component], InputForm], "`"]]
  ];

CanonicalAntennaComponentName[component_String] :=
  component;

SelectAntennaComponent[result_, key_, component_] :=
  Module[{order, orderNames, componentName, position},
    componentName = CanonicalAntennaComponentName[component];
    If[componentName === "All",
      Return[result]
    ];
    order = AntennaComponentOrder[key];
    orderNames = CanonicalAntennaComponentName /@ order;
    position = FirstPosition[orderNames, componentName, Missing[
       "UnknownComponent"]];
    If[position === Missing["UnknownComponent"],
      Print["Unknown component ", component, " for antenna ", key,
        ". Available components are ", order, ". Aborting..."];
      Return[$Failed]
    ];
    If[ListQ[result],
      If[position[[1]] <= Length[result],
        result[[position[[1]]]]
        ,
        Print["Component ", component, " is not available in result for ",
          key, ". Aborting..."];
        $Failed
      ]
      ,
      If[position[[1]] === 1,
        result
        ,
        Print["Component ", component, " is not available for scalar antenna ",
          key, ". Aborting..."];
        $Failed
      ]
    ]
  ];

AntennaObjectQ[AntennaObject[data_Association]] :=
  And[
    KeyExistsQ[data, "Key"],
    KeyExistsQ[data, "BuildData"],
    KeyExistsQ[data, "Antenna"],
    KeyExistsQ[data, "FullAntenna"]
  ];

AntennaObjectQ[_] :=
  False;

AntennaObjectData[AntennaObject[data_Association]] :=
  data;

AntennaKey[obj_AntennaObject] :=
  Lookup[AntennaObjectData[obj], "Key", Missing["UnknownKey"]];

AntennaComponent[obj_AntennaObject] :=
  Lookup[AntennaObjectData[obj], "SelectedComponent",
    Missing["UnknownComponent"]];

AntennaContribution[obj_AntennaObject] :=
  Lookup[AntennaObjectData[obj], "Contribution",
    Missing["UnknownContribution"]];

AntennaExpression[obj_AntennaObject] :=
  Lookup[AntennaObjectData[obj], "Antenna", Missing["UnknownAntenna"]];

AntennaFullExpression[obj_AntennaObject] :=
  Lookup[AntennaObjectData[obj], "FullAntenna",
    Missing["UnknownFullAntenna"]];

MakeAntennaObject[key_, data_Association, component_, contribution_] :=
  Module[{fullResult, selectedResult},
    fullResult = BuildAntennaResult[key, data];
    selectedResult = SelectAntennaComponent[fullResult, key, component];
    AntennaObject[
      <|
        "Key" -> key,
        "Profile" -> Lookup[data, "Profile", <|"Key" -> key|>],
        "BuildData" -> data,
        "FullAntenna" -> fullResult,
        "Antenna" -> selectedResult,
        "SelectedComponent" -> component,
        "SelectedComponentName" -> CanonicalAntennaComponentName[component],
        "Contribution" -> contribution,
        "ContributionName" -> CanonicalAntennaComponentName[contribution]
      |>
    ]
  ];

AntennaObjectWithSelection[obj_AntennaObject, component_, contribution_:Automatic] :=
  Module[{data, selectedContribution},
    data = AntennaObjectData[obj];
    selectedContribution =
      If[contribution === Automatic,
        Lookup[data, "Contribution", All],
        contribution
      ];
    MakeAntennaObject[
      Lookup[data, "Key", Missing["UnknownKey"]],
      Lookup[data, "BuildData", <||>],
      component,
      selectedContribution
    ]
  ];

BuildAntennaResult[{A, 2, 0}, data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{A, 3, 0}, data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{A, 4, 0}, data_Association] :=
  {data["Components"]["Antenna"], data["FullColorComponents"]["SubLead"
    ], data["FullColorComponents"]["QuarkLoop"]};

BuildAntennaResult[{B, 4, 0}, data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{C, 4, 0}, data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{A, 2, 1}, data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{A, 3, 1}, data_Association] :=
  {data["Components"]["Lead"], data["Components"]["SubLead"], data["Components"
    ]["QuarkLoop"]};

BuildAntennaResult[{A, 2, 2}, data_Association] :=
  {data["Components"]["Lead"], data["Components"]["SubLead"], data["Components"
    ]["QuarkLoop"], data["Components"]["Breve"]};

BuildAntennaDiagnostics[key_, result_, data_Association, runPaperCheck_
  ] :=
  Module[{paperDiagnostics},
    paperDiagnostics =
      If[TrueQ[runPaperCheck] || (runPaperCheck === Automatic && PaperCheckAvailableQ[
        key]),
        PaperDiagnosticsFor[key, result]
        ,
        <|"PaperCheckAvailable" -> False|>
      ];
    Join[data["Diagnostics"], <|"PaperDiagnostics" -> paperDiagnostics
      |>]
  ];

BuildAntennaObject[type_, numFinalParticles_, loopOrder_,
   OptionsPattern[]] :=
  BuildAntenna[type, numFinalParticles, loopOrder,
    ReturnDiagnostics -> OptionValue["ReturnDiagnostics"],
    ReturnBuildData -> False,
    ReturnAntennaObject -> False,
    IntegrableForm -> True,
    RunPaperCheck -> OptionValue["RunPaperCheck"],
    Verbose -> OptionValue["Verbose"],
    printDiagram -> OptionValue["printDiagram"],
    prefactor -> OptionValue["prefactor"],
    ApplyStripCouplings -> OptionValue["ApplyStripCouplings"],
    ApplyCasimirSubstitution -> OptionValue[
      "ApplyCasimirSubstitution"],
    ApplyDimReg -> OptionValue["ApplyDimReg"],
    LoopMomentum -> OptionValue["LoopMomentum"],
    ReductionBackend -> OptionValue["ReductionBackend"],
    Component -> OptionValue["Component"],
    LoopMomenta -> OptionValue["LoopMomenta"],
    Contribution -> OptionValue["Contribution"]];

BuildAntenna[type_, numFinalParticles_, loopOrder_, OptionsPattern[]] :=
  Module[{key, data, result, selectedResult, diagnostics, antennaObject,
     integrableRequested},
    key = {type, numFinalParticles, loopOrder};
    data =
      Switch[loopOrder,
        0,
          BuildAntennaData[key]
        ,
        1,
          BuildLoopAntennaData[key, printDiagram -> OptionValue["printDiagram"
            ], prefactor -> OptionValue["prefactor"], ApplyStripCouplings -> OptionValue[
            "ApplyStripCouplings"], ApplyCasimirSubstitution -> OptionValue["ApplyCasimirSubstitution"
            ], ApplyDimReg -> OptionValue["ApplyDimReg"], LoopMomentum -> OptionValue[
            "LoopMomentum"], ReductionBackend -> OptionValue["ReductionBackend"]]
        ,
        2,
          BuildTwoLoopAntennaData[key, printDiagram -> OptionValue[
            "printDiagram"], prefactor -> OptionValue["prefactor"],
            ApplyStripCouplings -> OptionValue["ApplyStripCouplings"],
            ApplyCasimirSubstitution -> OptionValue[
              "ApplyCasimirSubstitution"], ApplyDimReg -> OptionValue[
              "ApplyDimReg"], LoopMomenta -> OptionValue["LoopMomenta"],
            Contribution -> OptionValue["Contribution"]]
        ,
        _,
          <|"Profile" -> <|"Key" -> key|>, "Components" -> <||>,
            "Diagnostics" -> <|"Failed" -> True,
              "Reason" -> "UnsupportedLoopOrder"|>|>
      ];
    If[OptionValue["ReturnBuildData"] === True,
      Return[data]
    ];
    result = BuildAntennaResult[key, data];
    selectedResult = SelectAntennaComponent[result, key, OptionValue[
       "Component"]];
    antennaObject = MakeAntennaObject[key, data, OptionValue["Component"],
      OptionValue["Contribution"]];
    integrableRequested =
      TrueQ[OptionValue["IntegrableForm"]] ||
      TrueQ[OptionValue["ReturnAntennaObject"]];
    If[integrableRequested,
      If[OptionValue["ReturnDiagnostics"] === True,
        diagnostics = BuildAntennaDiagnostics[key, result, data, OptionValue[
          "RunPaperCheck"]];
        Return[{antennaObject, Join[diagnostics, <|"SelectedComponent" ->
              OptionValue["Component"], "Contribution" -> OptionValue[
              "Contribution"]|>]}]
        ,
        Return[antennaObject]
      ]
    ];
    If[OptionValue["ReturnDiagnostics"] === True,
      diagnostics = BuildAntennaDiagnostics[key, result, data, OptionValue[
        "RunPaperCheck"]];
      {selectedResult, Join[diagnostics, <|"SelectedComponent" -> OptionValue[
          "Component"]|>]}
      ,
      selectedResult
    ]
  ];
