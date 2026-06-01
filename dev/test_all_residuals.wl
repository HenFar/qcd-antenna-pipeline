Get[FileNameJoin[{DirectoryName[DirectoryName[]], "AntennaPipeline.wl"}]];

runComponent[component_] := Module[{res, diag},
  Print["\nIntegrating component: ", component];
  {res, diag} = IntegrateAntenna[A, 2, 2,
    Contribution -> TwoLoopTree, Component -> component,
    ReturnDiagnostics -> True, ExpansionOrder -> 0
  ];
  Print["Residual: ", diag["TTermResiduals"]];
  Print["Is Zero: ", diag["TTermResidualIsZero"]];
];

runComponent[Nf];
runComponent[Leading];
runComponent[Subleading];

Quit[];
