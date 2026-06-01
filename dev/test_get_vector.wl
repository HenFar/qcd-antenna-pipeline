Get[FileNameJoin[{DirectoryName[DirectoryName[]], "AntennaPipeline.wl"}]];

profile = IBPProfile["A22TwoLoopTree"];
basisLoad = LoadIBPBases[profile];
basis = basisLoad["Bases"][[1]]; (* Basis 1 *)
ds = LiteRed`Ds[basis];

Print["ds: ", InputForm[ds]];

getVector[sp[v_, _]] := v;
getVector[v_] := v;

Print["getVector[ds[[1]]]: ", InputForm[getVector[ds[[1]]]]];
Print["getVector[ds[[5]]]: ", InputForm[getVector[ds[[5]]]]];

Quit[];
