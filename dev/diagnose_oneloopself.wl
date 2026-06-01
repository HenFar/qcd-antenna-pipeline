Get[FileNameJoin[{DirectoryName[DirectoryName[]], "AntennaPipeline.wl"}]];
antenna = BuildAntenna[A, 2, 2, Contribution -> OneLoopSelf];
profile = IBPProfile["A22OneLoopSelf"];
basisLoad = LoadIBPBases[profile];
reduction = ReduceAntennaIBP[antenna, basisLoad["Bases"], profile];
Print["OneLoopSelf reduced expression: ", FullSimplify[Total[reduction["ReducedTerms"]]]];
Quit[];
