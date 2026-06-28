(*************************************************)

(*
  Public build interface.
  Communicates with:
    - src/routes/build_workflows.wl for the antenna-family build workflows.
    - src/routes/massive_a30_reconstruction.wl for the heavy A30 special case.
    - src/core/profiles.wl and src/core/result_cache.wl for route metadata and
      stored-result behavior.
    - src/interface/integration_router.wl, which consumes the AntennaObject
      and AntennaRunRecord wrappers defined here.

  Why this file exists:
    The route layer returns rich internal associations, but users need a stable
    public API that can return a plain expression, a selected component, an
    integrable object, or a replayable record.  This file is the adapter
    between those internal route associations and those public contracts.

  Internal one-loop build object.
  This association is for routing and diagnostics.  The public BuildAntenna
  wrapper below converts it back to the natural expression/list returned to
  the user.

  Expected shape of the returned association:
    "Profile"
      AntennaProfile[key] association used to drive later routing decisions.
    "TreeAmplitude" / "LoopAmplitude"
      Raw amplitude objects used to build the interference.
    "Interferences"
      Named intermediate interferences, usually keyed by contribution.
    "Components"
      Public-facing component association after extraction, e.g. Lead/SubLead.
    "Diagnostics"
      Build-side health and validation information.
    "NormalizedInterference"
      Optional scalar/color-normalized expression used by downstream logic.

  The intent is that all build routes, even failing ones, return the same broad
  record shape so diagnostics, caching, and public formatting do not need to
  special-case each antenna family.
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
  "BuildAntennaData[key, ...] assembles the raw build-side data association for a given antenna key.";

ResolvedTreeSelfInterference::usage =
  "ResolvedTreeSelfInterference[key, amp, profile] returns the tree self-interference for a route, falling back to a direct recomputation if the memoized symbol has gone inert.";

LoadMassiveA30Reconstruction::usage =
  "LoadMassiveA30Reconstruction[] loads the massive A30 reconstruction helper layer on demand for the public massive tree route.";

BuildD30PaperBuildData::usage =
  "BuildD30PaperBuildData[key, ...] returns the current paper-target-backed build association for the prototype D30 route.";

BuildD30PendingBuildData::usage =
  "BuildD30PendingBuildData[key] returns the honest failure record used while the repo-local D30 source model exists but the end-to-end antenna route has not yet been implemented.";

BuildD30SourceBuildData::usage =
  "BuildD30SourceBuildData[key] returns the source-amplitude and sourced-interference record used by the explicit D30 source-model reconstruction track.";

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

BuildAntennaPrototypeResult::usage =
  "BuildAntennaPrototypeResult[key, data] converts internal build data into the attached prototype or route-native result view.";

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

AntennaRunRecordQ::usage =
  "AntennaRunRecordQ[expr] returns True when expr is a valid AntennaRunRecord wrapper.";

longBuildRouteQ[key_] :=
  MemberQ[{{A, 3, 1}, {A, 2, 2}, {A, 4, 0}, {B, 4, 0}, {C, 4, 0}}, key];

buildRouteProgressLabel[key_, component_, contribution_] :=
  StringJoin[
    ToString[key, InputForm],
    " with Component -> ",
    CanonicalAntennaComponentName[component],
    ", Contribution -> ",
    CanonicalAntennaComponentName[contribution]
  ];

buildRouteProgressPrint[key_, component_, contribution_, current_Integer,
   total_Integer, label_String] :=
  Print[
    "[", DateString[{"ISODate", " ", "Time"}], "] ",
    "BuildAntenna [", current, "/", total, "]: ", label, " ",
    buildRouteProgressLabel[key, component, contribution]
  ];

AntennaRunRecordData::usage =
  "AntennaRunRecordData[record] returns the association stored inside an AntennaRunRecord.";

AntennaRunRecordValue::usage =
  "AntennaRunRecordValue[record, key] returns one named field from an AntennaRunRecord.";

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

BuildRecordStepLabels::usage =
  "BuildRecordStepLabels[] returns the canonical build-side stages included automatically in ReturnRecord mode.";

IntegrationRecordStepLabels::usage =
  "IntegrationRecordStepLabels[] returns the canonical integration-side stages included automatically in ReturnRecord mode.";

CollectBuildRecordStages::usage =
  "CollectBuildRecordStages[data, fullResult, selectedResult, antennaObject, diagnostics] collects the full build-side stages included in an AntennaRunRecord.";

CollectIntegrationRecordStages::usage =
  "CollectIntegrationRecordStages[antenna, rawIntegrated, tTerms, finalIntegrated, selectedIntegrated, backendDiagnostics, diagnostics] collects the full integration-side stages included in an AntennaRunRecord.";

MakeAntennaRunRecord::usage =
  "MakeAntennaRunRecord[assoc] wraps an association in the public AntennaRunRecord container.";

BuildRunRecord::usage =
  "BuildRunRecord[routeKind, result, diagnostics, stages, metadata] constructs a build-side AntennaRunRecord.";

IntegrationRunRecord::usage =
  "IntegrationRunRecord[routeKind, result, diagnostics, stages, metadata] constructs an integration-side AntennaRunRecord with the physics-facing aliases promoted from backend diagnostics when available.";

RetagAntennaRunRecord::usage =
  "RetagAntennaRunRecord[record, routeKind, metadata] rewrites the route metadata on an existing AntennaRunRecord.";

Options[BuildLoopAntennaData] = {printDiagram -> False, prefactor -> 
  1, ApplyStripCouplings -> AllCouplings, ApplyCasimirSubstitution -> True,
   ApplyDimReg -> True, LoopMomentum -> l, ReductionBackend -> Automatic};

Options[BuildTwoLoopAntennaData] = {printDiagram -> False, prefactor ->
  1, ApplyStripCouplings -> AllCouplings, ApplyCasimirSubstitution -> True,
   ApplyDimReg -> True, LoopMomenta -> {l1, l2}, Contribution -> All};

Options[BuildAntennaData] = {quarkMass -> 0, ApplyStripCouplings ->
  AllCouplings, ApplyCasimirSubstitution -> True, ApplyDimReg -> True,
  AllowPrototypeTargets -> False, UseSourceModelRoute -> False};

LoadMassiveA30Reconstruction[] :=
  Null;

BuildD30PaperBuildData[key_, opts:OptionsPattern[BuildAntennaData]] :=
  Module[{profile, antenna},
    profile = AntennaProfile[key];
    antenna = D30Paper // Together // Simplify;
    <|
      "Profile" -> profile,
      "Amplitude" -> Missing["EncodedPaperTarget"],
      "Interferences" -> <|"Production" -> Missing["EncodedPaperTarget"]|>,
      "Components" -> <|"Antenna" -> antenna|>,
      "Diagnostics" -> <|
        "ConstructionMethod" -> "PaperTarget",
        "DimensionalForm" -> "FourDimensional",
        "Source" -> "hep-ph/0505111",
        "Experimental" -> True,
        "Unfinished" -> True,
        "ReleaseGuarantee" -> "Excluded",
        "ImplementationStatus" -> Lookup[profile,
          "ImplementationStatus", "Unknown"]
      |>
    |>
  ];

BuildD30PendingBuildData[key_] :=
  Module[{profile},
    profile = AntennaProfile[key];
    <|
      "Profile" -> profile,
      "Amplitude" -> Missing["NotYetDerivedFromSourceModel"],
      "Interferences" -> <|"Production" -> Missing["NotYetDerivedFromSourceModel"]|>,
      "Components" -> <|"Antenna" -> $Failed|>,
      "Diagnostics" -> <|
        "Failed" -> True,
        "Reason" -> "SourceModelOwnedButRouteNotImplemented",
        "ConstructionMethod" -> "SourceModelPending",
        "SourceModel" -> Lookup[profile, "SourceModel", Missing["UnknownModel"]],
        "Experimental" -> True,
        "Unfinished" -> True,
        "ReleaseGuarantee" -> "Excluded",
        "ImplementationStatus" -> Lookup[profile,
          "ImplementationStatus", "Unknown"]
      |>
    |>
  ];

BuildD30SourceBuildData[key_] :=
  Module[{profile, bornAmp, sourceAmp, orderedRouteData, bornInterference,
     sourceInterference, productionColorReducedQ, bornColorReducedQ,
     legacySourceCandidate, legacySourceCandidateExactMatchQ,
     legacySourceCandidateNumericResidual, sourceCandidate,
     sourceCandidateExactMatchQ, sourceCandidateNumericResidual,
     orderedAntennaExactMatchQ, exchangedOrderedAntennaExactMatchQ,
     sourceTermGroups, sourceWardK2ZeroQ, sourceWardK3ZeroQ,
     diagnostics, sourceRouteReadyQ, components, statusReason},
    profile = AntennaProfile[key];
    bornAmp = D30EffectiveSourceAmplitude[2];
    sourceAmp = D30EffectiveSourceAmplitude[3];
    orderedRouteData = ColorOrderedD30Antenna[
      sourceAmp,
      bornAmp,
      3,
      Lookup[profile, "ColorOrderedSpec", <|"Name" -> "D30", "NumGluons" -> 1|>]
    ];
    bornInterference = Missing["DeferredLegacyDiagnostics"];
    sourceInterference = Missing["DeferredLegacyDiagnostics"];
    bornColorReducedQ = Missing["DeferredLegacyDiagnostics"];
    productionColorReducedQ = Missing["DeferredLegacyDiagnostics"];
    legacySourceCandidate = Missing["DeferredLegacyDiagnostics"];
    legacySourceCandidateExactMatchQ = Missing["DeferredLegacyDiagnostics"];
    legacySourceCandidateNumericResidual = Missing["DeferredLegacyDiagnostics"];
    sourceCandidate =
      If[AssociationQ[orderedRouteData],
        orderedRouteData["Antenna"],
        $Failed
      ];
    orderedAntennaExactMatchQ =
      If[AssociationQ[orderedRouteData],
        Lookup[orderedRouteData["Diagnostics"], "OrderedAntennaExactMatchQ",
          False],
        False
      ];
    exchangedOrderedAntennaExactMatchQ =
      If[AssociationQ[orderedRouteData],
        Lookup[orderedRouteData["Diagnostics"],
          "ExchangedOrderedAntennaExactMatchQ", False],
        False
      ];
    sourceCandidateExactMatchQ =
      If[AssociationQ[orderedRouteData],
        Lookup[orderedRouteData["Diagnostics"], "FullAntennaExactMatchQ",
          False],
        False
      ];
    sourceCandidateNumericResidual =
      If[AssociationQ[orderedRouteData],
        Lookup[orderedRouteData["Diagnostics"], "FullAntennaNumericResidual",
          Missing["NotBuilt"]],
        Missing["NotBuilt"]
      ];
    sourceTermGroups = Missing["DeferredLegacyDiagnostics"];
    sourceWardK2ZeroQ = Missing["DeferredLegacyDiagnostics"];
    sourceWardK3ZeroQ = Missing["DeferredLegacyDiagnostics"];
    diagnostics = <|
      "ConstructionMethod" -> "OrderedColorStrippedSource",
      "SourceModel" -> Lookup[profile, "SourceModel", Missing["UnknownModel"]],
      "SourceBornAmplitudeBuilt" -> True,
      "SourceProductionAmplitudeBuilt" -> True,
      "OrderedBornPartialBuilt" -> AssociationQ[orderedRouteData],
      "OrderedProductionPartialBuilt" -> AssociationQ[orderedRouteData],
      "OrderedAntennaExactMatchQ" -> orderedAntennaExactMatchQ,
      "OrderedAntennaNumericResidual" ->
        If[AssociationQ[orderedRouteData],
          Lookup[orderedRouteData["Diagnostics"],
            "OrderedAntennaNumericResidual", Missing["NotBuilt"]],
          Missing["NotBuilt"]
        ],
      "ExchangedOrderedAntennaExactMatchQ" ->
        exchangedOrderedAntennaExactMatchQ,
      "ExchangedOrderedAntennaNumericResidual" ->
        If[AssociationQ[orderedRouteData],
          Lookup[orderedRouteData["Diagnostics"],
            "ExchangedOrderedAntennaNumericResidual",
            Missing["NotBuilt"]],
          Missing["NotBuilt"]
        ],
      "SourceBornInterferenceBuilt" -> Missing["DeferredLegacyDiagnostics"],
      "SourceProductionInterferenceBuilt" -> Missing["DeferredLegacyDiagnostics"],
      "SourceBornInterferenceColorReducedQ" -> bornColorReducedQ,
      "SourceProductionInterferenceColorReducedQ" -> productionColorReducedQ,
      "SourceCandidateExactMatchQ" -> sourceCandidateExactMatchQ,
      "SourceCandidateNumericResidual" -> sourceCandidateNumericResidual,
      "LegacySourceCandidateExactMatchQ" ->
        legacySourceCandidateExactMatchQ,
      "LegacySourceCandidateNumericResidual" ->
        legacySourceCandidateNumericResidual,
      "SourceTermGroups" -> sourceTermGroups,
      "SourceWardIdentityK2ZeroQ" -> sourceWardK2ZeroQ,
      "SourceWardIdentityK3ZeroQ" -> sourceWardK3ZeroQ,
      "LegacyBranchAgreementNumericResidual" ->
        Missing["DeferredLegacyDiagnostics"]
    |>;
    sourceRouteReadyQ = D30SourceRouteReadyQ[diagnostics];
    statusReason =
      If[sourceRouteReadyQ,
        None,
        "ExperimentalSourceRouteNotYetValidatedForRelease"
      ];
    components =
      <|"Antenna" -> If[sourceRouteReadyQ, sourceCandidate, $Failed]|>;
    <|
      "Profile" -> profile,
      "BornAmplitude" -> bornAmp,
      "Amplitude" -> sourceAmp,
      "SourceTermGroups" -> sourceTermGroups,
      "Interferences" -> <|
        "Born" -> bornInterference,
        "Production" -> sourceInterference,
        "OrderedBorn" ->
          If[AssociationQ[orderedRouteData],
            orderedRouteData["BornSquare"],
            Missing["NotBuilt"]
          ],
        "OrderedProduction" ->
          If[AssociationQ[orderedRouteData],
            orderedRouteData["OrderedSquare"],
            Missing["NotBuilt"]
          ],
        "OrderedProductionExchanged" ->
          If[AssociationQ[orderedRouteData],
            orderedRouteData["ExchangedOrderedSquare"],
            Missing["NotBuilt"]
          ]
      |>,
      "SourceCandidate" -> sourceCandidate,
      "LegacySourceCandidate" -> legacySourceCandidate,
      "OrderedRouteData" -> orderedRouteData,
      "Components" -> components,
      "Diagnostics" -> Join[
        diagnostics,
        <|
          "SourceRouteReadyQ" -> sourceRouteReadyQ,
          "Experimental" -> True,
          "Unfinished" -> Not[sourceRouteReadyQ],
          "ReleaseGuarantee" -> "Excluded",
          "Failed" -> Not[sourceRouteReadyQ],
          "Reason" -> statusReason,
          "ImplementationStatus" ->
            If[sourceRouteReadyQ,
              "OrderedColorStrippedSourceRouteValidatedButStillOutsideReleaseGuarantee",
              "OrderedColorStrippedSourceRouteBuiltButLiteratureMatchPending"
            ]
        |>
      ]
    |>
  ];

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
    (* Build-time reduction shape is chosen to match the integration backend:
       PaVe routes want a reduced PaVe object, while IBP routes keep the more
       explicit loop form so the basis-matching layer can still see it. *)
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
    (* Interference is computed before dimensional-regularization cleanup
       because the extraction layer may need to inspect the unreduced structure
       when deciding how the public components should be separated. *)
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
    (* Extraction is the step that turns a raw production interference into the
       stable public component names used across BuildAntenna, diagnostics, and
       IntegrateAntenna. *)
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

BuildAntennaData[key_, OptionsPattern[]] :=
  BuildTreeRouteData[
    key,
    <|
      "quarkMass" -> OptionValue["quarkMass"],
      "ApplyStripCouplings" -> OptionValue["ApplyStripCouplings"],
      "ApplyCasimirSubstitution" -> OptionValue["ApplyCasimirSubstitution"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "AllowPrototypeTargets" -> OptionValue["AllowPrototypeTargets"],
      "UseSourceModelRoute" -> OptionValue["UseSourceModelRoute"]
    |>
  ];

ResolvedTreeSelfInterference[key_, amp_, profile_Association] :=
  ResolveTreeSelfInterferenceRoute[key, amp, profile];
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
  ReturnRecord -> False,
  RunPaperCheck -> Automatic, Verbose -> False, printDiagram -> False,
  prefactor -> 1, quarkMass -> 0, ApplyStripCouplings -> AllCouplings,
  ApplyCasimirSubstitution -> True, ApplyDimReg -> True,
  LoopMomentum -> l, ReductionBackend -> Automatic, Component -> All,
  IntermediateSteps -> {}, PrintIntermediateSteps -> False,
  LoopMomenta -> {l1, l2}, Contribution -> All,
  AllowPrototypeTargets -> False, UseSourceModelRoute -> False,
  UseStoredResults -> False, StoreResults -> False,
  ResultsCacheRoot -> Automatic, RefreshStoredResults -> False};

Options[BuildAntennaObject] =
  DeleteCases[Options[BuildAntenna], ReturnRecord -> _];

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

(* NormalizeIntermediateSteps[steps]
   =================================
   Convert the user-facing step selector into the canonical internal list used
   by both build and integration routers. *)
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

BuildRecordStepLabels[] :=
  {"BuildData", "FullBuildResult", "SelectedBuildResult",
    "AntennaObject"};

IntegrationRecordStepLabels[] :=
  {"InputAntenna", "RawIntegrated", "TTerms", "FinalIntegrated",
    "SelectedIntegrated"};

(* CollectBuildIntermediateSteps[data, fullResult, selectedResult, antennaObject, diagnostics, steps]
   ================================================================================================
   Collect only the build stages explicitly requested by the caller. *)
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

CollectBuildRecordStages[data_Association, fullResult_, selectedResult_,
   antennaObject_, diagnostics_] :=
  <|
    "BuildData" -> data,
    "FullBuildResult" -> fullResult,
    "PrototypeBuildResult" -> BuildAntennaPrototypeResult[
      Lookup[Lookup[data, "Profile", <||>], "Key",
        Lookup[data, "Key", Missing["UnknownKey"]]],
      data
    ],
    "SelectedBuildResult" -> selectedResult,
    "AntennaObject" -> antennaObject
  |>;

CollectIntegrationRecordStages[antenna_, rawIntegrated_, tTerms_,
   finalIntegrated_, selectedIntegrated_, backendDiagnostics_, diagnostics_] :=
  <|
    "InputAntenna" -> antenna,
    "RawIntegrated" -> rawIntegrated,
    "TTerms" -> tTerms,
    "FinalIntegrated" -> finalIntegrated,
    "SelectedIntegrated" -> selectedIntegrated
  |>;

PresentRecordStepValueQ[value_] :=
  Which[
    MatchQ[value, Missing[__]],
      False
    ,
    AssociationQ[value],
      Length[value] > 0
    ,
    ListQ[value],
      True
    ,
    True,
      True
  ];

(* BuildRecordAmplitudeValue[data]
   ===============================
   Choose the most readable amplitude payload for a run record. *)
BuildRecordAmplitudeValue[data_Association] :=
  Module[{singleAmplitude, multiAmplitude},
    singleAmplitude = Lookup[data, "Amplitude", Missing["NotAvailable"]];
    If[PresentRecordStepValueQ[singleAmplitude],
      Return[singleAmplitude]
    ];
    multiAmplitude =
      Association @ DeleteCases[
        {
          If[KeyExistsQ[data, "TreeAmplitude"],
            "TreeAmplitude" -> data["TreeAmplitude"],
            Nothing
          ],
          If[KeyExistsQ[data, "LoopAmplitude"],
            "LoopAmplitude" -> data["LoopAmplitude"],
            Nothing
          ],
          If[KeyExistsQ[data, "TwoLoopAmplitude"],
            "TwoLoopAmplitude" -> data["TwoLoopAmplitude"],
            Nothing
          ]
        },
        Nothing
      ];
    Which[
      Length[multiAmplitude] === 0,
        Missing["NotAvailable"]
      ,
      Length[multiAmplitude] === 1,
        First[Values[multiAmplitude]]
      ,
      True,
        multiAmplitude
    ]
  ];

(* BuildRecordInterferenceValue[data]
   ==================================
   Choose the most readable interference payload for a run record. *)
BuildRecordInterferenceValue[data_Association] :=
  Module[{interferences},
    interferences = Lookup[data, "Interferences", Missing["NotAvailable"]];
    If[!AssociationQ[interferences],
      Return[interferences]
    ];
    Which[
      Length[interferences] === 0,
        Missing["NotAvailable"]
      ,
      Length[interferences] === 1,
        First[Values[interferences]]
      ,
      KeyExistsQ[interferences, "Production"],
        Join[<|"Production" -> interferences["Production"]|>,
          KeyDrop[interferences, {"Production"}]]
      ,
      True,
        interferences
    ]
  ];

RecordStageAssociation[rules_List] :=
  Association @ DeleteCases[
    rules,
    (_String -> value_) /; !PresentRecordStepValueQ[value]
  ];

BuildRecordIntermediateStepsView[data_Association, result_, resultLabel_String:"Result"] :=
  RecordStageAssociation[
    {
      "Amplitude" -> BuildRecordAmplitudeValue[data],
      "Interference" -> BuildRecordInterferenceValue[data],
      "SourceTermGroups" -> Lookup[data, "SourceTermGroups",
        Missing["NotAvailable"]],
      "SourceCandidate" -> Lookup[data, "SourceCandidate",
        Missing["NotAvailable"]],
      "BuildOutputBoundary" -> Lookup[data, "BuildOutputBoundary",
        Missing["NotAvailable"]],
      resultLabel -> result
    }
  ];

BuildRecordIntermediateStepsView[obj_AntennaObject, resultLabel_String:"BuiltAntenna"] :=
  Module[{data},
    data = AntennaObjectData[obj];
    BuildRecordIntermediateStepsView[
      Lookup[data, "BuildData", <||>],
      Lookup[data, "Antenna", Missing["NotAvailable"]],
      resultLabel
    ]
  ];

IntegrationMethodValue[diagnostics_Association] :=
  Lookup[Lookup[diagnostics, "Profile", <||>], "DefaultBackend",
    Missing["NotAvailable"]];

IntegrationRecordIntermediateStepsView[routeKind_String,
   stages_Association, diagnostics_Association, metadata_Association:<||>] :=
  Module[{backendDiagnostics, masterCombination, dimensionExpression,
     resultValue, sourceObject, buildSteps},
    backendDiagnostics =
      Lookup[diagnostics, "BackendDiagnostics", Missing["NotAvailable"]];
    If[!AssociationQ[backendDiagnostics],
      backendDiagnostics = <||>
    ];
    masterCombination =
      Lookup[backendDiagnostics, "RawMasterCombination",
        Lookup[backendDiagnostics, "MasterMappedExpression",
          Missing["NotAvailable"]]];
    dimensionExpression =
      Lookup[backendDiagnostics, "MasterSubstitutedExpression",
        Missing["NotAvailable"]];
    resultValue =
      Lookup[stages, "SelectedIntegrated",
        Lookup[diagnostics, "SeriesResult", Missing["NotAvailable"]]];
    sourceObject =
      Lookup[metadata, "SourceObject",
        Lookup[metadata, "AntennaObject", Missing["NotAvailable"]]];
    buildSteps =
      If[routeKind === "BuildAndIntegrateAntenna" && AntennaObjectQ[sourceObject],
        BuildRecordIntermediateStepsView[sourceObject, "BuiltAntenna"]
        ,
        <||>
      ];
    Join[
      buildSteps,
      RecordStageAssociation[
        {
          "Method" -> IntegrationMethodValue[diagnostics],
          "MasterCombination" -> masterCombination,
          "DimensionExpression" -> dimensionExpression,
          "Result" -> resultValue
        }
      ]
    ]
  ];

IntegrationRecordAliases[stages_Association, diagnostics_Association] :=
  Module[{backendDiagnostics, masterCombination},
    backendDiagnostics =
      Lookup[stages, "BackendDiagnostics",
        Lookup[diagnostics, "BackendDiagnostics", Missing["NotAvailable"]]];
    If[!AssociationQ[backendDiagnostics],
      backendDiagnostics = <||>
    ];
    masterCombination =
      Lookup[backendDiagnostics, "RawMasterCombination",
        Lookup[backendDiagnostics, "MasterMappedExpression",
          Missing["NotAvailable"]]];
    <|
      "InputAntenna" -> Lookup[stages, "InputAntenna",
        Missing["NotAvailable"]],
      "RawIntegrated" -> Lookup[stages, "RawIntegrated",
        Lookup[diagnostics, "RawIntegrated", Missing["NotAvailable"]]],
      "TTerms" -> Lookup[stages, "TTerms",
        Lookup[diagnostics, "TTerms", Missing["NotAvailable"]]],
      "FinalIntegrated" -> Lookup[stages, "FinalIntegrated",
        Missing["NotAvailable"]],
      "SelectedIntegrated" -> Lookup[stages, "SelectedIntegrated",
        Missing["NotAvailable"]],
      "BackendDiagnostics" -> backendDiagnostics,
      "IntegrationDiagnostics" -> diagnostics,
      "IntegratedResultKind" -> Lookup[backendDiagnostics,
        "IntegratedResultKind", Missing["NotAvailable"]],
      "OpenMasterValuesQ" -> Lookup[backendDiagnostics,
        "OpenMasterValuesQ", Missing["NotAvailable"]],
      "RawLiteRedCombination" -> Lookup[backendDiagnostics,
        "RawLiteRedCombination", Missing["NotAvailable"]],
      "MasterMappedExpression" -> Lookup[backendDiagnostics,
        "MasterMappedExpression", Missing["NotAvailable"]],
      "RawMasterCombination" -> Lookup[backendDiagnostics,
        "RawMasterCombination", Missing["NotAvailable"]],
      "MasterCombination" -> masterCombination,
      "MasterSubstitutedExpression" -> Lookup[backendDiagnostics,
        "MasterSubstitutedExpression", Missing["NotAvailable"]],
      "NormalizedBeforeSeries" -> Lookup[backendDiagnostics,
        "NormalizedBeforeSeries", Missing["NotAvailable"]],
      "SeriesResult" -> Lookup[backendDiagnostics, "SeriesResult",
        Missing["NotAvailable"]],
      "OpenMasterRouteAvailable" -> Lookup[backendDiagnostics,
        "OpenMasterRouteAvailable", Missing["NotAvailable"]],
      "OpenMasterRouteSucceeded" -> Lookup[backendDiagnostics,
        "OpenMasterRouteSucceeded", Missing["NotAvailable"]],
      "OpenMasterSubstitutedExpression" -> Lookup[backendDiagnostics,
        "OpenMasterSubstitutedExpression", Missing["NotAvailable"]],
      "OpenMasterSeriesResult" -> Lookup[backendDiagnostics,
        "OpenMasterSeriesResult", Missing["NotAvailable"]],
      "OpenMasterRouteDiagnostics" -> Lookup[backendDiagnostics,
        "OpenMasterRouteDiagnostics", Missing["NotAvailable"]]
    |>
  ];

MakeAntennaRunRecord[assoc_Association] :=
  AntennaRunRecord[assoc];

AntennaRunRecord /: (record_AntennaRunRecord)[key_] :=
  AntennaRunRecordValue[record, key];

AntennaRunRecordQ[AntennaRunRecord[data_Association]] :=
  And[
    KeyExistsQ[data, "RouteKind"],
    KeyExistsQ[data, "Result"],
    KeyExistsQ[data, "Diagnostics"],
    KeyExistsQ[data, "IntermediateSteps"]
  ];

AntennaRunRecordQ[_] :=
  False;

AntennaRunRecordData[AntennaRunRecord[data_Association]] :=
  data;

AntennaRunRecordValue[record_AntennaRunRecord, key_] :=
  Lookup[AntennaRunRecordData[record], key,
    Missing["NotAvailable", key]];

(* BuildRunRecord[routeKind, result, diagnostics, stages, metadata]
   =================================================================
   Wrap a completed build call in the public AntennaRunRecord container. *)
BuildRunRecord[routeKind_String, result_, diagnostics_Association,
   stages_Association, metadata_Association:<||>] :=
  MakeAntennaRunRecord[
    Join[
      <|
        "RouteKind" -> routeKind,
        "Result" -> result,
        "Diagnostics" -> diagnostics,
        "IntermediateSteps" -> BuildRecordIntermediateStepsView[
          Lookup[stages, "BuildData", <||>],
          Lookup[stages, "SelectedBuildResult", result]
        ],
        "BuildData" -> Lookup[stages, "BuildData", Missing["NotAvailable"]],
        "FullBuildResult" -> Lookup[stages, "FullBuildResult",
          Missing["NotAvailable"]],
        "PrototypeBuildResult" -> Lookup[stages, "PrototypeBuildResult",
          Missing["NotAvailable"]],
        "SelectedBuildResult" -> Lookup[stages, "SelectedBuildResult",
          Missing["NotAvailable"]],
        "AntennaObject" -> Lookup[stages, "AntennaObject",
          Missing["NotAvailable"]],
        "BuildDiagnostics" -> diagnostics
      |>,
      metadata
    ]
  ];

(* IntegrationRunRecord[routeKind, result, diagnostics, stages, metadata]
   =======================================================================
   Wrap a completed integration call in the public AntennaRunRecord container,
   promoting backend-derived aliases when available. *)
IntegrationRunRecord[routeKind_String, result_, diagnostics_Association,
   stages_Association, metadata_Association:<||>] :=
  MakeAntennaRunRecord[
    Join[
      <|
        "RouteKind" -> routeKind,
        "Result" -> result,
        "Diagnostics" -> diagnostics,
        "IntermediateSteps" -> IntegrationRecordIntermediateStepsView[
          routeKind, stages, diagnostics, metadata
        ],
        "SourceObject" -> Lookup[metadata, "SourceObject",
          Lookup[diagnostics, "SourceObject", Missing["NotAvailable"]]],
        "AntennaObject" -> Lookup[metadata, "AntennaObject",
          Lookup[diagnostics, "AntennaObject", Missing["NotAvailable"]]],
        "StoredResultCache" -> Lookup[metadata, "StoredResultCache",
          Lookup[diagnostics, "StoredResultCache", Missing["NotAvailable"]]]
      |>,
      IntegrationRecordAliases[stages, diagnostics],
      metadata
    ]
  ];

RetagAntennaRunRecord[record_AntennaRunRecord, routeKind_String,
   metadata_Association:<||>] :=
  MakeAntennaRunRecord[
    Join[AntennaRunRecordData[record], <|"RouteKind" -> routeKind|>, metadata]
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

BuildOutputBoundaryAssociation[key_, data_Association] :=
  Module[{profile, conventionProfile, existingBoundary, publicBranch,
     prototypeBranch, publicComponents, prototypeComponents,
     implementationRelation},
    profile = Lookup[data, "Profile", <||>];
    conventionProfile = Lookup[profile, "ConventionProfile", <||>];
    existingBoundary = Lookup[data, "BuildOutputBoundary", <||>];
    publicBranch = Lookup[existingBoundary, "Public", <||>];
    prototypeBranch = Lookup[existingBoundary, "Prototype", <||>];
    publicComponents =
      Lookup[publicBranch, "Components",
        Lookup[data, "PublicComponents", Lookup[data, "Components", <||>]]];
    prototypeComponents =
      Lookup[prototypeBranch, "Components",
        Lookup[data, "PrototypeComponents",
          Lookup[data, "Components", publicComponents]]];
    implementationRelation =
      If[publicComponents === prototypeComponents,
        "Current route-native component payload is being promoted as both the public and prototype view until a route-specific semantic split is implemented.",
        "The route carries distinct public and prototype component payloads."
      ];
    <|
      "Public" -> Join[
        <|
          "Label" -> "Public",
          "ContractRole" -> "IntendedPublicResult",
          "Components" -> publicComponents,
          "RenormalizationStatus" -> Lookup[conventionProfile,
            "RenormalizationStatus", Missing["NotAvailable"]],
          "NormalizationStatus" -> Lookup[conventionProfile,
            "ScaleNormalizationStatus", Missing["NotAvailable"]],
          "StatusNote" ->
            "This branch is the package-facing build result used by BuildAntenna and AntennaObject by default."
        |>,
        KeyDrop[publicBranch, {"Label", "ContractRole", "Components",
          "RenormalizationStatus", "NormalizationStatus", "StatusNote"}]
      ],
      "Prototype" -> Join[
        <|
          "Label" -> "Prototype",
          "ContractRole" -> "PrototypeOrRouteNativeResult",
          "Components" -> prototypeComponents,
          "RenormalizationStatus" ->
            "Prototype or route-native state; may coincide with the public branch until a route-specific bare/pre-counterterm split exists.",
          "NormalizationStatus" ->
            "Prototype or route-native state; inspect route diagnostics before treating this branch as a stable convention boundary.",
          "StatusNote" ->
            "This branch preserves the route-native or provisional component payload for provenance, diagnostics, and later semantic repair."
        |>,
        KeyDrop[prototypeBranch, {"Label", "ContractRole", "Components",
          "RenormalizationStatus", "NormalizationStatus", "StatusNote"}]
      ],
      "CurrentImplementationRelation" -> implementationRelation,
      "Key" -> key
    |>
  ];

NormalizeBuildDataOutputBoundary[key_, data_Association] :=
  Module[{boundary},
    boundary = BuildOutputBoundaryAssociation[key, data];
    Join[
      data,
      <|
        "PublicComponents" -> Lookup[boundary["Public"], "Components", <||>],
        "PrototypeComponents" -> Lookup[boundary["Prototype"],
          "Components", <||>],
        "BuildOutputBoundary" -> boundary
      |>
    ]
  ];

NormalizeBuildDataOutputBoundary[_, data_] :=
  data;

BuildAntennaResultFromBranch[key_, data_Association, branch_String] :=
  Module[{branchAssociation, components},
    branchAssociation =
      Lookup[Lookup[data, "BuildOutputBoundary", <||>], branch, <||>];
    components =
      Lookup[branchAssociation, "Components",
        Switch[branch,
          "Prototype",
            Lookup[data, "PrototypeComponents",
              Lookup[data, "Components", <||>]]
          ,
          _,
            Lookup[data, "PublicComponents",
              Lookup[data, "Components", <||>]]
        ]];
    BuildAntennaResultFromComponents[key, components, data]
  ];

BuildAntennaResultFromComponents[{A, 2, 0}, components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[{A, 3, 0}, components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[{A, 4, 0}, components_Association,
   data_Association] :=
  {components["Antenna"], data["FullColorComponents"]["SubLead"]};

BuildAntennaResultFromComponents[{B, 4, 0}, components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[{C, 4, 0}, components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[{D, 3, 0}, components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[{A, 2, 1}, components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[{A, 3, 1}, components_Association, ___] :=
  {components["Lead"], components["SubLead"], components["QuarkLoop"]};

BuildAntennaResultFromComponents[{A, 2, 2}, components_Association, ___] :=
  {components["Lead"], components["SubLead"], components["QuarkLoop"],
    components["Breve"]};

BuildAntennaResultFromComponents[
   {type_Symbol /; SymbolName[type] === "A", 2, 0},
   components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[
   {type_Symbol /; SymbolName[type] === "A", 3, 0},
   components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[
   {type_Symbol /; SymbolName[type] === "A", 4, 0},
   components_Association, data_Association] :=
  {components["Antenna"], data["FullColorComponents"]["SubLead"]};

BuildAntennaResultFromComponents[
   {type_Symbol /; SymbolName[type] === "B", 4, 0},
   components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[
   {type_Symbol /; SymbolName[type] === "C", 4, 0},
   components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[
   {type_Symbol /; SymbolName[type] === "D", 3, 0},
   components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[
   {type_Symbol /; SymbolName[type] === "A", 2, 1},
   components_Association, ___] :=
  components["Antenna"];

BuildAntennaResultFromComponents[
   {type_Symbol /; SymbolName[type] === "A", 3, 1},
   components_Association, ___] :=
  {components["Lead"], components["SubLead"], components["QuarkLoop"]};

BuildAntennaResultFromComponents[
   {type_Symbol /; SymbolName[type] === "A", 2, 2},
   components_Association, ___] :=
  {components["Lead"], components["SubLead"], components["QuarkLoop"],
    components["Breve"]};

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
      "quarkMass" -> Lookup[options, "quarkMass", 0],
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
    CanonicalAntennaComponentName[Lookup[options, "Contribution", All]], "-",
    StringReplace[ToString[Lookup[options, "quarkMass", 0], InputForm],
      {"/" -> "_", " " -> ""}]
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
      "quarkMass" -> Lookup[options, "quarkMass", 0],
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
    CanonicalAntennaComponentName[Lookup[options, "Contribution", All]], "-",
    StringReplace[ToString[Lookup[options, "quarkMass", 0], InputForm],
      {"/" -> "_", " " -> ""}]
  ];

(* FormatFreshBuildReturn[result, diagnostics, ...]
   ================================================
   Convert one freshly computed build result into the requested public return
   shape: plain result, `{result, diagnostics}`, or `AntennaRunRecord`. *)
FormatFreshBuildReturn[result_, diagnostics_, returnDiagnostics_,
   returnRecord_, requestedSteps_List, printSteps_, routeKind_String:"BuildAntenna",
   recordStages_:Automatic, recordMetadata_Association:<||>] :=
  Module[{selectedSteps, stages, record},
    selectedSteps = Lookup[diagnostics, "IntermediateSteps", <||>];
    If[TrueQ[returnRecord],
      stages =
        If[AssociationQ[recordStages],
          recordStages
          ,
          If[AssociationQ[selectedSteps], selectedSteps, <||>]
        ];
      record = BuildRunRecord[routeKind, result, diagnostics, stages,
        recordMetadata];
      If[TrueQ[printSteps] && AssociationQ[record["IntermediateSteps"]] &&
          Length[record["IntermediateSteps"]] > 0,
        PrintIntermediateStepsAssociation[record["IntermediateSteps"]]
      ];
      Return[record]
    ];
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

(* MakeAntennaObject[key, data, component, contribution]
   =====================================================
   Construct the metadata-rich AntennaObject consumed later by
   IntegrateAntenna[...]. *)
MakeAntennaObject[key_, data_Association, component_, contribution_] :=
  Module[{fullResult, selectedResult, prototypeFullResult,
     prototypeSelectedResult},
    fullResult = BuildAntennaResult[key, data];
    prototypeFullResult = BuildAntennaPrototypeResult[key, data];
    selectedResult = SelectAntennaComponent[fullResult, key, component];
    prototypeSelectedResult =
      SelectAntennaComponent[prototypeFullResult, key, component];
    If[selectedResult === $Failed,
      Return[$Failed]
    ];
    AntennaObject[
      <|
        "Key" -> key,
        "Profile" -> Lookup[data, "Profile", <|"Key" -> key|>],
        "BuildData" -> data,
        "FullAntenna" -> fullResult,
        "PrototypeFullAntenna" -> prototypeFullResult,
        "Antenna" -> selectedResult,
        "PrototypeAntenna" -> prototypeSelectedResult,
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

(* BuildAntennaResult[key, data]
   =============================
   Convert route-owned component associations into the canonical public result
   shape for each antenna family. *)

BuildAntennaResult[{A, 2, 0}, data_Association] :=
  BuildAntennaResultFromBranch[{A, 2, 0}, data, "Public"];

BuildAntennaResult[{A, 3, 0}, data_Association] :=
  BuildAntennaResultFromBranch[{A, 3, 0}, data, "Public"];

BuildAntennaResult[{A, 4, 0}, data_Association] :=
  BuildAntennaResultFromBranch[{A, 4, 0}, data, "Public"];

BuildAntennaResult[{B, 4, 0}, data_Association] :=
  BuildAntennaResultFromBranch[{B, 4, 0}, data, "Public"];

BuildAntennaResult[{C, 4, 0}, data_Association] :=
  BuildAntennaResultFromBranch[{C, 4, 0}, data, "Public"];

BuildAntennaResult[{D, 3, 0}, data_Association] :=
  BuildAntennaResultFromBranch[{D, 3, 0}, data, "Public"];

BuildAntennaResult[{A, 2, 1}, data_Association] :=
  BuildAntennaResultFromBranch[{A, 2, 1}, data, "Public"];

BuildAntennaResult[{A, 3, 1}, data_Association] :=
  BuildAntennaResultFromBranch[{A, 3, 1}, data, "Public"];

BuildAntennaResult[{A, 2, 2}, data_Association] :=
  BuildAntennaResultFromBranch[{A, 2, 2}, data, "Public"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 2, 0},
   data_Association] :=
  BuildAntennaResultFromBranch[{type, 2, 0}, data, "Public"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 3, 0},
   data_Association] :=
  BuildAntennaResultFromBranch[{type, 3, 0}, data, "Public"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 4, 0},
   data_Association] :=
  BuildAntennaResultFromBranch[{type, 4, 0}, data, "Public"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "B", 4, 0},
   data_Association] :=
  BuildAntennaResultFromBranch[{type, 4, 0}, data, "Public"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "C", 4, 0},
   data_Association] :=
  BuildAntennaResultFromBranch[{type, 4, 0}, data, "Public"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "D", 3, 0},
   data_Association] :=
  BuildAntennaResultFromBranch[{type, 3, 0}, data, "Public"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 2, 1},
   data_Association] :=
  BuildAntennaResultFromBranch[{type, 2, 1}, data, "Public"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 3, 1},
   data_Association] :=
  BuildAntennaResultFromBranch[{type, 3, 1}, data, "Public"];

BuildAntennaResult[{type_Symbol /; SymbolName[type] === "A", 2, 2},
   data_Association] :=
  BuildAntennaResultFromBranch[{type, 2, 2}, data, "Public"];

BuildAntennaPrototypeResult[key_, data_Association] :=
  BuildAntennaResultFromBranch[key, data, "Prototype"];

BuildAntennaDiagnostics[key_, result_, data_Association, runPaperCheck_
  ] :=
  Module[{paperDiagnostics, quarkMassOpt, boundary},
    quarkMassOpt = Lookup[data, "quarkMass",
      Lookup[Lookup[data, "Diagnostics", <||>], "quarkMass", 0]];
    boundary = Lookup[data, "BuildOutputBoundary", Missing["NotAvailable"]];
    paperDiagnostics =
      If[result === $Failed,
        <|"PaperCheckAvailable" -> False, "Skipped" -> "BuildFailed"|>
        ,
      If[key === {A, 3, 0} && quarkMassOpt =!= 0 && runPaperCheck =!= False,
        <|
          "PaperCheckAvailable" -> True,
          "ExactMatchQ" -> Lookup[Lookup[data, "Diagnostics", <||>],
            "ThesisExactMatchQ", Missing["NotAvailable"]],
          "Residual" -> Lookup[Lookup[data, "Diagnostics", <||>],
            "ThesisResidual", Missing["NotAvailable"]]
        |>
        ,
      If[TrueQ[runPaperCheck] || (runPaperCheck === Automatic && PaperCheckAvailableQ[
        key]),
        PaperDiagnosticsFor[key, result]
        ,
        <|"PaperCheckAvailable" -> False|>
      ]]];
    Join[data["Diagnostics"], <|
        "BuildOutputBoundary" -> boundary,
        "PaperDiagnostics" -> paperDiagnostics
      |>]
  ];

(* BuildAntennaObject[type, n, loopOrder, ...]
   ===========================================
   Public constructor for an AntennaObject that preserves enough metadata to
   support later integration, caching, and record replay. *)
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
      "quarkMass" -> OptionValue["quarkMass"],
      "ApplyStripCouplings" -> OptionValue["ApplyStripCouplings"],
      "ApplyCasimirSubstitution" -> OptionValue[
        "ApplyCasimirSubstitution"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ReductionBackend" -> OptionValue["ReductionBackend"],
      "Component" -> OptionValue["Component"],
      "LoopMomenta" -> OptionValue["LoopMomenta"],
      "Contribution" -> OptionValue["Contribution"],
      "AllowPrototypeTargets" -> OptionValue["AllowPrototypeTargets"],
      "UseSourceModelRoute" -> OptionValue["UseSourceModelRoute"]
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
                "ReturnDiagnostics"], False, requestedSteps,
              OptionValue["PrintIntermediateSteps"], "BuildAntennaObject"]
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
            quarkMass -> OptionValue["quarkMass"],
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
            AllowPrototypeTargets -> OptionValue["AllowPrototypeTargets"],
            UseSourceModelRoute -> OptionValue["UseSourceModelRoute"],
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
            "ReturnDiagnostics"], False, requestedSteps, OptionValue[
            "PrintIntermediateSteps"], "BuildAntennaObject"]
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
      quarkMass -> OptionValue["quarkMass"],
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
      AllowPrototypeTargets -> OptionValue["AllowPrototypeTargets"],
      UseSourceModelRoute -> OptionValue["UseSourceModelRoute"],
      UseStoredResults -> OptionValue["UseStoredResults"],
      StoreResults -> OptionValue["StoreResults"],
      ResultsCacheRoot -> OptionValue["ResultsCacheRoot"],
      RefreshStoredResults -> OptionValue["RefreshStoredResults"]]
  ];

(* BuildAntenna[type, n, loopOrder, ...]
   =====================================
   Main public constructor for unintegrated antenna expressions and build
   records. *)
BuildAntenna[type_, numFinalParticles_, loopOrder_, OptionsPattern[]] :=
  Module[{key, data, result, selectedResult, publicResult, diagnostics,
     diagnosticsWithMetadata, antennaObject, integrableRequested,
     reductionBackend, intermediateSteps, collectedSteps, recordStages,
     useStored, storeStored, refreshStored, cacheKey, cacheLabel, cacheRoot,
     loaded, computed, optionsAssoc, recordMetadata, progressActive},
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
      "quarkMass" -> OptionValue["quarkMass"],
      "ApplyStripCouplings" -> OptionValue["ApplyStripCouplings"],
      "ApplyCasimirSubstitution" -> OptionValue[
        "ApplyCasimirSubstitution"],
      "ApplyDimReg" -> OptionValue["ApplyDimReg"],
      "LoopMomentum" -> OptionValue["LoopMomentum"],
      "ReductionBackend" -> OptionValue["ReductionBackend"],
      "Component" -> OptionValue["Component"],
      "LoopMomenta" -> OptionValue["LoopMomenta"],
      "Contribution" -> OptionValue["Contribution"],
      "AllowPrototypeTargets" -> OptionValue["AllowPrototypeTargets"],
      "UseSourceModelRoute" -> OptionValue["UseSourceModelRoute"]
    |>;
    recordMetadata =
      <|"Key" -> key, "SelectedComponent" -> OptionValue["Component"],
        "Contribution" -> OptionValue["Contribution"],
        "quarkMass" -> OptionValue["quarkMass"]|>;
    progressActive = longBuildRouteQ[key];
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
                "ReturnDiagnostics"], OptionValue["ReturnRecord"],
              intermediateSteps, OptionValue["PrintIntermediateSteps"],
              "BuildAntenna",
              <|"Key" -> key, "SelectedComponent" -> OptionValue["Component"],
                "Contribution" -> OptionValue["Contribution"],
                "quarkMass" -> OptionValue["quarkMass"]|>]
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
            quarkMass -> OptionValue["quarkMass"],
            ApplyStripCouplings -> OptionValue["ApplyStripCouplings"],
            ApplyCasimirSubstitution -> OptionValue[
              "ApplyCasimirSubstitution"],
            ApplyDimReg -> OptionValue["ApplyDimReg"],
            LoopMomentum -> OptionValue["LoopMomentum"],
            ReductionBackend -> OptionValue["ReductionBackend"],
            Component -> OptionValue["Component"],
            IntermediateSteps -> If[StoredResultsEnabledQ[useStored,
                storeStored, refreshStored],
              BuildRecordStepLabels[],
              OptionValue["IntermediateSteps"]
            ],
            PrintIntermediateSteps -> False,
            LoopMomenta -> OptionValue["LoopMomenta"],
            Contribution -> OptionValue["Contribution"],
            AllowPrototypeTargets -> OptionValue["AllowPrototypeTargets"],
            UseSourceModelRoute -> OptionValue["UseSourceModelRoute"],
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
              "ReturnDiagnostics"], OptionValue["ReturnRecord"],
            intermediateSteps, OptionValue["PrintIntermediateSteps"],
            "BuildAntenna", Automatic, recordMetadata]
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
    If[TrueQ[progressActive],
      buildRouteProgressPrint[key, OptionValue["Component"],
        OptionValue["Contribution"], 1, 5, "resolving route setup"]
    ];
    If[TrueQ[progressActive],
      buildRouteProgressPrint[key, OptionValue["Component"],
        OptionValue["Contribution"], 2, 5, "building route data"]
    ];
    data =
      BuildRouteBuildData[
        key,
        <|
          "printDiagram" -> OptionValue["printDiagram"],
          "prefactor" -> OptionValue["prefactor"],
          "quarkMass" -> OptionValue["quarkMass"],
          "ApplyStripCouplings" -> OptionValue["ApplyStripCouplings"],
          "ApplyCasimirSubstitution" -> OptionValue["ApplyCasimirSubstitution"],
          "ApplyDimReg" -> OptionValue["ApplyDimReg"],
          "LoopMomentum" -> OptionValue["LoopMomentum"],
          "ReductionBackend" -> reductionBackend,
          "LoopMomenta" -> OptionValue["LoopMomenta"],
          "Contribution" -> OptionValue["Contribution"],
          "AllowPrototypeTargets" -> OptionValue["AllowPrototypeTargets"],
          "UseSourceModelRoute" -> OptionValue["UseSourceModelRoute"]
        |>
      ];
    data = NormalizeBuildDataOutputBoundary[key, data];
    If[TrueQ[progressActive],
      buildRouteProgressPrint[key, OptionValue["Component"],
        OptionValue["Contribution"], 3, 5, "extracting public result"]
    ];
    If[OptionValue["ReturnBuildData"] === True &&
        !TrueQ[OptionValue["ReturnRecord"]],
      Return[data]
    ];
    result = BuildAntennaResult[key, data];
    selectedResult = SelectAntennaComponent[result, key, OptionValue[
       "Component"]];
    antennaObject = MakeAntennaObject[key, data, OptionValue["Component"],
      OptionValue["Contribution"]];
    If[TrueQ[progressActive],
      buildRouteProgressPrint[key, OptionValue["Component"],
        OptionValue["Contribution"], 4, 5, "building diagnostics"]
    ];
    If[integrableRequested,
      If[antennaObject === $Failed,
        diagnostics = BuildAntennaDiagnostics[key, result, data, OptionValue[
          "RunPaperCheck"]];
        collectedSteps = CollectBuildIntermediateSteps[data, result,
          selectedResult, $Failed, diagnostics, intermediateSteps];
        recordStages = CollectBuildRecordStages[data, result, selectedResult,
          $Failed, diagnostics];
        diagnosticsWithMetadata =
          Join[diagnostics, <|"SelectedComponent" -> OptionValue[
                "Component"], "Contribution" -> OptionValue["Contribution"],
              "Failed" -> True, "Reason" -> "InvalidComponentSelection"|>,
            If[Length[collectedSteps] > 0,
              <|"IntermediateSteps" -> collectedSteps|>,
              <||>
            ]];
        Return[
          FormatFreshBuildReturn[$Failed, diagnosticsWithMetadata, OptionValue[
              "ReturnDiagnostics"], OptionValue["ReturnRecord"],
            intermediateSteps, OptionValue["PrintIntermediateSteps"],
            "BuildAntenna", recordStages, recordMetadata]
        ]
      ];
      diagnostics = BuildAntennaDiagnostics[key, result, data, OptionValue[
        "RunPaperCheck"]];
      collectedSteps = CollectBuildIntermediateSteps[data, result,
        selectedResult, antennaObject, diagnostics, intermediateSteps];
      recordStages = CollectBuildRecordStages[data, result, selectedResult,
        antennaObject, diagnostics];
      diagnosticsWithMetadata =
        Join[diagnostics, <|"SelectedComponent" -> OptionValue[
              "Component"], "Contribution" -> OptionValue["Contribution"]|>,
          If[Length[collectedSteps] > 0,
            <|"IntermediateSteps" -> collectedSteps|>,
            <||>
          ]];
      If[TrueQ[progressActive],
        buildRouteProgressPrint[key, OptionValue["Component"],
          OptionValue["Contribution"], 5, 5, "formatting public return"]
      ];
      Return[
        FormatFreshBuildReturn[antennaObject, diagnosticsWithMetadata,
          OptionValue["ReturnDiagnostics"], OptionValue["ReturnRecord"],
          intermediateSteps, OptionValue["PrintIntermediateSteps"],
          "BuildAntenna", recordStages,
          Join[recordMetadata, <|"AntennaObject" -> antennaObject|>]]
      ]
    ];
    diagnostics = BuildAntennaDiagnostics[key, result, data, OptionValue[
      "RunPaperCheck"]];
    collectedSteps = CollectBuildIntermediateSteps[data, result,
      selectedResult, antennaObject, diagnostics, intermediateSteps];
    publicResult =
      If[TrueQ[OptionValue["ReturnBuildData"]],
        data
        ,
        selectedResult
      ];
    recordStages = CollectBuildRecordStages[data, result, selectedResult,
      antennaObject, diagnostics];
    diagnosticsWithMetadata =
      Join[diagnostics, <|"SelectedComponent" -> OptionValue["Component"],
          "Contribution" -> OptionValue["Contribution"]|>,
        If[Length[collectedSteps] > 0,
          <|"IntermediateSteps" -> collectedSteps|>,
          <||>
        ]];
    If[TrueQ[progressActive],
      buildRouteProgressPrint[key, OptionValue["Component"],
        OptionValue["Contribution"], 5, 5, "formatting public return"]
    ];
    FormatFreshBuildReturn[publicResult, diagnosticsWithMetadata, OptionValue[
        "ReturnDiagnostics"], OptionValue["ReturnRecord"], intermediateSteps,
      OptionValue["PrintIntermediateSteps"], "BuildAntenna", recordStages,
      Join[recordMetadata, <|"AntennaObject" -> antennaObject|>]]
  ];
