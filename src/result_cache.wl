(*************************************************)

(*
  Public result cache utilities.
  The computation pipeline remains the source of truth; this layer only
  stores and restores generated public-route outputs on disk.
*)

(*************************************************)

If[!ValueQ[$AntennaPipelineBypassStoredResults],
  $AntennaPipelineBypassStoredResults = False;
];

$AntennaPipelineStoredResultsSchemaVersion = 1;

DefaultStoredResultsRoot[] :=
  FileNameJoin[{$AntennaPipelineRoot, "stored_results"}];

ResolveStoredResultsRoot[root_] :=
  If[root === Automatic,
    DefaultStoredResultsRoot[]
    ,
    root
  ];

StoredResultsEnabledQ[useStored_, storeStored_, refreshStored_] :=
  TrueQ[useStored] || TrueQ[storeStored] || TrueQ[refreshStored];

StoredResultsSubdirectory["BuildAntenna"] := "build";

StoredResultsSubdirectory["BuildAntennaObject"] := "build_objects";

StoredResultsSubdirectory["IntegrateAntenna"] := "integrated";

StoredResultsSubdirectory["BuildAndIntegrateAntenna"] := "build_and_integrate";

StoredResultsSubdirectory["BuildRRatio"] := "rratio";

StoredResultsSubdirectory[routeKind_] :=
  StringReplace[ToLowerCase[routeKind], " " -> "_"];

NormalizeStoredResultKeyValue[value_] :=
  Which[
    AssociationQ[value],
      KeySort[Association @ KeyValueMap[
        #1 -> NormalizeStoredResultKeyValue[#2]&,
        value
      ]]
    ,
    ListQ[value],
      NormalizeStoredResultKeyValue /@ value
    ,
    MatchQ[value, _Rule | _RuleDelayed],
      NormalizeStoredResultKeyValue[First[value]] ->
        NormalizeStoredResultKeyValue[Last[value]]
    ,
    Head[value] === Symbol,
      SymbolName[Unevaluated[value]]
    ,
    MatchQ[value, _Missing],
      ToString[value, InputForm]
    ,
    True,
      value
  ];

StoredResultKeyAssociation[routeKind_String, request_Association] :=
  KeySort@Join[
    <|"RouteKind" -> routeKind|>,
    NormalizeStoredResultKeyValue[request]
  ];

StoredResultKeyHash[key_Association] :=
  IntegerString[
    Hash[HoldComplete[key], "SHA256"],
    16,
    64
  ];

SanitizeStoredResultLabel[label_String] :=
  Module[{sanitized},
    sanitized =
      StringReplace[
        ToLowerCase[label],
        {
          WhitespaceCharacter .. -> "-",
          "/" -> "-",
          ":" -> "-",
          "[" -> "",
          "]" -> "",
          "(" -> "",
          ")" -> "",
          "," -> "-",
          "." -> "-",
          "\"" -> "",
          "'" -> "",
          RegularExpression["[^a-z0-9_-]"] -> "-"
        }
      ];
    sanitized = StringReplace[sanitized, RegularExpression["-+"] -> "-"];
    StringTrim[sanitized, "-"]
  ];

StoredResultTypeLabel[type_] :=
  If[Head[type] === Symbol,
    SymbolName[Unevaluated[type]]
    ,
    ToString[type, InputForm]
  ];

StoredResultPath[routeKind_String, key_Association, root_, label_String] :=
  Module[{resolvedRoot, subdir, stem, hash},
    resolvedRoot = ResolveStoredResultsRoot[root];
    subdir = StoredResultsSubdirectory[routeKind];
    hash = StoredResultKeyHash[key];
    stem = StringTake[SanitizeStoredResultLabel[label], UpTo[48]];
    FileNameJoin[{resolvedRoot, subdir, stem <> "-" <> hash <> ".wl"}]
  ];

EnsureStoredResultsDirectory[path_String] :=
  Module[{dir},
    dir = DirectoryName[path];
    If[!DirectoryQ[dir],
      CreateDirectory[dir, CreateIntermediateDirectories -> True]
    ];
    dir
  ];

StoredResultPayload[result_, diagnostics_, routeKind_, key_Association,
   label_String] :=
  <|
    "SchemaVersion" -> $AntennaPipelineStoredResultsSchemaVersion,
    "RouteKind" -> routeKind,
    "RequestKey" -> key,
    "CreatedAt" -> DateString[{"ISODate", "T", "Time"}],
    "Label" -> label,
    "HasDiagnostics" -> AssociationQ[diagnostics],
    "Result" -> result,
    "Diagnostics" ->
      If[AssociationQ[diagnostics], diagnostics, <||>]
  |>;

StoredResultLoad[path_String] :=
  Module[{data},
    If[!FileExistsQ[path],
      Return[$Failed]
    ];
    data = Quiet[Check[Get[path], $Failed]];
    If[!AssociationQ[data],
      Return[$Failed]
    ];
    data
  ];

StoredResultPayloadValidQ[data_Association] :=
  Module[{result},
    result = Lookup[data, "Result", Missing["MissingResult"]];
    If[result === Missing["MissingResult"],
      Return[False]
    ];
    If[!FreeQ[result, Missing["KeyAbsent", __]],
      Return[False]
    ];
    True
  ];

LoadStoredResultEntry[routeKind_String, key_Association, root_, label_String] :=
  Module[{path, data},
    path = StoredResultPath[routeKind, key, root, label];
    data = StoredResultLoad[path];
    If[data === $Failed,
      Return[$Failed]
    ];
    If[Lookup[data, "SchemaVersion", Missing["MissingSchemaVersion"]] =!=
         $AntennaPipelineStoredResultsSchemaVersion ||
       Lookup[data, "RouteKind", Missing["MissingRouteKind"]] =!= routeKind ||
       Lookup[data, "RequestKey", Missing["MissingRequestKey"]] =!= key,
      Return[$Failed]
    ];
    If[!StoredResultPayloadValidQ[data],
      Return[$Failed]
    ];
    Join[data, <|"Path" -> path|>]
  ];

StoreStoredResultEntry[routeKind_String, key_Association, root_,
   label_String, result_, diagnostics_] :=
  Module[{path, payload},
    path = StoredResultPath[routeKind, key, root, label];
    EnsureStoredResultsDirectory[path];
    payload = StoredResultPayload[result, diagnostics, routeKind, key, label];
    Put[payload, path];
    path
  ];

StoredResultCacheMetadata[data_Association] :=
  <|
    "LoadedFromStoredResults" -> True,
    "Path" -> Lookup[data, "Path", Missing["UnknownPath"]],
    "CreatedAt" -> Lookup[data, "CreatedAt", Missing["UnknownCreatedAt"]],
    "SchemaVersion" -> Lookup[data, "SchemaVersion",
      Missing["UnknownSchemaVersion"]],
    "RouteKind" -> Lookup[data, "RouteKind", Missing["UnknownRouteKind"]],
    "Label" -> Lookup[data, "Label", Missing["UnknownLabel"]]
  |>;

SelectStoredIntermediateSteps[diagnostics_Association, requestedSteps_List] :=
  Module[{stored},
    stored = Lookup[diagnostics, "IntermediateSteps", <||>];
    If[!AssociationQ[stored],
      Return[<||>]
    ];
    Association @ KeyValueMap[
      If[RequestedIntermediateStepQ[requestedSteps, #1],
        #1 -> #2,
        Nothing
      ]&,
      stored
    ]
  ];

AnnotateStoredResultDiagnostics[diagnostics_Association, loadedData_Association,
   requestedSteps_List] :=
  Module[{stripped, cacheInfo, backendDiagnostics, timingDiagnostics,
     selectedSteps},
    stripped = KeyDrop[diagnostics, {"IntermediateSteps"}];
    cacheInfo = StoredResultCacheMetadata[loadedData];
    backendDiagnostics = Lookup[stripped, "BackendDiagnostics", Missing["Absent"]];
    If[AssociationQ[backendDiagnostics],
      timingDiagnostics = Lookup[backendDiagnostics, "TimingDiagnostics",
        Missing["Absent"]];
      If[AssociationQ[timingDiagnostics],
        backendDiagnostics =
          Join[
            backendDiagnostics,
            <|"TimingDiagnostics" ->
                Join[timingDiagnostics,
                  <|
                    "LoadedFromStoredResults" -> True,
                    "FreshRuntimeUnavailable" -> True
                  |>
                ]|>
          ];
        stripped = Join[stripped, <|"BackendDiagnostics" -> backendDiagnostics|>]
      ]
    ];
    selectedSteps = SelectStoredIntermediateSteps[diagnostics, requestedSteps];
    Join[
      stripped,
      <|"StoredResultCache" -> cacheInfo|>,
      If[Length[selectedSteps] > 0 || Length[requestedSteps] > 0,
        <|"IntermediateSteps" -> selectedSteps|>,
        <||>
      ]
    ]
  ];

PrintStoredResultHit[label_String] :=
  Print["Using stored result for ", label, "."];

FormatStoredResultReturn[result_, diagnostics_, loadedData_Association,
   returnDiagnostics_, requestedSteps_List, printSteps_] :=
  Module[{annotatedDiagnostics, selectedSteps},
    annotatedDiagnostics =
      If[AssociationQ[diagnostics],
        AnnotateStoredResultDiagnostics[diagnostics, loadedData,
          requestedSteps]
        ,
        <|"StoredResultCache" -> StoredResultCacheMetadata[loadedData]|>
      ];
    selectedSteps = Lookup[annotatedDiagnostics, "IntermediateSteps", <||>];
    If[TrueQ[printSteps] && AssociationQ[selectedSteps] && Length[
        selectedSteps] > 0,
      PrintIntermediateStepsAssociation[selectedSteps]
    ];
    If[TrueQ[returnDiagnostics],
      {result, annotatedDiagnostics}
      ,
      If[Length[requestedSteps] > 0,
        {result, selectedSteps}
        ,
        result
      ]
    ]
  ];
