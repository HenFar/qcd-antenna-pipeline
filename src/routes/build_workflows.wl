BuildRouteBuildData::usage =
  "BuildRouteBuildData[key, options] dispatches the src build route and returns the raw stage association before public formatting.";

BuildTreeRouteData::usage =
  "BuildTreeRouteData[key, options] runs the tree-level build workflow for the selected antenna.";

ResolveTreeSelfInterferenceRoute::usage =
  "ResolveTreeSelfInterferenceRoute[key, amp, profile] returns the tree-level self-interference used by the src route layer.";

BuildRouteBuildData[key_, options_Association] :=
  Module[{loopOrder},
    loopOrder = key[[3]];
    Switch[loopOrder,
      0,
        BuildTreeRouteData[key, options]
      ,
      1,
        BuildLoopAntennaData[key,
          printDiagram -> Lookup[options, "printDiagram", False],
          prefactor -> Lookup[options, "prefactor", 1],
          ApplyStripCouplings -> Lookup[options, "ApplyStripCouplings", AllCouplings],
          ApplyCasimirSubstitution -> Lookup[options, "ApplyCasimirSubstitution", True],
          ApplyDimReg -> Lookup[options, "ApplyDimReg", True],
          LoopMomentum -> Lookup[options, "LoopMomentum", l],
          ReductionBackend -> Lookup[options, "ReductionBackend", Automatic]
        ]
      ,
      2,
        BuildTwoLoopAntennaData[key,
          printDiagram -> Lookup[options, "printDiagram", False],
          prefactor -> Lookup[options, "prefactor", 1],
          ApplyStripCouplings -> Lookup[options, "ApplyStripCouplings", AllCouplings],
          ApplyCasimirSubstitution -> Lookup[options, "ApplyCasimirSubstitution", True],
          ApplyDimReg -> Lookup[options, "ApplyDimReg", True],
          LoopMomenta -> Lookup[options, "LoopMomenta", {l1, l2}],
          Contribution -> Lookup[options, "Contribution", All]
        ]
      ,
      _,
        <|
          "Profile" -> <|"Key" -> key, "RouteStory" -> BuildRouteStory[key]|>,
          "Components" -> <||>,
          "Diagnostics" -> <|"Failed" -> True, "Reason" -> "UnsupportedLoopOrder"|>
        |>
    ]
  ];

BuildTreeRouteData[key_, options_Association] :=
  Module[{profile, amp, context, fullInterference, fullExtraction, split,
     sectors, sectorInterference, extraction, colorOrderedData, diagnostics,
     referenceSector, referenceProfile, referenceInterference,
     referenceExtraction, output, quarkMassOpt},
    profile = AntennaProfile[key];
    quarkMassOpt = Lookup[options, "quarkMass", 0];
    If[key === {D, 3, 0},
      Return[
        If[TrueQ[Lookup[options, "UseSourceModelRoute", False]],
          BuildD30SourceBuildData[key]
          ,
          If[TrueQ[Lookup[options, "AllowPrototypeTargets", False]],
            BuildD30PaperBuildData[key,
              quarkMass -> quarkMassOpt,
              ApplyStripCouplings -> Lookup[options, "ApplyStripCouplings", AllCouplings],
              ApplyCasimirSubstitution -> Lookup[options, "ApplyCasimirSubstitution", True],
              ApplyDimReg -> Lookup[options, "ApplyDimReg", True],
              AllowPrototypeTargets -> True]
            ,
            BuildD30PendingBuildData[key]
          ]
        ]
      ]
    ];
    If[key === {A, 3, 0} && quarkMassOpt =!= 0,
      LoadMassiveA30Reconstruction[];
      Return[
        MassiveA30BuildData[
          quarkMass -> quarkMassOpt,
          ApplyStripCouplings -> Lookup[options, "ApplyStripCouplings", AllCouplings],
          ApplyCasimirSubstitution -> Lookup[options, "ApplyCasimirSubstitution", True],
          ApplyDimReg -> Lookup[options, "ApplyDimReg", True]
        ]
      ]
    ];
    amp = AntennaAmplitude[key];
    context = <|"BornInterference" -> BornInterference[]|>;
    output =
      Switch[profile["Production"],
        "SelfInterference",
          fullInterference = ResolveTreeSelfInterferenceRoute[key, amp, profile];
          extraction = ExtractAntennaComponents[fullInterference, profile, context];
          <|
            "Profile" -> Join[profile, <|"RouteStory" -> BuildRouteStory[key]|>],
            "Amplitude" -> amp,
            "Sectors" -> <||>,
            "Interferences" -> <|"Production" -> fullInterference|>,
            "Components" -> extraction["Components"],
            "Diagnostics" -> extraction["Diagnostics"]
          |>
        ,
        "ColorOrderedAntenna",
          fullInterference = ResolveTreeSelfInterferenceRoute[key, amp, profile];
          fullExtraction = ExtractAntennaComponents[fullInterference, profile, context];
          colorOrderedData = ColorOrderedAntenna[
            amp,
            AntennaAmplitude[{A, 2, 0}],
            profile["NumFinalParticles"],
            profile["ColorOrderedSpec"]
          ];
          diagnostics =
            If[colorOrderedData === $Failed,
              <|"Failed" -> True, "Reason" -> "ColorOrderedConstructionFailed"|>
              ,
              Join[fullExtraction["Diagnostics"], colorOrderedData["Diagnostics"]]
            ];
          <|
            "Profile" -> Join[profile, <|"RouteStory" -> BuildRouteStory[key]|>],
            "Amplitude" -> amp,
            "Sectors" -> <||>,
            "Interferences" -> <|"FullColor" -> fullInterference|>,
            "FullColorComponents" -> fullExtraction["Components"],
            "Components" ->
              If[colorOrderedData === $Failed,
                <|"Antenna" -> $Failed|>,
                <|"Antenna" -> colorOrderedData["Antenna"]|>
              ],
            "ColorOrderedData" -> colorOrderedData,
            "Diagnostics" -> diagnostics
          |>
        ,
        "SectorSelfInterference",
          fullInterference = ResolveTreeSelfInterferenceRoute[key, amp, profile];
          fullExtraction = ExtractAntennaComponents[fullInterference, profile, context];
          split = SplitAmplitudeBySectors[amp, profile];
          sectors = profile["ProductionSectors"];
          sectorInterference =
            If[
              split["Diagnostics"][sectors[[1]] <> "Terms"] > 0 &&
              split["Diagnostics"][sectors[[2]] <> "Terms"] > 0,
              InterfereMAmplitudes[
                split["Parts"][sectors[[1]]],
                split["Parts"][sectors[[2]]],
                profile["NumFinalParticles"],
                AntennaType -> profile["AntennaType"]
              ]
              ,
              $Failed
            ];
          extraction = ExtractAntennaComponents[sectorInterference, profile, context];
          diagnostics = Join[split["Diagnostics"], extraction["Diagnostics"]];
          <|
            "Profile" -> Join[profile, <|"RouteStory" -> BuildRouteStory[key]|>],
            "Amplitude" -> amp,
            "Sectors" -> split["Parts"],
            "Interferences" -> <|"Full" -> fullInterference, "Production" -> sectorInterference|>,
            "FullComponents" -> fullExtraction["Components"],
            "FullDiagnostics" -> fullExtraction["Diagnostics"],
            "Components" -> extraction["Components"],
            "Diagnostics" -> diagnostics
          |>
        ,
        "SectorSymmetrizedInterference",
          split = SplitAmplitudeBySectors[amp, profile];
          sectors = profile["ProductionSectors"];
          sectorInterference =
            If[
              split["Diagnostics"][sectors[[1]] <> "Terms"] > 0 &&
              split["Diagnostics"][sectors[[2]] <> "Terms"] > 0,
              SymmetrizedInterference[
                split["Parts"][sectors[[1]]],
                split["Parts"][sectors[[2]]],
                profile["NumFinalParticles"],
                profile["AntennaType"]
              ]
              ,
              $Failed
            ];
          extraction = ExtractAntennaComponents[sectorInterference, profile, context];
          referenceSector = Lookup[profile, "ReferenceSquareSector", Missing["NotAvailable"]];
          referenceProfile = AntennaProfile[Lookup[profile, "ReferenceSquareProfile", key]];
          referenceInterference =
            If[StringQ[referenceSector] && split["Diagnostics"][referenceSector <> "Terms"] > 0,
              InterfereMAmplitudes[
                split["Parts"][referenceSector],
                split["Parts"][referenceSector],
                profile["NumFinalParticles"],
                AntennaType -> profile["AntennaType"]
              ]
              ,
              $Failed
            ];
          referenceExtraction =
            ExtractAntennaComponents[referenceInterference, referenceProfile, context];
          diagnostics = Join[split["Diagnostics"], extraction["Diagnostics"]];
          <|
            "Profile" -> Join[profile, <|"RouteStory" -> BuildRouteStory[key]|>],
            "Amplitude" -> amp,
            "Sectors" -> split["Parts"],
            "Interferences" -> <|"Production" -> sectorInterference, "ReferenceSquare" -> referenceInterference|>,
            "Components" -> extraction["Components"],
            "Diagnostics" -> diagnostics,
            "ReferenceSquareComponents" -> referenceExtraction["Components"],
            "ReferenceSquareDiagnostics" -> referenceExtraction["Diagnostics"]
          |>
        ,
        _,
          <|
            "Profile" -> Join[profile, <|"RouteStory" -> BuildRouteStory[key]|>],
            "Amplitude" -> amp,
            "Sectors" -> <||>,
            "Interferences" -> <||>,
            "Components" -> <||>,
            "Diagnostics" -> <|"Failed" -> True, "Reason" -> "UnknownProductionMode"|>
          |>
      ];
    output
  ];

ResolveTreeSelfInterferenceRoute[key_, amp_, profile_Association] :=
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
    If[interference === $Failed || Head[interference] === AntennaSelfInterference,
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
