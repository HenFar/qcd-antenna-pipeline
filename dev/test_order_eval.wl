Get[FileNameJoin[{DirectoryName[DirectoryName[]], "AntennaPipeline.wl"}]];
eps = FeynCalc`Epsilon;
a21Val = IntegratedLowerAntenna[{A, 2, 1}, 2];
Print["a21Val: ", a21Val];
Quit[];
