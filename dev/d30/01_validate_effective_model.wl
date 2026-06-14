Get[FileNameJoin[{DirectoryName[DirectoryName[DirectoryName[$InputFileName]]],
  "AntennaPipeline.wl"}]];

validate[tag_, test_] :=
  If[TrueQ[test],
    Print[tag <> ": PASS"],
    Print[tag <> ": FAIL"];
    Quit[1]
  ];

validate["model-files", D30EffectiveModelFilesExistQ[]];

insertions2 = D30EffectiveSourceInsertions[2];
insertions3 = D30EffectiveSourceInsertions[3];

validate["insertions-1to2", Head[insertions2] =!= InsertFields && Length[insertions2] > 0];
validate["insertions-1to3", Head[insertions3] =!= InsertFields && Length[insertions3] > 0];

amp2 = D30EffectiveSourceAmplitude[2];
amp3 = D30EffectiveSourceAmplitude[3];

validate["amplitude-1to2", amp2 =!= $Failed && amp2 =!= 0];
validate["amplitude-1to3", amp3 =!= $Failed && amp3 =!= 0];

a30 = BuildAntenna[A, 3, 0];
validate["a30-regression", a30 =!= $Failed];

Print["diagram-count-1to2: ", Length[insertions2]];
Print["diagram-count-1to3: ", Length[insertions3]];
