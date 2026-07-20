(* ::Section:: *)

(* Integration-route orchestration *)

(* Communicates with:
   - src/core/profiles.wl and src/routes/route_catalog.wl for integration
     metadata and route stories.
   - src/engines/integration_pave.wl and src/engines/integration_ibp.wl for
     the actual backend integrations.
   - src/engines/integrated_antenna_extraction.wl for T-term and final
     integrated-antenna post-processing.
   - src/core/result_cache.wl for stored-result reuse and replay.
   - src/interface/integration_router.wl, which wraps these raw route results
     in the public API.
   - src/routes/massive_a30_integrated.wl for the special massive A30 branch.

   Why this file exists:
   Integration is where the package stops being a collection of isolated engines
   and becomes a user-facing pipeline: backend selection, cache behavior,
   component-by-component A22 stitching, and post-integration extraction all
   need to be coordinated in one place. *)

IntegrateBackendDirectRoute::usage = "IntegrateBackendDirectRoute[antenna, backend, options] evaluates the src direct integration route for a raw antenna expression.";

IntegrateRouteObject::usage = "IntegrateRouteObject[obj, options] evaluates the src integration route for an AntennaObject.";

BuildAndIntegrateRouteResult::usage = "BuildAndIntegrateRouteResult[type, n, l, options] evaluates the src build-and-integrate route before public formatting.";

IntegrationWrapperOptionContract::usage =
  "IntegrationWrapperOptionContract[] returns the disposition of every public integration option in BuildAndIntegrateAntenna: forwarded to IntegrateAntenna, applied at the wrapper boundary, or handled by the one-shot cache.";

BuildAndIntegrateIntegrationOptions::usage =
  "BuildAndIntegrateIntegrationOptions[options] converts one-shot integration settings into the rules supplied to IntegrateAntenna after the build stage.";

A22BuildIntegrationObject::usage = "A22BuildIntegrationObject[key, options, component] rebuilds a supported A22 source object for component-wise integration.";

A22BuildIntegrationObject[{type_, numFinalParticles_Integer, loopOrder_Integer
  }, options_Association, component_] :=
  BuildAntennaObject[type, numFinalParticles, loopOrder, Component ->
     component, quarkMass -> Lookup[options,
     "quarkMass", 0], ApplyDimReg -> Lookup[options, "ApplyDimReg", True],
     LoopMomentum -> Lookup[options, "LoopMomentum", l], UseStoredResults
     -> Lookup[options, "UseStoredResults", False], StoreResults -> Lookup[
    options, "StoreResults", False], ResultsCacheRoot -> Lookup[options,
    "ResultsCacheRoot", Automatic], RefreshStoredResults -> Lookup[options,
     "RefreshStoredResults", False], PrintIntermediateSteps -> False];

(* The one-shot function is a composition, not a separate integration API.
   Keep its option disposition explicit so additions to IntegrateAntenna cannot
   silently bypass the direct route.  Return shapes and cache handling belong
   to the wrapper; physics/backend controls are forwarded unchanged. *)
IntegrationWrapperOptionContract[] := <|
  ApplyFeynCalcMS -> "ForwardedToIntegrateAntenna",
  quarkMass -> "ForwardedToBuildAndIntegratePipeline",
  ExpansionOrder -> "ForwardedToIntegrateAntenna",
  KinematicScale -> "ForwardedToIntegrateAntenna",
  NormalizeKinematicScale -> "ForwardedToIntegrateAntenna",
  ReturnDiagnostics -> "AppliedAtWrapperReturnBoundary",
  ReturnRecord -> "AppliedAtWrapperReturnBoundary",
  ReturnMasterCombination -> "ForwardedToIntegrateAntenna",
  LoopMomentum -> "ForwardedToBuildAndIntegratePipeline",
  ApplyDimReg -> "ForwardedToBuildAndIntegratePipeline",
  BasisFamily -> "ForwardedToIntegrateAntenna",
  BasisRoot -> "ForwardedToIntegrateAntenna",
  GenerateMissingBases -> "ForwardedToIntegrateAntenna",
  ReturnTTerms -> "ForwardedToIntegrateAntenna",
  Component -> "ResolvedByBuildThenIntegratedAsSelectedObject",
  IntermediateSteps -> "ForwardedOrExpandedForWrapperRecord",
  PrintIntermediateSteps -> "ForwardedToIntegrateAntenna",
  DetailedTimingDiagnostics -> "ForwardedToIntegrateAntenna",
  UseStoredResults -> "HandledByWrapperCacheAndBuildStage",
  StoreResults -> "HandledByWrapperCacheAndBuildStage",
  ResultsCacheRoot -> "HandledByWrapperCacheAndBuildStage",
  RefreshStoredResults -> "HandledByWrapperCacheAndBuildStage"
|>;

BuildAndIntegrateIntegrationOptions[options_Association] := {
  ApplyFeynCalcMS -> Lookup[options, "ApplyFeynCalcMS", True],
  quarkMass -> Lookup[options, "quarkMass", 0],
  ExpansionOrder -> Lookup[options, "ExpansionOrder", Automatic],
  KinematicScale -> Lookup[options, "KinematicScale", q2],
  NormalizeKinematicScale -> Lookup[options, "NormalizeKinematicScale", True],
  ReturnDiagnostics -> True,
  ReturnRecord -> False,
  ReturnMasterCombination -> Lookup[options, "ReturnMasterCombination", False],
  LoopMomentum -> Lookup[options, "LoopMomentum", l],
  ApplyDimReg -> Lookup[options, "ApplyDimReg", True],
  BasisFamily -> Lookup[options, "BasisFamily", Automatic],
  BasisRoot -> Lookup[options, "BasisRoot", Automatic],
  GenerateMissingBases -> Lookup[options, "GenerateMissingBases", False],
  ReturnTTerms -> Lookup[options, "ReturnTTerms", False],
  IntermediateSteps -> If[TrueQ[Lookup[options, "ReturnRecord", False]],
    IntegrationRecordStepLabels[], Lookup[options, "IntermediateSteps", {}]],
  PrintIntermediateSteps -> Lookup[options, "PrintIntermediateSteps", False],
  DetailedTimingDiagnostics -> Lookup[options, "DetailedTimingDiagnostics", False],
  Component -> All
};

(* IntegrateBackendDirectRoute[antenna, integrationMethod, options]
   ================================================================
   Run one backend directly on a raw antenna expression, without any
   AntennaObject-level orchestration. *)

IntegrateBackendDirectRoute[antenna_, integrationMethod_, options_Association
  ] :=
  Module[{applyFeynCalcOpt, quarkMassOpt, profile, output, intermediateSteps,
     collectedSteps},
    applyFeynCalcOpt = Lookup[options, "ApplyFeynCalcMS", False];
    quarkMassOpt = Lookup[options, "quarkMass", 0];
    intermediateSteps = NormalizeIntermediateSteps[Lookup[options, "IntermediateSteps",
       {}]];
    profile =
      <|
        "DefaultBackend" -> integrationMethod
        ,
        "PaVeFamily" -> "MasslessTwoPartonVertex"
        ,
        "KinematicScale" -> Lookup[options, "KinematicScale", q2]
        ,
        "ExpansionOrder" ->
          If[Lookup[options, "ExpansionOrder", Automatic] === Automatic,

            2
            ,
            Lookup[options, "ExpansionOrder", 2]
          ]
      |>;
    output =
      Switch[integrationMethod,
        PaVe,
          IntegrateViaPaVe[antenna, profile, True, applyFeynCalcOpt,
            quarkMassOpt, PaVeEvaluation -> Lookup[profile, "PaVeEvaluation", "PaXEvaluate"
            ], ExpansionOrder -> profile["ExpansionOrder"], KinematicScale -> Lookup[
            options, "KinematicScale", q2], NormalizeKinematicScale -> Lookup[options,
             "NormalizeKinematicScale", False], LoopMomentum -> Lookup[options, "LoopMomentum",
             l], ApplyDimReg -> Lookup[options, "ApplyDimReg", True]]
        ,
        IBP,
          IntegrateViaIBP[antenna, ExpansionOrder -> profile["ExpansionOrder"
            ], BasisFamily -> Lookup[options, "BasisFamily", Automatic], BasisRoot
             -> Lookup[options, "BasisRoot", Automatic], GenerateMissingBases ->
            Lookup[options, "GenerateMissingBases", False], ReturnDiagnostics ->
            Lookup[options, "ReturnDiagnostics", False], DetailedTimingDiagnostics
             -> Lookup[options, "DetailedTimingDiagnostics", False], MassSymbol ->
             Lookup[profile, "MassSymbol", Automatic], ApplyFeynCalcMS -> Lookup[
            options, "ApplyFeynCalcMS", False], KinematicScale -> Lookup[options,
             "KinematicScale", q2], NormalizeKinematicScale -> Lookup[options, "NormalizeKinematicScale",
             False]]
        ,
        _,
          Print["Unsupported integration backend: ", integrationMethod,
             ". Aborting..."];
          $Failed
      ];
    output = SelectAntennaComponent[output, Missing["DirectIntegratedObject"
      ], Lookup[options, "Component", All]];
    collectedSteps = CollectIntegrationIntermediateSteps[antenna, Missing[
      "NotAvailable"], Missing["NotAvailable"], output, output, <||>, <||>,
       intermediateSteps];
    If[TrueQ[Lookup[options, "PrintIntermediateSteps", False]] && Length[
      collectedSteps] > 0,
      PrintIntermediateStepsAssociation[collectedSteps]
    ];
    If[Length[collectedSteps] > 0,
      {output, collectedSteps}
      ,
      output
    ]
  ];

(* IntegrateRouteObject[obj, options]
   ==================================
   Integrate one AntennaObject through the route layer, including backend
   selection, cache handling, diagnostics, and final post-processing. *)

IntegrateRouteObject[obj_, options_Association] :=
  Module[{data, key, profile, contributionInput, contribution, componentInput,
     componentName, storedComponent, backend, antenna, diagnostics, output,
     ibpResult, backendDiagnostics = <||>, rawIntegrated, tTerms, finalIntegrated,
     selectedIntegrated, expansionOrder, leadingCall, subleadingCall, nfCall,
     breveCall, leadingResult, subleadingResult, nfResult, breveResult, leadingDiag,
     subleadingDiag, nfDiag, breveDiag, treeDiags, intermediateSteps, collectedSteps,
     useStored, storeStored, refreshStored, cacheKey, cacheLabel, cacheRoot,
     loaded, computed, computedResult, computedDiagnostics, optionsAssoc,
     recordStages, recordMetadata, diagnosticsWithMetadata, ibpNeedsDiagnostics,
     quarkMassOpt, routeKind, progressActive, finishProgress, publicResult,
     publicDiagnostics},
    routeKind = Lookup[options, "RouteKind", "IntegrateAntenna"];
    If[!AntennaObjectQ[obj],
      diagnostics = <|"Failed" -> True, "Reason" -> "InvalidAntennaObject"
        |>;
      Return[FormatFreshIntegrationReturn[$Failed, diagnostics, Lookup[
        options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
         False], {}, False, routeKind, CollectIntegrationRecordStages[Missing[
        "NotAvailable"], $Failed, $Failed, $Failed, $Failed, <||>, diagnostics
        ]]]
    ];
    data = AntennaObjectData[obj];
    intermediateSteps = NormalizeIntermediateSteps[Lookup[options, "IntermediateSteps",
       {}]];
    useStored = TrueQ[Lookup[options, "UseStoredResults", False]];
    storeStored = TrueQ[Lookup[options, "StoreResults", False]];
    refreshStored = TrueQ[Lookup[options, "RefreshStoredResults", False
      ]];
    optionsAssoc = <|"ApplyFeynCalcMS" -> Lookup[options, "ApplyFeynCalcMS",
       False], "quarkMass" -> Lookup[options, "quarkMass", 0], "ExpansionOrder" ->
       Lookup[options, "ExpansionOrder", Automatic], "KinematicScale" -> Lookup[
      options, "KinematicScale", q2], "NormalizeKinematicScale" -> Lookup[options,
       "NormalizeKinematicScale", False], "LoopMomentum" -> Lookup[options,
       "LoopMomentum", l], "ApplyDimReg" -> Lookup[options, "ApplyDimReg",
      True], "BasisFamily" -> Lookup[options, "BasisFamily", Automatic], "BasisRoot"
       -> Lookup[options, "BasisRoot", Automatic], "GenerateMissingBases" ->
       Lookup[options, "GenerateMissingBases", False], "ReturnTTerms" -> Lookup[
      options, "ReturnTTerms", False], "ReturnMasterCombination" -> Lookup[
      options, "ReturnMasterCombination", False], "Component" -> Lookup[options,
       "Component", All], "DetailedTimingDiagnostics" -> Lookup[options, "DetailedTimingDiagnostics",
       False]|>;
    key = Lookup[data, "Key", Missing["UnknownKey"]];
    recordMetadata = <|"Key" -> key, "SelectedComponent" -> Lookup[options,
       "Component", All], "ContributionsUsed" -> AntennaContributionsUsed[key,
       Lookup[options, "Component", Lookup[data, "SelectedComponent", All]]],
       "SourceObject" -> obj, "AntennaObject" -> obj, "RouteStory" ->
       IntegrationRouteStory[key]|>;
    componentInput =
      If[Lookup[options, "Component", All] === All,
        Lookup[data, "SelectedComponent", All]
        ,
        Lookup[options, "Component", All]
      ];
    contributionInput = AntennaInternalContribution[key, componentInput];
    recordMetadata = Join[recordMetadata,
      <|"SelectedComponent" -> componentInput,
        "ContributionsUsed" -> AntennaContributionsUsed[key, componentInput]|>];
(* Every public integration route reports its stages. Heavy routes retain

   the same detailed stages; lightweight routes now no longer appear idle.
  *)
    progressActive = True;
    If[key === Missing["UnknownKey"],
      diagnostics = <|"Failed" -> True, "Reason" -> "MissingAntennaObjectKey",
         "SourceObject" -> obj, "AntennaObject" -> obj|>;
      Return[FormatFreshIntegrationReturn[$Failed, diagnostics, Lookup[
        options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
         False], {}, False, routeKind, CollectIntegrationRecordStages[obj, $Failed,
         $Failed, $Failed, $Failed, <||>, diagnostics], recordMetadata]]
    ];
    If[!TrueQ[$AntennaPipelineBypassStoredResults] && StoredResultsEnabledQ[
      useStored, storeStored, refreshStored],
      cacheKey = IntegrateAntennaStoredResultKey[obj, optionsAssoc];
      cacheLabel = IntegrateAntennaStoredResultLabel[obj, optionsAssoc
        ];
      cacheRoot = Lookup[options, "ResultsCacheRoot", Automatic];
      If[!refreshStored && useStored,
        loaded = LoadStoredResultEntry["IntegrateAntenna", cacheKey,
          cacheRoot, cacheLabel];
        If[AssociationQ[loaded],
          PrintStoredResultHit[cacheLabel];
          Return[FormatStoredResultReturn[loaded["Result"], loaded["Diagnostics"
            ], loaded, Lookup[options, "ReturnDiagnostics", False], Lookup[options,
             "ReturnRecord", False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
             False], routeKind, recordMetadata]]
        ]
      ];
      computed =
        Block[{$AntennaPipelineBypassStoredResults = True},
          IntegrateRouteObject[obj, Join[options, <|"ReturnDiagnostics"
             -> True, "ReturnRecord" -> False, "IntermediateSteps" -> IntegrationRecordStepLabels[
            ], "PrintIntermediateSteps" -> Lookup[options, "PrintIntermediateSteps",
             False], "UseStoredResults" -> False, "StoreResults" -> False, "ResultsCacheRoot"
             -> cacheRoot, "RefreshStoredResults" -> False, "RouteKind" -> routeKind
            |>]]
        ];
      If[!MatchQ[computed, {_, _Association}],
        Return[computed]
      ];
      {computedResult, computedDiagnostics} = computed;
      If[computedResult =!= $Failed && (storeStored || refreshStored),

        StoreStoredResultEntry["IntegrateAntenna", cacheKey, cacheRoot,
           cacheLabel, computedResult, computedDiagnostics]
      ];
      Return[FormatFreshIntegrationReturn[computedResult, computedDiagnostics,
         Lookup[options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
         False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
         False], routeKind, Automatic, recordMetadata]]
    ];
    quarkMassOpt = Lookup[options, "quarkMass", 0];
    MaybeWarnHeavyIntegrationRoute[key, Lookup[data, "SelectedComponent",
       All], AntennaInternalContribution[key, Lookup[data, "SelectedComponent", All]]];
    profile = AntennaIntegrationProfile[key];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 3, 0}] && quarkMassOpt
       =!= 0,
      profile = Join[profile, <|"BasisFamily" -> "MX30", "MassSymbol"
         -> quarkMassOpt|>]
    ];
    contribution = CanonicalAntennaComponentName[contributionInput];
    componentName = CanonicalAntennaComponentName[componentInput];
    (* Stage 6 is the public-return formatting event.  Do not emit a second
       6/6 "finished" line afterwards: it adds no state information and
       separates the master-basis legend from the single terminal stage. *)
    finishProgress := Null;
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] && contribution
       === "OneLoopSelf",
      profile = Join[profile, <|"BasisFamily" -> "A22OneLoopSelf", "ImplementationStatus"
         -> "ExperimentalOneLoopSelfOnly"|>]
    ];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] && contribution
       === "TwoLoopTree",
      profile = Join[profile, <|"BasisFamily" -> "A22TwoLoopTree", "ImplementationStatus"
         -> "ExperimentalTwoLoopTree"|>]
    ];
    If[TrueQ[progressActive],
      heavyIntegrationProgressPrint[routeKind, key, componentInput, contributionInput,
         1, 6, "resolving route profile"]
    ];
    expansionOrder =
      If[Lookup[options, "ExpansionOrder", Automatic] === Automatic,
        Lookup[profile, "ExpansionOrder", 0]
        ,
        Lookup[options, "ExpansionOrder", 0]
      ];
(* Massive A30 is currently a special route: unless the caller explicitly

   forces the IBP master route, the package uses the dedicated integrated

   bridge module rather than the generic backend path. *)
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 3, 0}] && quarkMassOpt
       =!= 0 && !TrueQ[$MassiveA30ForceIBPMasterRoute],
      Module[{routeData, antennaLocal, openMasterBackendDiagnostics},

        antennaLocal = Lookup[data, "Antenna", $Failed];
        routeData = MassiveA30IntegratedRouteData[quarkMassOpt, expansionOrder,
           Lookup[options, "NormalizeKinematicScale", False], profile];
        rawIntegrated = routeData["RawIntegrated"];
        tTerms = routeData["TTerms"];
        finalIntegrated = routeData["FinalIntegrated"];
        selectedIntegrated = routeData["SelectedIntegrated"];
        backendDiagnostics = routeData["BackendDiagnostics"];
        diagnostics = routeData["Diagnostics"];
        openMasterBackendDiagnostics = MassiveA30OpenMasterBackendDiagnostics[
          obj, options, routeKind];
        If[AssociationQ[openMasterBackendDiagnostics] && Length[openMasterBackendDiagnostics
          ] > 0,
          backendDiagnostics = Join[backendDiagnostics, openMasterBackendDiagnostics
            ];
          diagnostics = Join[diagnostics, <|"BackendDiagnostics" -> backendDiagnostics,
             "OpenMasterRouteAvailable" -> True|>]
        ];
        collectedSteps = CollectIntegrationIntermediateSteps[antennaLocal,
           rawIntegrated, tTerms, finalIntegrated, selectedIntegrated, backendDiagnostics,
           diagnostics, intermediateSteps];
        diagnosticsWithMetadata =
          Join[
            diagnostics
            ,
            <|"SelectedComponent" -> componentInput, "BuildComponent"
               -> storedComponent, "ContributionsUsed" -> AntennaContributionsUsed[key,
               componentInput], "RawIntegrated" -> rawIntegrated, "TTerms" -> tTerms,
               "SourceObject" -> obj, "AntennaObject" -> obj, "RouteStory" -> IntegrationRouteStory[
              key]|>
            ,
            If[Length[collectedSteps] > 0,
              <|"IntermediateSteps" -> collectedSteps|>
              ,
              <||>
            ]
          ];
        recordStages = CollectIntegrationRecordStages[antennaLocal, rawIntegrated,
           tTerms, finalIntegrated, selectedIntegrated, backendDiagnostics, diagnosticsWithMetadata
          ];
        Return[
          With[{
            publicReturn =
              If[TrueQ[Lookup[options, "ReturnMasterCombination", False
                ]],
                ResolveIntegrationPublicResult[selectedIntegrated, diagnosticsWithMetadata,
                   True, ToString[key, InputForm]]
                ,
                MassiveA30DefaultMasterEndpointResult[obj, options, routeKind,
                   selectedIntegrated, diagnosticsWithMetadata, ToString[key, InputForm
                  ]]
              ]
          },
            FormatFreshIntegrationReturn[publicReturn[[1]], publicReturn
              [[2]], Lookup[options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
               False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
               False], routeKind, recordStages, recordMetadata]
          ]
        ]
      ]
    ];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] && contribution
       === "All",
      Switch[componentName,
        "Leading" | "Subleading" | "Nf",
          Return[IntegrateRouteObject[A22BuildIntegrationObject[key,
            options, componentInput], Join[options, <|"Component" ->
             All, "RouteKind" -> routeKind|>]]]
        ,
        "Breve",
          Return[IntegrateRouteObject[A22BuildIntegrationObject[key,
            options, Breve], Join[options, <|"Component" -> All,
             "RouteKind" -> routeKind|>]]]
        ,
        "All",
          If[TrueQ[progressActive],
            heavyIntegrationProgressPrint[routeKind, key, componentInput,
               contributionInput, 2, 6, "integrating component branches"]
          ];
          leadingCall = IntegrateRouteObject[A22BuildIntegrationObject[
            key, options, Leading], Join[options, <|"ReturnDiagnostics"
             -> True, "Component" -> All, "RouteKind"
             -> routeKind|>]];
          subleadingCall = IntegrateRouteObject[A22BuildIntegrationObject[
            key, options, Subleading], Join[options, <|"ReturnDiagnostics"
             -> True, "Component" -> All, "RouteKind"
             -> routeKind|>]];
          nfCall = IntegrateRouteObject[A22BuildIntegrationObject[key,
             options, Nf], Join[options, <|"ReturnDiagnostics" -> True,
             "Component" -> All, "RouteKind" -> routeKind
            |>]];
          breveCall = IntegrateRouteObject[A22BuildIntegrationObject[
            key, options, Breve], Join[options, <|"ReturnDiagnostics"
             -> True, "Component" -> All, "RouteKind"
             -> routeKind|>]];
          {leadingResult, leadingDiag} = leadingCall;
          {subleadingResult, subleadingDiag} = subleadingCall;
          {nfResult, nfDiag} = nfCall;
          {breveResult, breveDiag} = breveCall;
          If[MemberQ[{leadingResult, subleadingResult, nfResult, breveResult
            }, $Failed],
            diagnosticsWithMetadata = <|"Failed" -> True, "Reason" ->
               "A22CombinedContributionIntegrationFailed", "ContributionDiagnostics" ->
               <|"TwoLoopTree" -> <|"Leading" -> leadingDiag, "Subleading" -> subleadingDiag,
               "Nf" -> nfDiag|>, "OneLoopSelf" -> breveDiag|>,
               "ContributionsUsed" -> AntennaContributionsUsed[key, All], "SourceObject" -> obj,
               "AntennaObject" -> obj, "RouteStory" -> IntegrationRouteStory[key]|>
              ;
            finishProgress;
            Return[FormatFreshIntegrationReturn[$Failed, diagnosticsWithMetadata,
               Lookup[options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
               False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
               False], routeKind, CollectIntegrationRecordStages[Lookup[data, "Antenna",
               $Failed], $Failed, $Failed, $Failed, $Failed, <|"TwoLoopTree" -> <|"Leading"
               -> leadingDiag, "Subleading" -> subleadingDiag, "Nf" -> nfDiag|>, "OneLoopSelf"
               -> breveDiag|>, diagnosticsWithMetadata], recordMetadata]]
          ];
          If[TrueQ[progressActive],
            heavyIntegrationProgressPrint[routeKind, key, componentInput,
               contributionInput, 3, 6, "combining integrated components"]
          ];
          finalIntegrated = A22CombineIntegratedResults[{leadingResult,
             subleadingResult, nfResult}, breveResult];
          treeDiags = <|"Leading" -> leadingDiag, "Subleading" -> subleadingDiag,
             "Nf" -> nfDiag|>;
          If[TrueQ[progressActive],
            heavyIntegrationProgressPrint[routeKind, key, componentInput,
               contributionInput, 4, 6, "collecting diagnostics"]
          ];
          diagnostics = A22CombineIntegratedComponentDiagnostics[treeDiags,
             breveDiag, finalIntegrated, componentInput, Lookup[options, "ReturnTTerms",
             False]];
          diagnosticsWithMetadata = Join[diagnostics, <|"SourceObject"
             -> obj, "AntennaObject" -> obj, "RouteStory" -> IntegrationRouteStory[
            key]|>];
          recordStages = CollectIntegrationRecordStages[Lookup[data,
            "Antenna", $Failed], Lookup[diagnostics, "RawIntegrated", Missing["NotAvailable"
            ]], Lookup[diagnostics, "TTerms", Missing["NotAvailable"]], finalIntegrated,
             finalIntegrated, <|"TwoLoopTree" -> treeDiags, "OneLoopSelf" -> breveDiag
            |>, diagnosticsWithMetadata];
          If[TrueQ[progressActive],
            heavyIntegrationProgressPrint[routeKind, key, componentInput,
               contributionInput, 6, 6, "formatting public return"]
          ];
          finishProgress;
          Return[FormatFreshIntegrationReturn[finalIntegrated, diagnosticsWithMetadata,
             Lookup[options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
             False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
             False], routeKind, recordStages, recordMetadata]]
      ]
    ];
    If[Lookup[profile, "ImplementationStatus", "Implemented"] === "ScaffoldOnly"
       && Lookup[profile, "BasisFamily", Missing["NoFamily"]] =!= "MX30",
      diagnostics = <|"Failed" -> True, "Reason" -> "IntegratedAntennaNotImplemented",
         "Profile" -> profile, "ContributionsUsed" -> AntennaContributionsUsed[key,
         componentInput]|>;
      finishProgress;
      Return[FormatFreshIntegrationReturn[$Failed, Join[diagnostics,
        <|"SourceObject" -> obj, "AntennaObject" -> obj, "RouteStory" -> IntegrationRouteStory[
        key]|>], Lookup[options, "ReturnDiagnostics", False], Lookup[options,
         "ReturnRecord", False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
         False], routeKind, CollectIntegrationRecordStages[Lookup[data, "Antenna",
         $Failed], $Failed, $Failed, $Failed, $Failed, <||>, diagnostics], recordMetadata
        ]]
    ];
    backend = profile["DefaultBackend"];
    storedComponent = Lookup[data, "SelectedComponent", All];
(* A selected AntennaObject is a public view, not a different integration

   problem.  In particular, the A31 extraction contains common terms that

   must be assembled before a colour component is selected. *)
    antenna = Lookup[data, "FullAntenna", Lookup[data, "Antenna", $Failed
      ]];
(* The unreplaced master combination is a backend diagnostic payload.  A

   direct public ReturnMasterCombination request must therefore retain the

   same IBP diagnostics that BuildAndIntegrateAntenna collects internally.

   Otherwise the later public-result resolver has nothing to expose.
  *)
    ibpNeedsDiagnostics = TrueQ[Lookup[options, "ReturnDiagnostics",
      False]] || TrueQ[Lookup[options, "ReturnRecord", False]] || TrueQ[Lookup[
      options, "ReturnMasterCombination", False]];
    If[TrueQ[progressActive],
      heavyIntegrationProgressPrint[routeKind, key, componentInput, contributionInput,
         2, 6, "running backend reduction"]
    ];
    rawIntegrated =
      Switch[backend,
        PaVe,
          IntegrateViaPaVe[antenna, profile, True, Lookup[options, "ApplyFeynCalcMS",
             False], Lookup[options, "quarkMass", 0], PaVeEvaluation -> Lookup[profile,
             "PaVeEvaluation", "PaXEvaluate"], ExpansionOrder -> expansionOrder, KinematicScale
             -> Lookup[profile, "KinematicScale", Lookup[options, "KinematicScale",
             q2]], NormalizeKinematicScale -> Lookup[options, "NormalizeKinematicScale",
             False], LoopMomentum -> Lookup[options, "LoopMomentum", l], ApplyDimReg
             -> Lookup[options, "ApplyDimReg", True]]
        ,
        IBP,
          ibpResult =
            IntegrateViaIBP[
              antenna
              ,
              NumFinalParticles -> key[[2]]
              ,
              NumLoops -> key[[3]]
              ,
              BasisFamily ->
                If[Lookup[options, "BasisFamily", Automatic] === Automatic,

                  Lookup[profile, "BasisFamily", Automatic]
                  ,
                  Lookup[options, "BasisFamily", Automatic]
                ]
              ,
              BasisRoot -> Lookup[options, "BasisRoot", Automatic]
              ,
              GenerateMissingBases -> Lookup[options, "GenerateMissingBases",
                 False]
              ,
              ExpansionOrder -> expansionOrder
              ,
              ReturnDiagnostics -> ibpNeedsDiagnostics
              ,
              DetailedTimingDiagnostics -> Lookup[options, "DetailedTimingDiagnostics",
                 False]
              ,
              MassSymbol -> Lookup[profile, "MassSymbol", Automatic]
              ,
              ApplyFeynCalcMS -> Lookup[options, "ApplyFeynCalcMS", False
                ]
              ,
              KinematicScale -> Lookup[profile, "KinematicScale", Lookup[
                options, "KinematicScale", q2]]
              ,
              NormalizeKinematicScale -> Lookup[options, "NormalizeKinematicScale",
                 False]
            ];
          If[TrueQ[ibpNeedsDiagnostics],
            backendDiagnostics = ibpResult[[2]];
            ibpResult[[1]]
            ,
            backendDiagnostics = <||>;
            ibpResult
          ]
        ,
        _,
          Print["Unsupported integration backend for antenna ", key,
            ": ", backend, ". Aborting..."];
          $Failed
      ];
    tTerms =
      If[rawIntegrated === $Failed,
        $Failed
        ,
        IntegratedAntennaTTerms[key, rawIntegrated, ExpansionOrder ->
           expansionOrder, Component -> All]
      ];
    If[TrueQ[progressActive],
      heavyIntegrationProgressPrint[routeKind, key, componentInput, contributionInput,
         3, 6, "constructing T-terms"]
    ];
    finalIntegrated =
      If[rawIntegrated === $Failed,
        $Failed
        ,
        If[Lookup[options, "ReturnTTerms", False] === True,
          tTerms
          ,
          ExtractIntegratedAntenna[key, tTerms, ExpansionOrder -> expansionOrder
            ]
        ]
      ];
    If[TrueQ[progressActive],
      heavyIntegrationProgressPrint[routeKind, key, componentInput, contributionInput,
         4, 6, "extracting integrated result"]
    ];
    selectedIntegrated = SelectAntennaComponent[finalIntegrated, key,
       componentInput];
    If[TrueQ[progressActive],
      heavyIntegrationProgressPrint[routeKind, key, componentInput, contributionInput,
         5, 6, "collecting diagnostics"]
    ];
    diagnostics =
      Join[
        IntegratedAntennaDiagnostics[key, antenna, finalIntegrated, profile,
           <|"RawIntegrated" -> rawIntegrated, "TTerms" -> tTerms, "ReturnTTerms"
           -> Lookup[options, "ReturnTTerms", False], "ExpansionOrder" -> expansionOrder,
           "SelectedComponent" -> componentInput, "BuildComponent" -> storedComponent
          |>]
        ,
        If[rawIntegrated === $Failed && AssociationQ[backendDiagnostics
          ] && KeyExistsQ[backendDiagnostics, "Reason"],
          <|"Failed" -> True, "Reason" -> backendDiagnostics["Reason"
            ]|>
          ,
          <||>
        ]
        ,
        If[AssociationQ[backendDiagnostics] && Length[backendDiagnostics
          ] > 0,
          <|"BackendDiagnostics" -> backendDiagnostics|>
          ,
          <||>
        ]
      ];
    collectedSteps = CollectIntegrationIntermediateSteps[antenna, rawIntegrated,
       tTerms, finalIntegrated, selectedIntegrated, backendDiagnostics, diagnostics,
       intermediateSteps];
    diagnosticsWithMetadata =
      Join[
        diagnostics
        ,
        <|"SelectedComponent" -> componentInput, "BuildComponent" ->
          storedComponent, "ContributionsUsed" -> AntennaContributionsUsed[key,
          componentInput], "RawIntegrated" -> rawIntegrated, "TTerms" -> tTerms,
           "SourceObject" -> obj, "AntennaObject" -> obj, "RouteStory" -> IntegrationRouteStory[
          key]|>
        ,
        If[Length[collectedSteps] > 0,
          <|"IntermediateSteps" -> collectedSteps|>
          ,
          <||>
        ]
      ];
    recordStages = CollectIntegrationRecordStages[antenna, rawIntegrated,
       tTerms, finalIntegrated, selectedIntegrated, backendDiagnostics, diagnosticsWithMetadata
      ];
    {publicResult, publicDiagnostics} = ResolveIntegrationPublicResult[
      selectedIntegrated, diagnosticsWithMetadata, Lookup[options, "ReturnMasterCombination",
       False], ToString[key, InputForm]];
    output = FormatFreshIntegrationReturn[publicResult, publicDiagnostics,
       Lookup[options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
       False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
       False], routeKind, recordStages, recordMetadata];
    If[TrueQ[progressActive],
      heavyIntegrationProgressPrint[routeKind, key, componentInput, contributionInput,
         6, 6, "formatting public return"]
    ];
    If[!TrueQ[$AntennaPipelineDeferMasterBasisPrint] && Lookup[publicDiagnostics,
       "RequestedResultKind", Missing["Absent"]] === "MasterCombination",
      PrintMasterCombinationBasisSummary[publicResult, publicDiagnostics
        ]
    ];
    finishProgress;
    output
  ];

(* BuildAndIntegrateRouteResult[type, numFinalParticles, loopOrder, options]
   =========================================================================
   Compose the build and integration routes end to end, while preserving the
   same cache and return-shape conventions as the standalone integration route. *)

BuildAndIntegrateRouteResult[type_, numFinalParticles_Integer, loopOrder_Integer,
   options_Association] :=
  Module[{key, profile, contribution, componentName, antennaObject, buildComponent,
     diagnostics, expansionOrder, intermediateSteps, useStored, storeStored,
     refreshStored, cacheKey, cacheLabel, cacheRoot, loaded, computed, computedResult,
     computedDiagnostics, optionsAssoc, recordMetadata, quarkMassOpt, integrationResult,
     integrationDiagnostics, buildOutput, buildDiagnostics, integrationObjects,
     integrationCalls, componentDiagnostics, integrateOptions},
    key = {type, numFinalParticles, loopOrder};
    intermediateSteps = NormalizeIntermediateSteps[Lookup[options, "IntermediateSteps",
       {}]];
    useStored = TrueQ[Lookup[options, "UseStoredResults", False]];
    storeStored = TrueQ[Lookup[options, "StoreResults", False]];
    refreshStored = TrueQ[Lookup[options, "RefreshStoredResults", False
      ]];
    optionsAssoc = <|"ApplyFeynCalcMS" -> Lookup[options, "ApplyFeynCalcMS",
       False], "quarkMass" -> Lookup[options, "quarkMass", 0], "ExpansionOrder" ->
       Lookup[options, "ExpansionOrder", Automatic], "KinematicScale" -> Lookup[
      options, "KinematicScale", q2], "NormalizeKinematicScale" -> Lookup[options,
       "NormalizeKinematicScale", False], "LoopMomentum" -> Lookup[options,
       "LoopMomentum", l], "ApplyDimReg" -> Lookup[options, "ApplyDimReg",
      True], "BasisFamily" -> Lookup[options, "BasisFamily", Automatic], "BasisRoot"
       -> Lookup[options, "BasisRoot", Automatic], "GenerateMissingBases" ->
       Lookup[options, "GenerateMissingBases", False], "ReturnTTerms" -> Lookup[
      options, "ReturnTTerms", False], "ReturnMasterCombination" -> Lookup[
      options, "ReturnMasterCombination", False], "Component" -> Lookup[options,
       "Component", All], "DetailedTimingDiagnostics" -> Lookup[options, "DetailedTimingDiagnostics",
       False]|>;
    recordMetadata = <|"Key" -> key, "SelectedComponent" -> Lookup[options,
       "Component", All], "ContributionsUsed" -> AntennaContributionsUsed[key,
       Lookup[options, "Component", All]], "RouteStory" -> IntegrationRouteStory[key]|>;
    If[!TrueQ[$AntennaPipelineBypassStoredResults] && StoredResultsEnabledQ[
      useStored, storeStored, refreshStored],
      cacheKey = BuildAndIntegrateStoredResultKey[type, numFinalParticles,
         loopOrder, optionsAssoc];
      cacheLabel = BuildAndIntegrateStoredResultLabel[type, numFinalParticles,
         loopOrder, optionsAssoc];
      cacheRoot = Lookup[options, "ResultsCacheRoot", Automatic];
      If[!refreshStored && useStored,
        loaded = LoadStoredResultEntry["BuildAndIntegrateAntenna", cacheKey,
           cacheRoot, cacheLabel];
        If[AssociationQ[loaded],
          PrintStoredResultHit[cacheLabel];
          Return[FormatStoredResultReturn[loaded["Result"], loaded["Diagnostics"
            ], loaded, Lookup[options, "ReturnDiagnostics", False], Lookup[options,
             "ReturnRecord", False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
             False], "BuildAndIntegrateAntenna", recordMetadata]]
        ]
      ];
      computed =
        Block[{$AntennaPipelineBypassStoredResults = True},
          BuildAndIntegrateRouteResult[type, numFinalParticles, loopOrder,
             Join[options, <|"ReturnDiagnostics" -> True, "ReturnRecord" -> False,
             "IntermediateSteps" -> IntegrationRecordStepLabels[], "PrintIntermediateSteps"
             -> False, "UseStoredResults" -> False, "StoreResults" -> False, "ResultsCacheRoot"
             -> cacheRoot, "RefreshStoredResults" -> False|>]]
        ];
      If[!MatchQ[computed, {_, _Association}],
        Return[computed]
      ];
      {computedResult, computedDiagnostics} = computed;
      If[computedResult =!= $Failed && (storeStored || refreshStored),

        StoreStoredResultEntry["BuildAndIntegrateAntenna", cacheKey,
          cacheRoot, cacheLabel, computedResult, computedDiagnostics]
      ];
      Return[FormatFreshIntegrationReturn[computedResult, computedDiagnostics,
         Lookup[options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
         False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
         False], "BuildAndIntegrateAntenna", Automatic, recordMetadata]]
    ];
    MaybeWarnHeavyIntegrationRoute[key, Lookup[options, "Component", All],
      AntennaInternalContribution[key, Lookup[options, "Component", All]]];
    quarkMassOpt = Lookup[options, "quarkMass", 0];
    profile = AntennaIntegrationProfile[key];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 3, 0}] && quarkMassOpt
       =!= 0,
      profile = Join[profile, <|"BasisFamily" -> "MX30", "MassSymbol"
         -> quarkMassOpt|>]
    ];
    contribution = CanonicalAntennaComponentName[AntennaInternalContribution[key,
       Lookup[options, "Component", All]]];
    componentName = CanonicalAntennaComponentName[Lookup[options, "Component",
       All]];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] && contribution
       === "OneLoopSelf",
      profile = Join[profile, <|"BasisFamily" -> "A22OneLoopSelf", "ImplementationStatus"
         -> "ExperimentalOneLoopSelfOnly"|>]
    ];
    If[MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}] && contribution
       === "TwoLoopTree",
      profile = Join[profile, <|"BasisFamily" -> "A22TwoLoopTree", "ImplementationStatus"
         -> "ExperimentalTwoLoopTree"|>]
    ];
    expansionOrder =
      If[Lookup[options, "ExpansionOrder", Automatic] === Automatic,
        Lookup[profile, "ExpansionOrder", 0]
        ,
        Lookup[options, "ExpansionOrder", 0]
      ];
    If[Lookup[profile, "ImplementationStatus", "Implemented"] === "ScaffoldOnly"
       && Lookup[profile, "BasisFamily", Missing["NoFamily"]] =!= "MX30" &&
       !MatchQ[key, {a_Symbol /; SymbolName[a] === "A", 2, 2}],
      diagnostics = <|"Failed" -> True, "Reason" -> "IntegratedAntennaNotImplemented",
         "Profile" -> profile, "ContributionsUsed" -> AntennaContributionsUsed[key,
         Lookup[options, "Component", All]]|>;
      Return[FormatFreshIntegrationReturn[$Failed, diagnostics, Lookup[
        options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
         False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
         False], "BuildAndIntegrateAntenna", CollectIntegrationRecordStages[Missing[
        "NotAvailable"], $Failed, $Failed, $Failed, $Failed, <||>, diagnostics
        ], recordMetadata]]
    ];
    buildComponent = Lookup[options, "Component", All];
    heavyIntegrationProgressPrint["BuildAndIntegrateAntenna", key, Lookup[
      options, "Component", All], All, 1,
      3, "building antenna"];
(* This wrapper intentionally composes the two public operations.  It may

   not take a private build path: otherwise a selected component can reach

   a different integration algebra from the standalone API. *)
    buildOutput = BuildAntenna[type, numFinalParticles, loopOrder, ReturnDiagnostics
       -> True, IntegrableForm -> True, quarkMass -> Lookup[options, "quarkMass",
       0], ApplyDimReg -> Lookup[options, "ApplyDimReg", True], LoopMomentum
       -> Lookup[options, "LoopMomentum", l], PrintIntermediateSteps -> Lookup[
      options, "PrintIntermediateSteps", False], UseStoredResults -> Lookup[
      options, "UseStoredResults", False], StoreResults -> Lookup[options,
      "StoreResults", False], ResultsCacheRoot -> Lookup[options, "ResultsCacheRoot",
       Automatic], RefreshStoredResults -> Lookup[options, "RefreshStoredResults",
       False], Component -> buildComponent];
    If[MatchQ[buildOutput, {_, _Association}],
      {antennaObject, buildDiagnostics} = buildOutput
      ,
      antennaObject = buildOutput;
      buildDiagnostics = <||>
    ];
    If[antennaObject === $Failed,
      Return[FormatFreshIntegrationReturn[$Failed, <|"Failed" -> True,
         "Reason" -> "InvalidComponentSelection", "SelectedComponent" -> Lookup[
        options, "Component", All], "ContributionsUsed" -> AntennaContributionsUsed[key,
         Lookup[options, "Component", All]]|>, Lookup[options, "ReturnDiagnostics", False], Lookup[options,
         "ReturnRecord", False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
         False], "BuildAndIntegrateAntenna", CollectIntegrationRecordStages[Missing[
        "NotAvailable"], $Failed, $Failed, $Failed, $Failed, <||>, <|"Failed"
         -> True, "Reason" -> "InvalidComponentSelection", "SelectedComponent"
         -> Lookup[options, "Component", All], "ContributionsUsed" -> AntennaContributionsUsed[key,
         Lookup[options, "Component", All]]|>], recordMetadata]]
    ];
    heavyIntegrationProgressPrint["BuildAndIntegrateAntenna", key, Lookup[
      options, "Component", All], All, 2,
      3, "integrating antenna"];
    integrationObjects =
      If[ListQ[antennaObject],
        antennaObject
        ,
        {antennaObject}
      ];
    integrateOptions = BuildAndIntegrateIntegrationOptions[options];
    integrationCalls =
      Block[{$AntennaPipelineDeferMasterBasisPrint = True},
        (IntegrateAntenna[#, Sequence @@ integrateOptions]& /@ integrationObjects
          )
      ];
    If[!And @@ (MatchQ[#, {_, _Association}]& /@ integrationCalls),
      integrationResult = $Failed;
      integrationDiagnostics = Join[buildDiagnostics, <|"Failed" -> True,
         "Reason" -> "ComponentIntegrationFailed", "SourceObject" -> antennaObject,
         "AntennaObject" -> antennaObject|>]
      ,
      If[Length[integrationCalls] === 1,
        {integrationResult, integrationDiagnostics} = First[integrationCalls
          ];
        integrationDiagnostics = Join[buildDiagnostics, integrationDiagnostics,
           <|"SourceObject" -> antennaObject, "AntennaObject" -> antennaObject|>
          ]
        ,
        integrationResult = First /@ integrationCalls;
        componentDiagnostics = Last /@ integrationCalls;
        integrationDiagnostics = Join[buildDiagnostics, <|"ComponentDiagnostics"
           -> AssociationThread[CanonicalAntennaComponentName /@ (AntennaComponent
           /@ integrationObjects), componentDiagnostics], "SourceObject" -> antennaObject,
           "AntennaObject" -> antennaObject|>]
      ]
    ];
    heavyIntegrationProgressPrint["BuildAndIntegrateAntenna", key, Lookup[
      options, "Component", All], All, 3,
      3, "integration complete"];
    If[Lookup[integrationDiagnostics, "RequestedResultKind", Missing[
      "Absent"]] === "MasterCombination",
      PrintMasterCombinationBasisSummary[integrationResult, integrationDiagnostics
        ]
    ];
    FormatFreshIntegrationReturn[integrationResult, integrationDiagnostics,
       Lookup[options, "ReturnDiagnostics", False], Lookup[options, "ReturnRecord",
       False], intermediateSteps, Lookup[options, "PrintIntermediateSteps",
       False], "BuildAndIntegrateAntenna", Automatic, Join[recordMetadata,
      <|"SourceObject" -> antennaObject, "AntennaObject" -> antennaObject|>
      ]]
  ];
