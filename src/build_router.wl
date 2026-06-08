(*************************************************)

(*
  Internal one-loop build object.
  This association is for routing and diagnostics.  The public BuildAntenna
  wrapper below converts it back to the natural expression/list returned to
  the user.
*)

(*************************************************)

BuildLoopAntennaData::usage =
  "BuildLoopAntennaData[key, ...] builds the internal association used to route one-loop antenna construction and diagnostics.";

BuildTwoLoopAntennaData::usage =
  "BuildTwoLoopAntennaData[key, ...] builds the internal association used by the experimental two-loop source routes.";

ResolveLoopBuildReductionBackend::usage =
  "ResolveLoopBuildReductionBackend[profile, requestedBackend] chooses the loop-side reduction backend used during build-time processing.";

ResolveIntegrableLoopBuildReductionBackend::usage =
  "ResolveIntegrableLoopBuildReductionBackend[key, requestedBackend] picks the build-time reduction shape needed by an integrable antenna object.";

BuildAntennaData::usage =
  "BuildAntennaData[key] assembles the raw build-side data association for a given antenna key.";

ResolvedTreeSelfInterference::usage =
  "ResolvedTreeSelfInterference[key, amp, profile] returns the tree self-interference for a route, falling back to a direct recomputation if the memoized symbol has gone inert.";

BuildAntenna::usage =
  "BuildAntenna[type, numFinalParticles, loopOrder, ...] is the main public constructor for unintegrated antenna expressions.";

BuildAntennaObject::usage =
  "BuildAntennaObject[type, numFinalParticles, loopOrder, ...] builds an AntennaObject carrying the metadata needed by IntegrateAntenna.";

BuildAntennaDiagnostics::usage =
  "BuildAntennaDiagnostics[key, result, data, ...] constructs the diagnostics association returned by the public build routes.";

BuildAntennaStoredResultKey::usage =
  "BuildAntennaStoredResultKey[type, numFinalParticles, loopOrder, options] builds the cache key for a BuildAntenna request.";

BuildAntennaStoredResultLabel::usage =
  "BuildAntennaStoredResultLabel[type, numFinalParticles, loopOrder, options] builds the human-readable cache label for a BuildAntenna request.";

BuildAntennaObjectStoredResultKey::usage =
  "BuildAntennaObjectStoredResultKey[type, numFinalParticles, loopOrder, options] builds the cache key for a BuildAntennaObject request.";

BuildAntennaObjectStoredResultLabel::usage =
  "BuildAntennaObjectStoredResultLabel[type, numFinalParticles, loopOrder, options] builds the human-readable cache label for a BuildAntennaObject request.";

BuildAntennaResult::usage =
  "BuildAntennaResult[key, data] converts internal build data into the natural public antenna expression or component list.";

AntennaComponentOrder::usage =
  "AntennaComponentOrder[key] returns the canonical component ordering used when a route has multiple public components.";

CanonicalAntennaComponentName::usage =
  "CanonicalAntennaComponentName[component] normalizes component labels to the standard public names used across diagnostics and caching.";

NormalizeIntermediateSteps::usage =
  "NormalizeIntermediateSteps[steps] normalizes intermediate-step requests into the internal list form used by the routers.";

RequestedIntermediateStepQ::usage =
  "RequestedIntermediateStepQ[steps, label] tests whether a named intermediate stage was requested by the caller.";

PrintIntermediateStepsAssociation::usage =
  "PrintIntermediateStepsAssociation[steps] prints the requested intermediate-stage association with simple section headers.";

CollectBuildIntermediateSteps::usage =
  "CollectBuildIntermediateSteps[key, buildData, result, diagnostics, requestedSteps] collects the build-side stages requested for inspection.";

FormatFreshBuildReturn::usage =
  "FormatFreshBuildReturn[result, diagnostics, returnDiagnostics, requestedSteps, printSteps] formats a fresh build result in the public return shape.";

SelectAntennaComponent::usage =
  "SelectAntennaComponent[result, key, component] extracts one named component from a multi-component antenna result.";

AntennaObjectQ::usage =
  "AntennaObjectQ[expr] returns True when expr is a valid AntennaObject wrapper.";

AntennaObjectData::usage =
  "AntennaObjectData[obj] returns the association stored inside an AntennaObject.";

AntennaKey::usage =
  "AntennaKey[obj] returns the {type, multiplicity, loopOrder} key stored in an AntennaObject.";

AntennaComponent::usage =
  "AntennaComponent[obj] returns the currently selected component recorded in an AntennaObject.";

AntennaContribution::usage =
  "AntennaContribution[obj] returns the currently selected contribution recorded in an AntennaObject.";

AntennaExpression::usage =
  "AntennaExpression[obj] returns the selected antenna expression stored in an AntennaObject.";

AntennaFullExpression::usage =
  "AntennaFullExpression[obj] returns the full unselected expression payload stored in an AntennaObject.";

MakeAntennaObject::usage =
  "MakeAntennaObject[key, data, component, contribution] constructs the AntennaObject wrapper used by the integration routes.";

AntennaObjectWithSelection::usage =
  "AntennaObjectWithSelection[obj, component, contribution] returns a copy of an AntennaObject with updated component or contribution selection.";

Options[BuildLoopAntennaData] = {printDiagram -> False, prefactor -> 
  1, ApplyStripCouplings -> AllCouplings, ApplyCasimirSubstitution -> True,
   ApplyDimReg -> True, LoopMomentum -> l, ReductionBackend -> Automatic};

Options[BuildTwoLoopAntennaData] = {printDiagram -> False, prefactor ->
  1, ApplyStripCouplings -> AllCouplings, ApplyCasimirSubstitution -> True,
   ApplyDimReg -> True, LoopMomenta -> {l1, l2}, Contribution -> All};

ResolveLoopBuildReductionBackend[profile_Association, requestedBackend_] :=
  Module[{resolvedBackend},
    resolvedBackend =
      If[requestedBackend === Automatic,
        Lookup[Lookup[profile, "ReductionProfile", <||>], "DefaultBackend",
          "PaVe"]
        ,
        requestedBackend
      ];
    resolvedBackend
  ];

ResolveLoopBuildReductionBackend[profile_, requestedBackend_] :=
  Module[{resolvedProfile},
    resolvedProfile = Quiet[Check[Evaluate[profile], profile]];
    If[AssociationQ[resolvedProfile],
      Return[
        ResolveLoopBuildReductionBackend[resolvedProfile, requestedBackend]
      ]
    ];
    If[requestedBackend === Automatic,
      "PaVe"
      ,
      requestedBackend
    ]
  ];

ResolveIntegrableLoopBuildReductionBackend[key_, requestedBackend_] :=
  Module[{integrationBackend},
    If[requestedBackend =!= Automatic,
      Return[requestedBackend]
    ];
    integrationBackend =
      Lookup[AntennaIntegrationProfile[key], "DefaultBackend", None];
    Switch[integrationBackend,
      PaVe,
        "PaVe"
      ,
      IBP,
        None
      ,
      _,
        None
    ]
  ];

BuildLoopAntennaData[key_, OptionsPattern[]] :=
  Module[{profile, treeAmp, loopAmp, reductionBackend, interference,
     context, extraction, output},
    profile = AntennaProfile[key];
    reductionBackend =
      ResolveLoopBuildReductionBackend[profile, OptionValue["ReductionBackend"]];
    treeAmp = profile["TreeAmplitude"];
    loopAmp = MAmpOneLoop[profile["NumFinalParticles"], AntennaType ->
       profile["AntennaType"], LoopMomentum -> OptionValue["LoopMomentum"],
       printDiagram -> OptionValue["printDiagram"], prefactor -> OptionValue[
      "prefactor"], ApplyStripCouplings -> OptionValue["ApplyStripCouplings"
      ]];
    interference = InterfereOneLoopMAmplitudes[treeAmp, loopAmp, profile[
      "NumFinalParticles"], LoopMomentum -> OptionValue["LoopMomentum"], ReductionBackend
       -> reductionBackend, ApplyCasimirSubstitution -> OptionValue[
      "ApplyCasimirSubstitution"], ApplyDimReg -> False];
    If[interference === $Failed,
      Return[
        <|"Profile" -> profile, "TreeAmplitude" -> treeAmp,
          "LoopAmplitude" -> loopAmp, "Interferences" -> <|"Production" -> $Failed|>,
          "Components" -> <|"Lead" -> $Failed, "SubLead" -> $Failed,
            "QuarkLoop" -> $Failed, "Breve" -> $Failed|>,
          "Diagnostics" -> <|"Failed" -> True,
            "Reason" -> "OneLoopInterferenceFailed"|>,
          "NormalizedInterference" -> $Failed|>
      ]
    ];
    context = <|"BornInterference" -> profile["BornInterference"]|>;
    extraction = ExtractLoopAntennaComponents[interference, profile, 
      context, ApplyDimReg -> OptionValue["ApplyDimReg"]];
    If[!AssociationQ[extraction],
      Return[
        <|"Profile" -> profile, "TreeAmplitude" -> treeAmp,
          "LoopAmplitude" -> loopAmp,
          "Interferences" -> <|"Production" -> interference|>,
          "Components" -> <|"Lead" -> $Failed, "SubLead" -> $Failed,
            "QuarkLoop" -> $Failed|>,
          "Diagnostics" -> <|"Failed" -> True,
            "Reason" -> "LoopExtractionFailed",
            "ExtractionHead" -> Head[extraction]|>,
          "NormalizedInterference" -> $Failed|>
      ]
    ];
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
          fullInterference = ResolvedTreeSelfInterference[key, amp, profile];
          extraction = ExtractAntennaComponents[fullInterference, profile,
             context];
          <|"Profile" -> profile, "Amplitude" -> amp, "Sectors" -> <|
            |>, "Interferences" -> <|"Production" -> fullInterference|>, "Components"
             -> extraction["Components"], "Diagnostics" -> extraction["Diagnostics"
            ]|>
        ,
        "ColorOrderedAntenna",
          fullInterference = ResolvedTreeSelfInterference[key, amp, profile];
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
          fullInterference = ResolvedTreeSelfInterference[key, amp, profile];
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

ResolvedTreeSelfInterference[key_, amp_, profile_Association] :=
  Module[{interference, storedRuleValue, keyTypeName},
    keyTypeName = SymbolName[First[key]];
    If[keyTypeName === "A" && key[[2]] === 3 && key[[3]] === 0,
      Return[
        InterfereMAmplitudes[
          amp,
          amp,
          Lookup[profile, "NumFinalParticles", key[[2]]]
        ]
      ]
    ];
    interference = Quiet[Check[Evaluate[AntennaSelfInterference[key]], $Failed]];
    If[interference === $Failed ||
        Head[interference] === AntennaSelfInterference,
      storedRuleValue =
        FirstCase[
          DownValues[AntennaSelfInterference],
          HoldPattern[HoldPattern[AntennaSelfInterference[arg : {type_Symbol, n_Integer, l_Integer}]] :> rhs_] /;
              TrueQ[
                SymbolName[type] === keyTypeName &&
                n === key[[2]] &&
                l === key[[3]]
              ] :>
            rhs,
          Missing["NotFound"]
        ];
      If[storedRuleValue =!= Missing["NotFound"],
        Return[storedRuleValue]
      ];
      interference =
        If[Lookup[profile, "AntennaType", First[key]] === A,
          InterfereMAmplitudes[
            amp,
            amp,
            Lookup[profile, "NumFinalParticles", key[[2]]]
          ]
          ,
          InterfereMAmplitudes[
            amp,
            amp,
            Lookup[profile, "NumFinalParticles", key[[2]]],
            AntennaType -> Lookup[profile, "AntennaType", First[key]]
          ]
        ]
    ];
    interference
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
  LoopMomentum -> l, ReductionBackend -> Automatic, Component -> All,
  IntermediateSteps -> {}, PrintIntermediateSteps -> False,
  LoopMomenta -> {l1, l2}, Contribution -> All,
  UseStoredResults -> False, StoreResults -> False,
  ResultsCacheRoot -> Automatic, RefreshStoredResults -> False};

Options[BuildAntennaObject] =
  Options[BuildAntenna];

AntennaComponentOrder[{a_Symbol /; SymbolName[a] === "A", 4, 0}] :=
  {Leading, Subleading};

AntennaComponentOrder[{a_Symbol /; SymbolName[a] === "A", 3, 1}] :=
  {Leading, Subleading, Nf};

AntennaComponentOrder[{a_Symbol /; SymbolName[a] === "A", 2, 2}] :=
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

NormalizeIntermediateSteps[steps_] :=
  Module[{normalized},
    normalized =
      Which[
        steps === None || steps === False || steps === {},
          {}
        ,
        steps === All || steps === True,
          {"BuildData", "FullBuildResult", "SelectedBuildResult",
            "AntennaObject", "BuildDiagnostics"}
        ,
        StringQ[steps],
          {steps}
        ,
        ListQ[steps],
          Flatten[steps /. s_String :> {s}]
        ,
        True,
          {ToString[Unevaluated[steps], InputForm]}
      ];
    DeleteDuplicates[normalized]
  ];

RequestedIntermediateStepQ[steps_List, label_String] :=
  MemberQ[steps, label];

CollectBuildIntermediateSteps[data_Association, fullResult_, selectedResult_,
   antennaObject_, diagnostics_, steps_List] :=
  Module[{collected = <||>},
    If[RequestedIntermediateStepQ[steps, "BuildData"],
      collected = Join[collected, <|"BuildData" -> data|>]
    ];
    If[RequestedIntermediateStepQ[steps, "FullBuildResult"],
      collected = Join[collected, <|"FullBuildResult" -> fullResult|>]
    ];
    If[RequestedIntermediateStepQ[steps, "SelectedBuildResult"],
      collected = Join[collected, <|"SelectedBuildResult" -> selectedResult|>]
    ];
    If[RequestedIntermediateStepQ[steps, "AntennaObject"],
      collected = Join[collected, <|"AntennaObject" -> antennaObject|>]
    ];
    If[RequestedIntermediateStepQ[steps, "BuildDiagnostics"],
      collected = Join[collected, <|"BuildDiagnostics" -> diagnostics|>]
    ];
    collected
  ];

PrintIntermediateStepsAssociation[steps_Association] :=
  Module[{},
    KeyValueMap[
      (
        Print["=== ", #1, " ==="];
        Print[#2]
      )&,
      steps
    ];
    Null
  ];

BuildAntennaStoredResultKey[type_, numFinalParticles_, loopOrder_,
   options_Association] :=
  StoredResultKeyAssociation[
    "BuildAntenna",
    <|
      "Type" -> type,
      "NumFinalParticles" -> numFinalParticles,
      "LoopOrder" -> loopOrder,
      "ReturnBuildData" -> Lookup[options, "ReturnBuildData", False],
      "ReturnAntennaObject" -> Lookup[options, "ReturnAntennaObject", False],
      "IntegrableForm" -> Lookup[options, "IntegrableForm", False],
      "RunPaperCheck" -> Lookup[options, "RunPaperCheck", Automatic],
      "prefactor" -> Lookup[options, "prefactor", 1],
      "ApplyStripCouplings" -> Lookup[options, "ApplyStripCouplings",
        AllCouplings],
      "ApplyCasimirSubstitution" -> Lookup[options,
        "ApplyCasimirSubstitution", True],
      "ApplyDimReg" -> Lookup[options, "ApplyDimReg", True],
      "LoopMomentum" -> Lookup[options, "LoopMomentum", l],
      "ReductionBackend" -> Lookup[options, "ReductionBackend", Automatic],
      "Component" -> Lookup[options, "Component", All],
      "LoopMomenta" -> Lookup[options, "LoopMomenta", {l1, l2}],
      "Contribution" -> Lookup[options, "Contribution", All]
    |>
  ];

BuildAntennaStoredResultLabel[type_, numFinalParticles_, loopOrder_,
   options_Association] :=
  StringJoin[
    "BuildAntenna-",
    StoredResultTypeLabel[type], "-",
    ToString[numFinalParticles], "-",
    ToString[loopOrder], "-",
    CanonicalAntennaComponentName[Lookup[options, "Component", All]], "-",
    CanonicalAntennaComponentName[Lookup[options, "Contribution", All]]
  ];

BuildAntennaObjectStoredResultKey[type_, numFinalParticles_, loopOrder_,
   options_Association] :=
  StoredResultKeyAssociation[
    "BuildAntennaObject",
    <|
      "Type" -> type,
      "NumFinalParticles" -> numFinalParticles,
      "LoopOrder" -> loopOrder,
      "RunPaperCheck" -> Lookup[options, "RunPaperCheck", Automatic],
      "prefactor" -> Lookup[options, "prefactor", 1],
      "ApplyStripCouplings" -> Lookup[options, "ApplyStripCouplings",
        AllCouplings],
      "ApplyCasimirSubstitution" -> Lookup[options,
        "ApplyCasimirSubstitution", True],
      "ApplyDimReg" -> Lookup[options, "ApplyDimReg", True],
      "LoopMomentum" -> Lookup[options, "LoopMomentum", l],
      "ReductionBackend" -> Lookup[options, "ReductionBackend", Automatic],
      "Component" -> Lookup[options, "Component", All],
      "LoopMomenta" -> Lookup[options, "LoopMomenta", {l1, l2}],
      "Contribution" -> Lookup[options, "Contribution", All]
    |>
  ];

BuildAntennaObjectStoredResultLabel[type_, numFinalParticles_, loopOrder_,
   options_Association] :=
  StringJoin[
    "BuildAntennaObject-",
    StoredResultTypeLabel[type], "-",
    ToString[numFinalParticles], "-",
    ToString[loopOrder], "-",
    CanonicalAntennaComponentName[Lookup[options, "Component", All]], "-",
    CanonicalAntennaComponentName[Lookup[options, "Contribution", All]]
  ];

FormatFreshBuildReturn[result_, diagnostics_, returnDiagnostics_,
   requestedSteps_List, printSteps_] :=
  Module[{selectedSteps},
    selectedSteps = Lookup[diagnostics, "IntermediateSteps", <||>];
    If[TrueQ[printSteps] && AssociationQ[selectedSteps] && Length[
        selectedSteps] > 0,
      PrintIntermediateStepsAssociation[selectedSteps]
    ];
    If[TrueQ[returnDiagnostics],
      {result, diagnostics}
      ,
      If[Length[requestedSteps] > 0,
        {result, selectedSteps}
        ,
        result
      ]
    ]
  ];

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
    If[selectedResult === $Failed,
      Return[$Failed]
    ];
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
    ]};

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

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 2, 0},
   data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 3, 0},
   data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 4, 0},
   data_Association] :=
  {data["Components"]["Antenna"], data["FullColorComponents"]["SubLead"]};

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "B", 4, 0},
   data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "C", 4, 0},
   data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 2, 1},
   data_Association] :=
  data["Components"]["Antenna"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 3, 1},
   data_Association] :=
  {data["Components"]["Lead"], data["Components"]["SubLead"],
    data["Components"]["QuarkLoop"]};

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 2, 2},
   data_Association] :=
  {data["Components"]["Lead"], data["Components"]["SubLead"],
    data["Components"]["QuarkLoop"], data["Components"]["Breve"]};

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
  Module[{requestedSteps, useStored, storeStored, refreshStored,
     cacheKey, cacheLabel, cacheRoot, loaded, computed, result, diagnostics,
     optionsAssoc},
    requestedSteps = NormalizeIntermediateSteps[OptionValue[
      "IntermediateSteps"]];
    useStored = TrueQ[OptionValue["UseStoredResults"]];
    storeStored = TrueQ[OptionValue["StoreResults"]];
    refreshStored = TrueQ[OptionValue["RefreshStoredResults"]];
    optionsAssoc = <|
      "RunPaperCheck" -> OptionValue["RunPaperCheck"],
      "prefactor" -> OptionValue["prefactor"],
      "ApplyStripCouplings" -> OptionValue["ApplyStripCouplings"],
      "ApplyCasimirSubstitution" -> OptionValue[
        "ApplyCasimirSubstitution"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ReductionBackend" -> OptionValue["ReductionBackend"],
      "Component" -> OptionValue["Component"],
      "LoopMomenta" -> OptionValue["LoopMomenta"],
      "Contribution" -> OptionValue["Contribution"]
    |>;
    If[!TrueQ[$AntennaPipelineBypassStoredResults] &&
        StoredResultsEnabledQ[useStored, storeStored, refreshStored],
      cacheKey = BuildAntennaObjectStoredResultKey[type,
        numFinalParticles, loopOrder, optionsAssoc];
      cacheLabel = BuildAntennaObjectStoredResultLabel[type,
        numFinalParticles, loopOrder, optionsAssoc];
      cacheRoot = OptionValue["ResultsCacheRoot"];
      If[!refreshStored && useStored,
        loaded = LoadStoredResultEntry["BuildAntennaObject", cacheKey,
          cacheRoot, cacheLabel];
        If[AssociationQ[loaded],
          PrintStoredResultHit[cacheLabel];
          Return[
            FormatStoredResultReturn[loaded["Result"],
              loaded["Diagnostics"], loaded, OptionValue[
                "ReturnDiagnostics"], requestedSteps,
              OptionValue["PrintIntermediateSteps"]]
          ]
        ]
      ];
      computed =
        Block[{$AntennaPipelineBypassStoredResults = True},
          BuildAntenna[type, numFinalParticles, loopOrder,
            ReturnDiagnostics -> True,
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
            ReductionBackend -> If[loopOrder === 1,
              ResolveIntegrableLoopBuildReductionBackend[
                {type, numFinalParticles, loopOrder},
                OptionValue["ReductionBackend"]]
              ,
              OptionValue["ReductionBackend"]
            ],
            Component -> OptionValue["Component"],
            IntermediateSteps -> OptionValue["IntermediateSteps"],
            PrintIntermediateSteps -> False,
            LoopMomenta -> OptionValue["LoopMomenta"],
            Contribution -> OptionValue["Contribution"],
            UseStoredResults -> False,
            StoreResults -> False,
            ResultsCacheRoot -> cacheRoot,
            RefreshStoredResults -> False]
        ];
      If[!MatchQ[computed, {_, _Association}],
        Return[computed]
      ];
      {result, diagnostics} = computed;
      If[result =!= $Failed && (storeStored || refreshStored),
        StoreStoredResultEntry["BuildAntennaObject", cacheKey, cacheRoot,
          cacheLabel, result, diagnostics]
      ];
      Return[
        FormatFreshBuildReturn[result, diagnostics, OptionValue[
            "ReturnDiagnostics"], requestedSteps, OptionValue[
            "PrintIntermediateSteps"]]
      ]
    ];
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
      ReductionBackend -> If[loopOrder === 1,
        ResolveIntegrableLoopBuildReductionBackend[
          {type, numFinalParticles, loopOrder},
          OptionValue["ReductionBackend"]]
        ,
        OptionValue["ReductionBackend"]
      ],
      Component -> OptionValue["Component"],
      IntermediateSteps -> OptionValue["IntermediateSteps"],
      PrintIntermediateSteps -> OptionValue["PrintIntermediateSteps"],
      LoopMomenta -> OptionValue["LoopMomenta"],
      Contribution -> OptionValue["Contribution"],
      UseStoredResults -> OptionValue["UseStoredResults"],
      StoreResults -> OptionValue["StoreResults"],
      ResultsCacheRoot -> OptionValue["ResultsCacheRoot"],
      RefreshStoredResults -> OptionValue["RefreshStoredResults"]]
  ];

BuildAntenna[type_, numFinalParticles_, loopOrder_, OptionsPattern[]] :=
  Module[{key, data, result, selectedResult, diagnostics, antennaObject,
     integrableRequested, reductionBackend, intermediateSteps,
     collectedSteps, useStored, storeStored, refreshStored, cacheKey,
     cacheLabel, cacheRoot, loaded, computed, optionsAssoc},
    useStored = TrueQ[OptionValue["UseStoredResults"]];
    storeStored = TrueQ[OptionValue["StoreResults"]];
    refreshStored = TrueQ[OptionValue["RefreshStoredResults"]];
    key = {type, numFinalParticles, loopOrder};
    intermediateSteps = NormalizeIntermediateSteps[OptionValue[
      "IntermediateSteps"]];
    optionsAssoc = <|
      "ReturnBuildData" -> OptionValue["ReturnBuildData"],
      "ReturnAntennaObject" -> OptionValue["ReturnAntennaObject"],
      "IntegrableForm" -> OptionValue["IntegrableForm"],
      "RunPaperCheck" -> OptionValue["RunPaperCheck"],
      "prefactor" -> OptionValue["prefactor"],
      "ApplyStripCouplings" -> OptionValue["ApplyStripCouplings"],
      "ApplyCasimirSubstitution" -> OptionValue[
        "ApplyCasimirSubstitution"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ReductionBackend" -> OptionValue["ReductionBackend"],
      "Component" -> OptionValue["Component"],
      "LoopMomenta" -> OptionValue["LoopMomenta"],
      "Contribution" -> OptionValue["Contribution"]
    |>;
    If[!TrueQ[$AntennaPipelineBypassStoredResults] &&
        StoredResultsEnabledQ[useStored, storeStored, refreshStored],
      cacheKey = BuildAntennaStoredResultKey[type, numFinalParticles,
        loopOrder, optionsAssoc];
      cacheLabel = BuildAntennaStoredResultLabel[type, numFinalParticles,
        loopOrder, optionsAssoc];
      cacheRoot = OptionValue["ResultsCacheRoot"];
      If[!refreshStored && useStored,
        loaded = LoadStoredResultEntry["BuildAntenna", cacheKey, cacheRoot,
          cacheLabel];
        If[AssociationQ[loaded],
          PrintStoredResultHit[cacheLabel];
          Return[
            FormatStoredResultReturn[loaded["Result"],
              loaded["Diagnostics"], loaded, OptionValue[
                "ReturnDiagnostics"], intermediateSteps, OptionValue[
                "PrintIntermediateSteps"]]
          ]
        ]
      ];
      computed =
        Block[{$AntennaPipelineBypassStoredResults = True},
          BuildAntenna[type, numFinalParticles, loopOrder,
            ReturnDiagnostics -> True,
            ReturnBuildData -> OptionValue["ReturnBuildData"],
            ReturnAntennaObject -> OptionValue["ReturnAntennaObject"],
            IntegrableForm -> OptionValue["IntegrableForm"],
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
            IntermediateSteps -> OptionValue["IntermediateSteps"],
            PrintIntermediateSteps -> False,
            LoopMomenta -> OptionValue["LoopMomenta"],
            Contribution -> OptionValue["Contribution"],
            UseStoredResults -> False,
            StoreResults -> False,
            ResultsCacheRoot -> cacheRoot,
            RefreshStoredResults -> False]
        ];
      If[MatchQ[computed, {_, _Association}],
        {result, diagnostics} = computed;
        If[result =!= $Failed && (storeStored || refreshStored),
          StoreStoredResultEntry["BuildAntenna", cacheKey, cacheRoot,
            cacheLabel, result, diagnostics]
        ];
        Return[
          FormatFreshBuildReturn[result, diagnostics, OptionValue[
              "ReturnDiagnostics"], intermediateSteps, OptionValue[
              "PrintIntermediateSteps"]]
        ]
      ];
      If[OptionValue["ReturnBuildData"] === True && computed =!= $Failed &&
          (storeStored || refreshStored),
        StoreStoredResultEntry["BuildAntenna", cacheKey, cacheRoot,
          cacheLabel, computed, <||>]
      ];
      Return[computed]
    ];
    integrableRequested =
      TrueQ[OptionValue["IntegrableForm"]] ||
      TrueQ[OptionValue["ReturnAntennaObject"]];
    reductionBackend =
      If[loopOrder === 1 && integrableRequested,
        ResolveIntegrableLoopBuildReductionBackend[key, OptionValue[
          "ReductionBackend"]]
        ,
        OptionValue["ReductionBackend"]
      ];
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
            "LoopMomentum"], ReductionBackend -> reductionBackend]
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
    If[integrableRequested,
      If[antennaObject === $Failed,
        diagnostics = BuildAntennaDiagnostics[key, result, data, OptionValue[
          "RunPaperCheck"]];
        collectedSteps = CollectBuildIntermediateSteps[data, result,
          selectedResult, $Failed, diagnostics, intermediateSteps];
        If[TrueQ[OptionValue["PrintIntermediateSteps"]] && Length[
            collectedSteps] > 0,
          PrintIntermediateStepsAssociation[collectedSteps]
        ];
        Return[
          If[OptionValue["ReturnDiagnostics"] === True,
            {$Failed, Join[diagnostics, <|"SelectedComponent" ->
                OptionValue["Component"], "Contribution" -> OptionValue[
                "Contribution"], "Failed" -> True,
                "Reason" -> "InvalidComponentSelection"|>,
              If[Length[collectedSteps] > 0,
                <|"IntermediateSteps" -> collectedSteps|>,
                <||>
              ]]}
            ,
            If[Length[collectedSteps] > 0,
              {$Failed, collectedSteps}
              ,
              $Failed
            ]
          ]
        ]
      ];
      diagnostics = BuildAntennaDiagnostics[key, result, data, OptionValue[
        "RunPaperCheck"]];
      collectedSteps = CollectBuildIntermediateSteps[data, result,
        selectedResult, antennaObject, diagnostics, intermediateSteps];
      If[TrueQ[OptionValue["PrintIntermediateSteps"]] && Length[
          collectedSteps] > 0,
        PrintIntermediateStepsAssociation[collectedSteps]
      ];
      If[OptionValue["ReturnDiagnostics"] === True,
        Return[{antennaObject, Join[diagnostics, <|"SelectedComponent" ->
              OptionValue["Component"], "Contribution" -> OptionValue[
              "Contribution"]|>,
            If[Length[collectedSteps] > 0,
              <|"IntermediateSteps" -> collectedSteps|>,
              <||>
            ]]}]
        ,
        Return[
          If[Length[collectedSteps] > 0,
            {antennaObject, collectedSteps}
            ,
            antennaObject
          ]
        ]
      ]
    ];
    diagnostics = BuildAntennaDiagnostics[key, result, data, OptionValue[
      "RunPaperCheck"]];
    collectedSteps = CollectBuildIntermediateSteps[data, result,
      selectedResult, antennaObject, diagnostics, intermediateSteps];
    If[TrueQ[OptionValue["PrintIntermediateSteps"]] && Length[
        collectedSteps] > 0,
      PrintIntermediateStepsAssociation[collectedSteps]
    ];
    If[OptionValue["ReturnDiagnostics"] === True,
      {selectedResult, Join[diagnostics, <|"SelectedComponent" -> OptionValue[
          "Component"]|>,
        If[Length[collectedSteps] > 0,
          <|"IntermediateSteps" -> collectedSteps|>,
          <||>
        ]]}
      ,
      If[Length[collectedSteps] > 0,
        {selectedResult, collectedSteps}
        ,
        selectedResult
      ]
    ]
  ];
