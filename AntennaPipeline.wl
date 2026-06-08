description = "antenna pipeline v0.1 - modular tree and one-loop antenna builder";

If[$FrontEnd === Null,
  $FeynCalcStartupMessages = False;
];

packageRoot = DirectoryName[$InputFileName];
$AntennaPipelineRoot = packageRoot;

Get[FileNameJoin[{packageRoot, "src", "setup.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "result_cache.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "kinematics_and_utilities.wl"}]
  ];

Get[FileNameJoin[{packageRoot, "src", "amplitudes_tree.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "amplitudes_loop.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "interference_tree.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "interference_loop.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "profiles.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "extraction_tree.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "extraction_loop.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "color_ordered_a40.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "build_router.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "production_assignments.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "integration_ibp.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "integration_pave.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "integrated_antenna_extraction.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "integration_router.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "paper_targets.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "diagnostics.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "notebook_patches.wl"}]];

Get[FileNameJoin[{packageRoot, "src", "rratio_driver.wl"}]];
