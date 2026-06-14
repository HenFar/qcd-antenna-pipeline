description = "antenna pipeline v0.1 - compatibility alias for the layered loader";

(*
  Compatibility loader kept during the layered-src cutover.
  It simply delegates to the canonical AntennaPipeline.wl entrypoint.
*)

Get[FileNameJoin[{DirectoryName[$InputFileName], "AntennaPipeline.wl"}]];
