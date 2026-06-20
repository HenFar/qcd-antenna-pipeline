Get[FileNameJoin[{DirectoryName[DirectoryName[DirectoryName[$InputFileName]]],
  "AntennaPipeline.wl"}]];

results = {};

record[tag_, test_] :=
  Module[{passed},
    passed = TrueQ[test];
    AppendTo[results, <|"Tag" -> tag, "Passed" -> passed|>];
    Print[tag <> ": " <> If[passed, "PASS", "FAIL"]];
    passed
  ];

Print["=== 01_validate_effective_model.wl ==="];
record["model-files", D30EffectiveModelFilesExistQ[]];

insertions2 = D30EffectiveSourceInsertions[2];
insertions3 = D30EffectiveSourceInsertions[3];
record["insertions-1to2",
  Head[insertions2] =!= InsertFields && Length[insertions2] > 0];
record["insertions-1to3",
  Head[insertions3] =!= InsertFields && Length[insertions3] > 0];

amp2 = D30EffectiveSourceAmplitude[2];
amp3 = D30EffectiveSourceAmplitude[3];
record["amplitude-1to2", amp2 =!= $Failed && amp2 =!= 0];
record["amplitude-1to3", amp3 =!= $Failed && amp3 =!= 0];

a30 = BuildAntenna[A, 3, 0];
record["a30-regression", a30 =!= $Failed];
Print["diagram-count-1to2: ", Length[insertions2]];
Print["diagram-count-1to3: ", Length[insertions3]];

Print["=== 03_validate_source_structure.wl ==="];
groups = D30SourceAmplitudeTermGroups[];
groupAssoc = D30SourceAmplitudeGroupAssociation[];
record["group-contact-present", KeyExistsQ[groupAssoc, "Contact"]];
record["group-gluino-exchange-present",
  KeyExistsQ[groupAssoc, "GluinoExchange"]];
record["group-gluon-exchange-present",
  KeyExistsQ[groupAssoc, "GluonExchange"]];
record["group-contact-nonzero", groupAssoc["Contact"] =!= 0];
record["group-gluino-exchange-nonzero",
  groupAssoc["GluinoExchange"] =!= 0];
record["group-gluon-exchange-nonzero",
  groupAssoc["GluonExchange"] =!= 0];
ward2 = D30SourceWardIdentityZeroQ[2];
ward3 = D30SourceWardIdentityZeroQ[3];
Print["group-map: ", groups];
Print["ward-k2-zeroq: ", ward2];
Print["ward-k3-zeroq: ", ward3];
Print["ward-k2-groups: ", D30SourceWardGroupZeroQAssociation[2]];
Print["ward-k3-groups: ", D30SourceWardGroupZeroQAssociation[3]];

Print["=== 02_validate_source_route.wl ==="];
int2 = D30SourceSelfInterference[2];
record["source-born-interference",
  int2 =!= $Failed && Head[int2] =!= D30SourceSelfInterference];
int3 = TimeConstrained[D30SourceSelfInterference[3], 300, $Aborted];
record["source-production-interference",
  int3 =!= $Failed && int3 =!= $Aborted &&
    Head[int3] =!= D30SourceSelfInterference];
record["source-production-interference-color-reduced",
  FreeQ[int3, _SUNF | _SUNTF | _SUNDelta | _SUNTrace]
];
candidate = D30SourceAntennaCandidate[int2, int3];
record["source-candidate-built", candidate =!= $Failed];
Print["source-candidate numeric residual: ",
  ExactNumericResidual[D30Paper, candidate, 3]];
res = BuildAntenna[D, 3, 0, ReturnDiagnostics -> True];
record["source-route-remains-honest",
  MatchQ[res, {$Failed, _Association}] &&
  Lookup[Last[res], "Reason", Missing["MissingReason"]] ===
    "ExperimentalSourceRouteNotYetValidatedForRelease" &&
  Lookup[Last[res], "SourceRouteReadyQ", Missing["MissingReadyQ"]] === False &&
  Lookup[Last[res], "SourceCandidateExactMatchQ",
    Missing["MissingExactMatchQ"]] === False
];
Print["leaf-born: ", LeafCount[int2]];
Print["leaf-production: ", LeafCount[int3]];

If[AllTrue[results, Lookup[#, "Passed", False] &],
  Print["D30 validation summary: PASS"],
  Print["D30 validation summary: FAIL"];
  Quit[1]
];
