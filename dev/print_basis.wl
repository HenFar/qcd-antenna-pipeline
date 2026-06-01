Get[FileNameJoin[{DirectoryName[DirectoryName[]], "AntennaPipeline.wl"}]];
profile = IBPProfile["A22TwoLoopTree"];
basisLoad = LoadIBPBases[profile];
Print[InputForm[LiteRed`Ds[A22TwoLoopTreeBasis1]]];
Quit[];
