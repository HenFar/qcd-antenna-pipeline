Get[FileNameJoin[{DirectoryName[DirectoryName[]], "AntennaPipeline.wl"}]];

Print[CanonicalAntennaComponentName[Nf]];
Print[CanonicalAntennaComponentName[Subleading]];
Print[IntegratedLowerAntenna[{A, 2, 1}, 2]];
Print[
  IntegratedAntennaTTerms[
    {A, 2, 2},
    1/(6 FeynCalc`Epsilon^3),
    ExpansionOrder -> 0,
    Component -> Nf
  ]
];
