Get[FileNameJoin[{DirectoryName[DirectoryName[]], "AntennaPipeline.wl"}]];

printSeries[name_, core_] := Module[{conv},
  conv = A22TwoLoopTreePaperConventionFactor[] * A22TwoLoopTreePaperConventionRules[core] /. {q2 -> 1};
  Print["\n=== ", name, " ==="];
  Print["Series to order 3: ", Series[conv, {eps, 0, 3}] // Normal // FunctionExpand // FullSimplify // InputForm];
];

printSeries["A22LO", A22TwoLoopTreeMasterCoreA22LO[]];
printSeries["A3", A22TwoLoopTreeMasterCoreA3[]];
printSeries["A4", A22TwoLoopTreeMasterCoreA4[]];
printSeries["A6", A22TwoLoopTreeMasterCoreA6[]];

Quit[];
