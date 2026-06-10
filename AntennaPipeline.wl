description = "antenna pipeline v0.1 - modular tree and one-loop antenna builder";

(*
  Package load order and top-level architecture.

  This file is intentionally a plain sequence of Get[...] calls rather than a
  BeginPackage/EndPackage wrapper.  The package relies on the current global
  FeynCalc/FeynArts/FeynHelpers symbol behavior, so keeping the notebook-style
  loading model avoids introducing a second context-management layer on top of
  the thesis code.

  The modules are grouped roughly as follows:

    1. setup/result_cache/kinematics
       Core symbols, rewrites, and shared utilities used everywhere else.

    2. amplitudes/interference/extraction/profiles
       Build the raw amplitudes, interfere them, and extract the public antenna
       components according to the selected antenna profile.

    3. build_router/production_assignments
       Present the public build API and convert internal routing data into the
       public BuildAntenna / BuildAntennaObject return shapes.

    4. integration_* / integrated_antenna_extraction
       Run the PaVe or IBP backend, normalize the result, and extract the final
       integrated antenna objects returned by the public integration API.

    5. paper_targets/diagnostics/notebook_patches/rratio_driver
       Validation helpers, compatibility patches for notebook-era reference
       material, and the prototype public R-ratio assembly layer.

  The practical end-to-end flow for the public API is:

    BuildAntenna[...] or BuildAntennaObject[...]
      -> profile lookup
      -> amplitude generation
      -> interference
      -> component extraction
      -> optional integration routing
      -> diagnostics / caching / public return formatting
*)

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
