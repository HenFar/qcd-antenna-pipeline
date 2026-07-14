repoRoot = Environment["ANTENNA_PIPELINE_ROOT"];

If[repoRoot === $Failed || repoRoot === "",
  repoRoot = DirectoryName[DirectoryName[$InputFileName]];
];

Get[FileNameJoin[{repoRoot, "AntennaPipeline.wl"}]];

reports = <|
  "A30" -> VerifyWardIdentity[A, 3, 0],
  "A40" -> VerifyWardIdentity[A, 4, 0]
|>;

compactResidual[residual_] :=
  If[residual === 0 || MemberQ[{$Failed, $Aborted}, residual],
    residual,
    <|"NonzeroResidualLeafCount" -> LeafCount[residual]|>
  ];

compactReport[report_Association] :=
  Join[
    KeyTake[report, {"Key", "ValidationStatus", "CheckedGluonLegs"}],
    <|"LegReports" -> Association @ KeyValueMap[
      #1 -> Join[
        KeyTake[#2, {"Leg", "Momentum", "SimplificationStatus", "PassQ",
          "ValidationStatus"}],
        <|"Residual" -> compactResidual[Lookup[#2, "Residual", Missing["NotAvailable"]]]|>
      ]&,
      Lookup[report, "LegReports", <||>]
    ]|>
  ];

Print["=== WARD-IDENTITY VALIDATION ==="];
Print[compactReport /@ reports];

If[AllTrue[Values[reports], Lookup[#, "ValidationStatus", "Failed"] === "Pass" &],
  Exit[0],
  Exit[1]
];
