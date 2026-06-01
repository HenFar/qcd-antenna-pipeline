Get[FileNameJoin[{DirectoryName[DirectoryName[]], "AntennaPipeline.wl"}]];
eps = FeynCalc`Epsilon;

Print["Before DownValues: ", DownValues[IntegratedLowerAntenna]];

antenna = BuildAntenna[A, 2, 2, Contribution -> TwoLoopTree, Component -> Leading];
profile = IBPProfile["A22TwoLoopTree"];
basisLoad = LoadIBPBases[profile];
reduction = ReduceAntennaIBP[antenna, basisLoad["Bases"], profile];

Print["After DownValues: ", DownValues[IntegratedLowerAntenna]];
Quit[];
