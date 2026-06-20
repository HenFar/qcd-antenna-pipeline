repoRoot = ParentDirectory[DirectoryName[$InputFileName]];

Get[FileNameJoin[{repoRoot, "AntennaPipeline.wl"}]];

runCase[name_String, heldExpr_Hold, checkFn_] :=
  Module[{result, passedQ},
    Print["Running: ", name];
    result = Quiet[Check[ReleaseHold[heldExpr], $Failed]];
    passedQ = TrueQ[checkFn[result]];
    <|"Name" -> name, "Passed" -> passedQ, "Result" -> result|>
  ];

recordReadyQ[rec_] :=
  AntennaRunRecordQ[rec] &&
  KeyExistsQ[AntennaRunRecordData[rec], "Result"] &&
  KeyExistsQ[AntennaRunRecordData[rec], "IntermediateSteps"] &&
  KeyExistsQ[AntennaRunRecordData[rec], "Diagnostics"];

results = {
  runCase[
    "BuildAntenna A20",
    Hold[BuildAntenna[A, 2, 0]],
    Function[result, result =!= $Failed]
  ],
  runCase[
    "BuildAntenna A30",
    Hold[BuildAntenna[A, 3, 0]],
    Function[result, result =!= $Failed]
  ],
  runCase[
    "BuildAndIntegrate A30",
    Hold[BuildAndIntegrateAntenna[A, 3, 0]],
    Function[result, result =!= $Failed]
  ],
  runCase[
    "BuildAndIntegrate A30 record",
    Hold[BuildAndIntegrateAntenna[A, 3, 0, ReturnRecord -> True]],
    recordReadyQ
  ],
  runCase[
    "BuildAndIntegrate A21",
    Hold[BuildAndIntegrateAntenna[A, 2, 1]],
    Function[result, result =!= $Failed]
  ],
  runCase[
    "BuildAndIntegrate A31",
    Hold[BuildAndIntegrateAntenna[A, 3, 1]],
    Function[result, result =!= $Failed]
  ],
  runCase[
    "BuildAndIntegrate A22",
    Hold[BuildAndIntegrateAntenna[A, 2, 2]],
    Function[result, result =!= $Failed]
  ],
  runCase[
    "BuildAndIntegrate A40 leading",
    Hold[BuildAndIntegrateAntenna[A, 4, 0, Component -> Leading]],
    Function[result, result =!= $Failed]
  ],
  runCase[
    "BuildAndIntegrate B40",
    Hold[BuildAndIntegrateAntenna[B, 4, 0]],
    Function[result, result =!= $Failed]
  ],
  runCase[
    "BuildAndIntegrate C40",
    Hold[BuildAndIntegrateAntenna[C, 4, 0]],
    Function[result, result =!= $Failed]
  ],
  runCase[
    "BuildRRatio SMQCD massless",
    Hold[BuildRRatio[SMQCD, quarkMass -> 0]],
    Function[result, result =!= $Failed]
  ]
};

failed = Select[results, Not[TrueQ[#["Passed"]]] &];

Print[""];
Print["=== RELEASE VERIFICATION SUMMARY ==="];
Do[
  Print[
    result["Name"],
    " | passed=",
    result["Passed"]
  ],
  {result, results}
];

Print[""];
Print["=== RELEASE SCOPE ==="];
Print["This script checks only the supported massless release matrix."];
Print["Experimental massive A30 and D30 routes are intentionally excluded."];

Print[""];
Print["=== FINAL COUNTS ==="];
Print[
  <|
    "NumTests" -> Length[results],
    "NumPassed" -> Count[results[[All, "Passed"]], True],
    "NumFailed" -> Count[results[[All, "Passed"]], False]
  |>
];

If[failed === {},
  Exit[0],
  Print[""];
  Print["=== FAILED CASES ==="];
  Do[Print[result["Name"]], {result, failed}];
  Exit[1]
];
