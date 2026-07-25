(* Targeted fresh-versus-contaminated state regression.
   Run with: wolframscript -file dev/regression_state_isolation.wl
   The worker runs in a new kernel for every baseline and contaminated sequence
   so this parent process cannot accidentally heal or contaminate a scenario. *)

repoRoot = DirectoryName[DirectoryName[$InputFileName]];
workerPath = FileNameJoin[{repoRoot, "dev", "state_isolation_worker.wl"}];
kernelCandidates = DeleteCases[
  {Environment["WOLFRAMKERNEL"], FindExecutable["WolframKernel"],
   "/Applications/Wolfram.app/Contents/MacOS/WolframKernel"},
  $Failed | ""
];
kernel = SelectFirst[kernelCandidates, StringQ[#] && FileExistsQ[#]&, $Failed];

If[kernel === $Failed || !FileExistsQ[kernel] || !FileExistsQ[workerPath],
  Print["State-isolation regression cannot locate WolframKernel or its worker."];
  Exit[2]
];

EnvironmentString[name_String] :=
  With[{value = Environment[name]}, If[StringQ[value], value, ""]];

allScenarios = {"A30ThenA40", "A30Sequential", "A21ThenA40", "A31ThenMX30",
  "MX30ThenA31", "A40ThenA30", "C40ThenA31ThenA22"};
requestedScenarios = StringSplit[EnvironmentString["ANTCALC_STATE_SCENARIOS"], ","];
scenarios = Select[requestedScenarios, MemberQ[allScenarios, #]&];
If[scenarios === {}, scenarios = allScenarios];
timeoutSeconds = With[{requested = EnvironmentString["ANTCALC_STATE_TIMEOUT"]},
  If[StringMatchQ[requested, DigitCharacter..], ToExpression[requested], 300]
];

ClearAll[NormalizeJSON, ReadWorkerReport, RunWorker, StateDelta, CompareScenario,
  EnvironmentString];

NormalizeJSON[value_Association] :=
  Association @ KeyValueMap[#1 -> NormalizeJSON[#2]&, value];
NormalizeJSON[rules : {(_Rule | _RuleDelayed) ..}] :=
  Association @ (Rule[First[#], NormalizeJSON[Last[#]]]& /@ rules);
NormalizeJSON[values_List] := NormalizeJSON /@ values;
NormalizeJSON[value_] := value;

ReadWorkerReport[stdout_String] :=
  Module[{line},
    line = SelectFirst[StringSplit[stdout, "\n"],
      StringStartsQ[#, "ANTCALC_STATE_REPORT="]&, Missing["NotFound"]];
    If[MissingQ[line],
      <|"WorkerReportMissingQ" -> True, "RawStandardOutput" -> stdout|>,
      Quiet[Check[
        NormalizeJSON @ ImportString[
          StringDelete[line, "ANTCALC_STATE_REPORT="], "JSON"],
        <|"WorkerReportInvalidQ" -> True, "RawStandardOutput" -> stdout|>
      ]]
    ]
  ];

RunWorker[mode_String, scenario_String] :=
  Module[{process},
    process = RunProcess[{kernel, "-script", workerPath, mode, scenario,
       ToString[timeoutSeconds]}, All];
    Join[
      <|"WorkerExitCode" -> process["ExitCode"],
        "WorkerStandardError" -> process["StandardError"]|>,
      ReadWorkerReport[process["StandardOutput"]]
    ]
  ];

StateDelta[before_Association, after_Association] :=
  Association @ Select[
    Table[
      key -> <|"Before" -> Lookup[before, key, Missing["Absent"]],
        "After" -> Lookup[after, key, Missing["Absent"]]|>,
      {key, Union[Keys[before], Keys[after]]}
    ],
    #[[2, "Before"]] =!= #[[2, "After"]]&
  ];

CompareScenario[scenario_String] :=
  Module[{fresh, contaminated, freshTarget, contaminatedTarget, freshTimeout,
     contaminatedTimeout, comparison, stateDelta, status, cacheCleanQ},
    Print["Running state-isolation scenario: ", scenario];
    fresh = RunWorker["fresh", scenario];
    contaminated = RunWorker["contaminated", scenario];
    If[TrueQ[fresh["WorkerReportMissingQ"]] || TrueQ[contaminated["WorkerReportMissingQ"]],
      Return[<|"Scenario" -> scenario, "Status" -> "WorkerFailure",
        "Fresh" -> fresh, "Contaminated" -> contaminated|>]
    ];
    freshTarget = fresh["TargetRun"]["Signature"];
    contaminatedTarget = contaminated["TargetRun"]["Signature"];
    freshTimeout = TrueQ[freshTarget["TimedOutQ"]];
    contaminatedTimeout = TrueQ[contaminatedTarget["TimedOutQ"]];
    cacheCleanQ = !TrueQ[fresh["StoredResultHitQ"]] && !TrueQ[contaminated["StoredResultHitQ"]];
    comparison = <|
      "InputFormHashMatchQ" -> (freshTarget["InputFormHash"] === contaminatedTarget["InputFormHash"]),
      "FixedPhysicalPointMatchQ" -> (freshTarget["FixedPhysicalPoint"] === contaminatedTarget["FixedPhysicalPoint"]),
      "OpenMasterCombinationHashMatchQ" ->
        (freshTarget["OpenMasterCombinationHash"] === contaminatedTarget["OpenMasterCombinationHash"]),
      "ExactTargetAgreementMatchQ" ->
        (freshTarget["ExactTargetAgreementQ"] === contaminatedTarget["ExactTargetAgreementQ"]),
      "CacheCleanQ" -> cacheCleanQ
    |>;
    stateDelta = StateDelta[contaminated["BeforeState"], contaminated["AfterState"]];
    status = Which[
      freshTimeout && contaminatedTimeout, "InconclusiveBothTimedOut",
      !freshTimeout && contaminatedTimeout, "FailContaminatedTimedOut",
      !cacheCleanQ, "FailUnexpectedStoredResult",
      And @@ Values[comparison], "Pass",
      True, "FailResultMismatch"
    ];
    <|"Scenario" -> scenario, "Status" -> status,
      "Comparison" -> comparison, "ContaminatedStateDelta" -> stateDelta,
      "Fresh" -> fresh, "Contaminated" -> contaminated|>
  ];

report = <|"SchemaVersion" -> 1, "TimeoutSeconds" -> timeoutSeconds,
  "Scenarios" -> (CompareScenario /@ scenarios)|>;

jsonReport = Quiet[Check[ExportString[report, "JSON", "Compact" -> False], $Failed]];
If[jsonReport === $Failed,
  Print["State-isolation regression could not export its report as JSON."];
  Exit[1]
];
Print[jsonReport];

failed = Select[report["Scenarios"], !MemberQ[{"Pass", "InconclusiveBothTimedOut"}, #"Status"]&];
If[Length[failed] > 0, Exit[1], Exit[0]];
