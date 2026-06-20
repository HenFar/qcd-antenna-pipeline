Get[FileNameJoin[{DirectoryName[DirectoryName[DirectoryName[$InputFileName]]], "AntennaPipeline.wl"}]];
validate[tag_, test_] := If[TrueQ[test], Print[tag <> ": PASS"], Print[tag <> ": FAIL"]; Quit[1]];
int2 = D30SourceSelfInterference[2];
validate["source-born-interference", int2 =!= $Failed && Head[int2] =!= D30SourceSelfInterference];
int3 = TimeConstrained[D30SourceSelfInterference[3], 300, $Aborted];
validate["source-production-interference", int3 =!= $Failed && int3 =!= $Aborted && Head[int3] =!= D30SourceSelfInterference];
validate["source-production-interference-color-reduced",
  FreeQ[int3, _SUNF | _SUNTF | _SUNDelta | _SUNTrace]
];
candidate = D30SourceAntennaCandidate[int2, int3];
validate["source-candidate-built", candidate =!= $Failed];
Print["source-candidate numeric residual: ", ExactNumericResidual[D30Paper, candidate, 3]];
res = BuildAntenna[D, 3, 0, ReturnDiagnostics -> True];
validate["source-route-remains-honest",
  MatchQ[res, {$Failed, _Association}] &&
  Lookup[Last[res], "Reason", Missing["MissingReason"]] ===
    "ExperimentalSourceRouteNotYetValidatedForRelease" &&
  Lookup[Last[res], "SourceRouteReadyQ", Missing["MissingReadyQ"]] === False &&
  Lookup[Last[res], "SourceCandidateExactMatchQ",
    Missing["MissingExactMatchQ"]] === False
];
Print["leaf-born: ", LeafCount[int2]];
Print["leaf-production: ", LeafCount[int3]];
