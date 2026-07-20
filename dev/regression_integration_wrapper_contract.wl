(* Fresh-kernel public API regression: direct AntennaObject integration and
   BuildAndIntegrateAntenna must expose identical integration options and
   identical unreplaced A30 master combinations. *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "..",
    "AntennaPipeline.wl"}]];

ClearAll[a30Object, directMaster, wrappedMaster, optionNames, contract,
  forwardedRules, probeRules, report];

a30Object = BuildAntenna[A, 3, 0,
  IntegrableForm -> True,
  UseStoredResults -> False,
  StoreResults -> False];

directMaster = IntegrateAntenna[a30Object,
  ReturnMasterCombination -> True,
  UseStoredResults -> False,
  StoreResults -> False];

wrappedMaster = BuildAndIntegrateAntenna[A, 3, 0,
  ReturnMasterCombination -> True,
  UseStoredResults -> False,
  StoreResults -> False];

optionNames[head_] := Sort[First /@ Options[head]];
contract = IntegrationWrapperOptionContract[];
forwardedRules = Association[BuildAndIntegrateIntegrationOptions[<||>]];
probeRules = Association[BuildAndIntegrateIntegrationOptions[<|
  "ApplyFeynCalcMS" -> False, "quarkMass" -> testMass,
  "PaVeEvaluation" -> "RawPaVe", "ExpansionOrder" -> 3,
  "KinematicScale" -> testScale, "NormalizeKinematicScale" -> False,
  "ReturnMasterCombination" -> True, "LoopMomentum" -> testLoop,
  "ApplyDimReg" -> False, "BasisFamily" -> testBasis,
  "BasisRoot" -> testRoot, "GenerateMissingBases" -> True,
  "ReturnTTerms" -> True, "IntermediateSteps" -> {"TTerms"},
  "PrintIntermediateSteps" -> True,
  "DetailedTimingDiagnostics" -> True|>]];

report = <|
  "Regression" -> "IntegrationWrapperContract",
  "Checks" -> <|
    "IntegrationOptionSetsMatch" ->
      (optionNames[IntegrateAntenna] ===
        optionNames[BuildAndIntegrateAntenna]),
    "EveryPublicOptionHasOneShotDisposition" ->
      (optionNames[IntegrateAntenna] === Sort[Keys[contract]]),
    "ForwardedRulesCoverPhysicsAndReturnControls" ->
      ContainsAll[Keys[forwardedRules], {
        ApplyFeynCalcMS, quarkMass, PaVeEvaluation, ExpansionOrder,
        KinematicScale, NormalizeKinematicScale, ReturnDiagnostics,
        ReturnRecord, ReturnMasterCombination, LoopMomentum, ApplyDimReg,
        BasisFamily, BasisRoot, GenerateMissingBases, ReturnTTerms,
        IntermediateSteps, PrintIntermediateSteps,
        DetailedTimingDiagnostics, Component
      }],
    "ForwardedRulesPreserveRequestedValues" ->
      And[
        probeRules[ApplyFeynCalcMS] === False,
        probeRules[quarkMass] === testMass,
        probeRules[PaVeEvaluation] === "RawPaVe",
        probeRules[ExpansionOrder] === 3,
        probeRules[KinematicScale] === testScale,
        probeRules[NormalizeKinematicScale] === False,
        probeRules[ReturnMasterCombination] === True,
        probeRules[LoopMomentum] === testLoop,
        probeRules[ApplyDimReg] === False,
        probeRules[BasisFamily] === testBasis,
        probeRules[BasisRoot] === testRoot,
        probeRules[GenerateMissingBases] === True,
        probeRules[ReturnTTerms] === True,
        probeRules[IntermediateSteps] === {"TTerms"},
        probeRules[PrintIntermediateSteps] === True,
        probeRules[DetailedTimingDiagnostics] === True
      ],
    "DirectMasterCombinationReturned" -> directMaster =!= $Failed,
    "WrapperMasterCombinationReturned" -> wrappedMaster =!= $Failed,
    "DirectAndWrapperMasterCombinationsMatch" ->
      TrueQ[Together[directMaster - wrappedMaster] === 0]
    |>
  |>;
report = Join[report, <|"Passed" -> And @@ Values[report["Checks"]]|>];
Print[report];
