(*************************************************)

(*
  File role and communication map
  -------------------------------
  This file is the metadata registry for the whole package.

  It communicates with:
    - src/engines/amplitudes_tree.wl through MAmpLoopLess[...], which supplies
      the tree amplitudes cached by AntennaAmplitude[...].
    - src/engines/interference_tree.wl through InterfereMAmplitudes[...], which
      supplies the Born/self-interference objects cached by
      AntennaSelfInterference[...].
    - src/core/d30_effective_model.wl through D30EffectiveModelName[], which is
      referenced by the D30 tree-level profile metadata.
    - src/routes/build_workflows.wl, which uses AntennaProfile[...] to choose
      the correct production and extraction workflow for a requested antenna.
    - src/routes/integration_workflows.wl and src/interface/integration_router.wl,
      which use AntennaIntegrationProfile[...] to choose the integration backend,
      basis family, and expansion depth.
    - src/core/production_assignments.wl, which reads AntennaAmplitude[...]
      and AntennaSelfInterference[...] to populate legacy globals.

  Why this file exists:
  The package separates route logic from physics metadata.  Instead of
  hard-coding every antenna family choice inside builders and integrators, the
  builders ask this registry what kind of object they are dealing with.  That
  makes the workflow code shorter and, more importantly, makes design decisions
  like colour normalization, sector choice, or reduction backend explicit and
  centrally auditable.

  Lightweight shared normalisation.
  This is symbolic and cheap to define at load time; amplitudes and
  interferences are built lazily below.
*)

(*************************************************)

AntennaReductionProfile::usage =
  "AntennaReductionProfile[key] returns the build-side reduction settings associated with an antenna family.";

AntennaProfile::usage =
  "AntennaProfile[key] returns the main metadata association for an antenna route, including amplitudes, extraction rules, and diagnostics data.";

AntennaAmplitude::usage =
  "AntennaAmplitude[key] returns the tree-level amplitude object associated with a profile.";

AntennaSelfInterference::usage =
  "AntennaSelfInterference[key] returns the encoded self-interference or companion object associated with a profile.";

BornInterference::usage =
  "BornInterference[] returns the standard born-level interference data shared by the loop extractors.";

AntennaIntegrationProfile::usage =
  "AntennaIntegrationProfile[key] returns the integration-backend metadata used by IntegrateAntenna for a given route.";

colourNorm = SUNN - 1 / SUNN;

(*************************************************)

(*
  One-loop routing profiles.
  These profiles keep the A21/A31 differences out of the production code:
  particle exclusions, generation sums, reduction preferences, and antenna
  extraction are chosen from the antenna key {type, multiplicity, loop order}.
*)

(*************************************************)

(* AntennaReductionProfile[key]
   ============================
   Summary
     Return build-side reduction preferences for a requested antenna family.

   Parameters
     key : list
       Antenna selector of the form `{type, multiplicity, loopOrder}`.

   Returns
     Association
       Reduction metadata consumed by the build routes.

   Notes
     The reduction backend is stored as metadata rather than inferred from the
     loop order because the physically natural backend can differ from one family
     to another.  A21 and A31, for example, are both one-loop objects but feed
     very different extraction logic downstream. *)
AntennaReductionProfile[{A, 2, 1}] :=
  <|"DefaultBackend" -> "PaVe"|>;

AntennaReductionProfile[{A, 3, 1}] :=
  <|"DefaultBackend" -> "PaVe"|>;

AntennaReductionProfile[{type_Symbol /; SymbolName[type] === "A", 2, 1}] :=
  <|"DefaultBackend" -> "PaVe"|>;

AntennaReductionProfile[{type_Symbol /; SymbolName[type] === "A", 3, 1}] :=
  <|"DefaultBackend" -> "PaVe"|>;

(* AntennaProfile[key]
   ===================
   Summary
     Return the central metadata record describing how one antenna family should
     be produced, extracted, and normalized.

   Parameters
     key : list
       Antenna selector `{type, multiplicity, loopOrder}`.

   Returns
     Association
       Route metadata used throughout the build layer.

   Notes
     This function is the main contract between the physics taxonomy of the
     package and the workflow layer.  Fields such as `Extraction`,
     `ProductionSectors`, and `ColourNorm` encode not just what the object is,
     but why the code treats it differently from nearby families. *)
AntennaProfile[{A, 2, 1}] :=
  <|"Key" -> {A, 2, 1}, "Name" -> "A21", "AntennaType" -> A, "NumFinalParticles"
     -> 2, "LoopOrder" -> 1, "TreeAmplitude" -> AntennaAmplitude[{A, 2,
      0}], "BornInterference" -> BornInterference[], "Extraction" -> "LoopScalar", 
    "ColourNorm" -> colourNorm, "ExcludedParticles" -> {S[_], V[1],
     V[2], V[3], U[1], U[2], U[3], 
    U[4]}, "DropSumOver" -> True, "ReductionProfile" -> AntennaReductionProfile[
    {A, 2, 1}]|>;

AntennaProfile[{A, 3, 1}] :=
  <|"Key" -> {A, 3, 1}, "Name" -> "A31", "AntennaType" -> A, "NumFinalParticles"
     -> 3, "LoopOrder" -> 1, "TreeAmplitude" -> AntennaAmplitude[{A, 3,
      0}], "BornInterference" -> BornInterference[], "Extraction" -> "LoopColorCoefficients",
     "ColourNorm" -> colourNorm, "ExcludedParticles" -> {S[_], V[1], V[2],
     V[3], U[1], U[
    2], U[3]}, "DropSumOver" -> False, "ReductionProfile" -> AntennaReductionProfile[
    {A, 3, 1}]|>;

AntennaProfile[{A, 2, 2}] :=
  <|"Key" -> {A, 2, 2}, "Name" -> "A22", "AntennaType" -> A,
    "NumFinalParticles" -> 2, "LoopOrder" -> 2,
    "BornInterference" -> BornInterference[],
    "Components" -> {Leading, Subleading, Nf, Breve},
    "Contributions" -> {TwoLoopTree, OneLoopSelf},
    "Extraction" -> "TwoLoopTTermComponents",
    "ExcludedParticles" -> {S[_], V[1], V[2], V[3], U[1], U[2],
      U[3], U[4]}, "DropSumOver" -> False,
    "ColourNorm" -> colourNorm,
    "ImplementationStatus" -> "ExperimentalSourceProduction"|>;

AntennaProfile[{type_Symbol /; SymbolName[type] === "A", 2, 1}] :=
  <|"Key" -> {type, 2, 1}, "Name" -> "A21", "AntennaType" -> type,
    "NumFinalParticles" -> 2, "LoopOrder" -> 1, "TreeAmplitude" ->
     AntennaAmplitude[{type, 2, 0}], "BornInterference" ->
     BornInterference[], "Extraction" -> "LoopScalar", "ColourNorm" ->
     colourNorm, "ExcludedParticles" -> {S[_], V[1], V[2], V[3], U[1],
      U[2], U[3], U[4]}, "DropSumOver" -> True, "ReductionProfile" ->
     AntennaReductionProfile[{type, 2, 1}]|>;

AntennaProfile[{type_Symbol /; SymbolName[type] === "A", 3, 1}] :=
  <|"Key" -> {type, 3, 1}, "Name" -> "A31", "AntennaType" -> type,
    "NumFinalParticles" -> 3, "LoopOrder" -> 1, "TreeAmplitude" ->
     AntennaAmplitude[{type, 3, 0}], "BornInterference" ->
     BornInterference[], "Extraction" -> "LoopColorCoefficients",
    "ColourNorm" -> colourNorm, "ExcludedParticles" -> {S[_], V[1], V[2],
      V[3], U[1], U[2], U[3]}, "DropSumOver" -> False,
    "ReductionProfile" -> AntennaReductionProfile[{type, 3, 1}]|>;

AntennaProfile[{type_Symbol /; SymbolName[type] === "A", 2, 2}] :=
  <|"Key" -> {type, 2, 2}, "Name" -> "A22", "AntennaType" -> type,
    "NumFinalParticles" -> 2, "LoopOrder" -> 2, "BornInterference" ->
     BornInterference[], "Components" -> {Leading, Subleading, Nf,
      Breve}, "Contributions" -> {TwoLoopTree, OneLoopSelf},
    "Extraction" -> "TwoLoopTTermComponents", "ExcludedParticles" -> {S[_],
      V[1], V[2], V[3], U[1], U[2], U[3], U[4]}, "DropSumOver" -> False,
    "ColourNorm" -> colourNorm, "ImplementationStatus" ->
     "ExperimentalSourceProduction"|>;
(*************************************************)

(*
  Tree-level antenna profiles.
  Antenna-specific physics is stored as metadata here: colour normalisation,
  production mode, and the sector definitions used for B/C four-quark
  antennae.  The production functions below are generic.
*)

(*************************************************)

(* The tree-level profiles below are intentionally declarative.
   The route layer reads these records to decide which engine workflow to call,
   so the profile tells us not only the antenna family name but also why the
   family branches:
   - `SelfInterference` for simple squared amplitudes,
   - `ColorOrderedAntenna` when the physically useful object is a color-ordered
     decomposition rather than one scalar,
   - sector-based production for B40/C40 where phase-space singular structure
     and quark-pair symmetry make a one-shot build less usable. *)
AntennaProfile[{A, 2, 0}] :=
  <|"Key" -> {A, 2, 0}, "Name" -> "A20", "AntennaType" -> A, "NumFinalParticles"
     -> 2, "Production" -> "SelfInterference", "Extraction" -> "BornScalar",
     "ColourNorm" -> colourNorm|>;

AntennaProfile[{A, 3, 0}] :=
  <|"Key" -> {A, 3, 0}, "Name" -> "A30", "AntennaType" -> A, "NumFinalParticles"
     -> 3, "Production" -> "SelfInterference", "Extraction" -> "TreeColorCoefficients",
     "ColourNorm" -> colourNorm|>;

AntennaProfile[{A, 4, 0}] :=
  <|"Key" -> {A, 4, 0}, "Name" -> "A40", "AntennaType" -> A, "NumFinalParticles"
     -> 4, "Production" -> "ColorOrderedAntenna", "Extraction" -> "TreeColorCoefficients",
     "ColourNorm" -> colourNorm, "ColorOrderedSpec" -> <|"Name" -> "A40",
     "Ordering" -> {1, 3, 4, 2}, "NumGluons" -> 2|>|>;

AntennaProfile[{B, 4, 0}] :=
  <|"Key" -> {B, 4, 0}, "Name" -> "B40", "AntennaType" -> B, "NumFinalParticles"
     -> 4, "Production" -> "SectorSelfInterference", "Extraction" -> "ColourNormScalar",
     "ColourNorm" -> colourNorm, "ProductionSectors" -> {"PrimaryCurrent",
     "PrimaryCurrent"}, "SectorDefinitions" -> <|"PrimaryCurrent" -> {{s34
    }, {s134, s234}}, "SecondaryCurrent" -> {{s12}, {s123, s124}}|>|>;

AntennaProfile[{C, 4, 0}] :=
  <|"Key" -> {C, 4, 0}, "Name" -> "C40", "AntennaType" -> C, "NumFinalParticles"
     -> 4, "Production" -> "SectorSymmetrizedInterference", "Extraction" 
    -> "MinusTwoColourNormOverSUNN", "ColourNorm" -> colourNorm, "ProductionSectors"
     -> {"DirectPrimary", "ExchangePrimary"}, "ReferenceSquareSector" -> 
    "DirectPrimary", "ReferenceSquareProfile" -> {B, 4, 0}, "SectorDefinitions"
     -> <|"DirectPrimary" -> {{s34}, {s134, s234}}, "DirectSecondary" -> 
    {{s12}, {s123, s124}}, "ExchangePrimary" -> {{s23}, {s123, s234}}, "ExchangeSecondary"
     -> {{s14}, {s124, s134}}|>|>;

AntennaProfile[{D, 3, 0}] :=
  <|"Key" -> {D, 3, 0}, "Name" -> "D30", "AntennaType" -> D,
    "NumFinalParticles" -> 3, "Production" -> "OrderedColorStrippedSource",
    "Extraction" -> "ColourNormScalar", "ColourNorm" -> 1,
    "SourceModel" -> D30EffectiveModelName[],
    "ColorOrderedSpec" -> <|"Name" -> "D30", "NumGluons" -> 1|>,
    "ImplementationStatus" -> "ModelOwnedOrderedSourceRouteInProgress"|>;

AntennaProfile[{type_Symbol /; SymbolName[type] === "A", 2, 0}] :=
  <|"Key" -> {type, 2, 0}, "Name" -> "A20", "AntennaType" -> type,
    "NumFinalParticles" -> 2, "Production" -> "SelfInterference",
    "Extraction" -> "BornScalar", "ColourNorm" -> colourNorm|>;

AntennaProfile[{type_Symbol /; SymbolName[type] === "A", 3, 0}] :=
  <|"Key" -> {type, 3, 0}, "Name" -> "A30", "AntennaType" -> type,
    "NumFinalParticles" -> 3, "Production" -> "SelfInterference",
    "Extraction" -> "TreeColorCoefficients", "ColourNorm" -> colourNorm|>;

AntennaProfile[{type_Symbol /; SymbolName[type] === "A", 4, 0}] :=
  <|"Key" -> {type, 4, 0}, "Name" -> "A40", "AntennaType" -> type,
    "NumFinalParticles" -> 4, "Production" -> "ColorOrderedAntenna",
    "Extraction" -> "TreeColorCoefficients", "ColourNorm" -> colourNorm,
    "ColorOrderedSpec" -> <|"Name" -> "A40", "Ordering" -> {1, 3, 4, 2},
      "NumGluons" -> 2|>|>;

AntennaProfile[{type_Symbol /; SymbolName[type] === "B", 4, 0}] :=
  <|"Key" -> {type, 4, 0}, "Name" -> "B40", "AntennaType" -> type,
    "NumFinalParticles" -> 4, "Production" -> "SectorSelfInterference",
    "Extraction" -> "ColourNormScalar", "ColourNorm" -> colourNorm,
    "ProductionSectors" -> {"PrimaryCurrent", "PrimaryCurrent"},
    "SectorDefinitions" -> <|"PrimaryCurrent" -> {{s34}, {s134, s234}},
      "SecondaryCurrent" -> {{s12}, {s123, s124}}|>|>;

AntennaProfile[{type_Symbol /; SymbolName[type] === "C", 4, 0}] :=
  <|"Key" -> {type, 4, 0}, "Name" -> "C40", "AntennaType" -> type,
    "NumFinalParticles" -> 4, "Production" ->
     "SectorSymmetrizedInterference", "Extraction" ->
     "MinusTwoColourNormOverSUNN", "ColourNorm" -> colourNorm,
    "ProductionSectors" -> {"DirectPrimary", "ExchangePrimary"},
    "ReferenceSquareSector" -> "DirectPrimary", "ReferenceSquareProfile" ->
     {B, 4, 0}, "SectorDefinitions" -> <|
      "DirectPrimary" -> {{s34}, {s134, s234}},
      "DirectSecondary" -> {{s12}, {s123, s124}},
      "ExchangePrimary" -> {{s23}, {s123, s234}},
      "ExchangeSecondary" -> {{s14}, {s124, s134}}|>|>;

AntennaProfile[{type_Symbol /; SymbolName[type] === "D", 3, 0}] :=
  <|"Key" -> {type, 3, 0}, "Name" -> "D30", "AntennaType" -> type,
    "NumFinalParticles" -> 3, "Production" -> "OrderedColorStrippedSource",
    "Extraction" -> "ColourNormScalar", "ColourNorm" -> 1,
    "SourceModel" -> D30EffectiveModelName[],
    "ColorOrderedSpec" -> <|"Name" -> "D30", "NumGluons" -> 1|>,
    "ImplementationStatus" -> "ModelOwnedOrderedSourceRouteInProgress"|>;

(* AntennaAmplitude[key]
   =====================
   Summary
     Lazily build and memoize the tree-level amplitude associated with a tree
     antenna profile.

   Parameters
     key : list
       Tree-level antenna selector.

   Returns
     expression
       The underlying FeynCalc amplitude.

   Notes
     These amplitudes are memoized because many routes need them repeatedly:
     self-interference construction, Born normalization for loop antennae, and
     notebook compatibility helpers.  Building them once keeps the software
     responsive without hiding where the physics input came from. *)
AntennaAmplitude[{A, 2, 0}] :=
  AntennaAmplitude[{A, 2, 0}] = MAmpLoopLess[2];

AntennaAmplitude[{A, 3, 0}] :=
  AntennaAmplitude[{A, 3, 0}] = MAmpLoopLess[3];

AntennaAmplitude[{A, 4, 0}] :=
  AntennaAmplitude[{A, 4, 0}] = MAmpLoopLess[4];

AntennaAmplitude[{B, 4, 0}] :=
  AntennaAmplitude[{B, 4, 0}] = MAmpLoopLess[4, AntennaType -> B];

AntennaAmplitude[{C, 4, 0}] :=
  AntennaAmplitude[{C, 4, 0}] = MAmpLoopLess[4, AntennaType -> C];

AntennaAmplitude[{type_Symbol /; SymbolName[type] === "A", 2, 0}] :=
  AntennaAmplitude[{type, 2, 0}] = MAmpLoopLess[2];

AntennaAmplitude[{type_Symbol /; SymbolName[type] === "A", 3, 0}] :=
  AntennaAmplitude[{type, 3, 0}] = MAmpLoopLess[3];

AntennaAmplitude[{type_Symbol /; SymbolName[type] === "A", 4, 0}] :=
  AntennaAmplitude[{type, 4, 0}] = MAmpLoopLess[4];

AntennaAmplitude[{type_Symbol /; SymbolName[type] === "B", 4, 0}] :=
  AntennaAmplitude[{type, 4, 0}] = MAmpLoopLess[4, AntennaType -> B];

AntennaAmplitude[{type_Symbol /; SymbolName[type] === "C", 4, 0}] :=
  AntennaAmplitude[{type, 4, 0}] = MAmpLoopLess[4, AntennaType -> C];

(* AntennaSelfInterference[key]
   ============================
   Summary
     Lazily build and memoize the tree-level self-interference object associated
     with a tree antenna profile.

   Parameters
     key : list
       Tree-level antenna selector.

   Returns
     expression
       The squared or interfered matrix element before route-specific
       extraction.

   Notes
     This sits one level above AntennaAmplitude[...].  Keeping the self-
     interference cached separately is useful because several downstream routes
     need the squared object directly, while others still need access to the
     unsquared amplitude for more specialized reconstructions. *)
AntennaSelfInterference[{A, 2, 0}] :=
  AntennaSelfInterference[{A, 2, 0}] =
    InterfereMAmplitudes[AntennaAmplitude[{A, 2, 0}], AntennaAmplitude[{
      A, 2, 0}], 2];

AntennaSelfInterference[{A, 3, 0}] :=
  AntennaSelfInterference[{A, 3, 0}] =
    InterfereMAmplitudes[AntennaAmplitude[{A, 3, 0}], AntennaAmplitude[{
      A, 3, 0}], 3];

AntennaSelfInterference[{A, 4, 0}] :=
  AntennaSelfInterference[{A, 4, 0}] =
    InterfereMAmplitudes[AntennaAmplitude[{A, 4, 0}], AntennaAmplitude[{
      A, 4, 0}], 4];

AntennaSelfInterference[{B, 4, 0}] :=
  AntennaSelfInterference[{B, 4, 0}] =
    InterfereMAmplitudes[AntennaAmplitude[{B, 4, 0}], AntennaAmplitude[{
      B, 4, 0}], 4, AntennaType -> B];

AntennaSelfInterference[{C, 4, 0}] :=
  AntennaSelfInterference[{C, 4, 0}] =
    InterfereMAmplitudes[AntennaAmplitude[{C, 4, 0}], AntennaAmplitude[{
      C, 4, 0}], 4, AntennaType -> C];

(* BornInterference[]
   ==================
   Summary
     Return the canonical A20 Born interference used to normalize loop-level
     antenna extractions.

   Returns
     expression
       The A20 self-interference object.

   Notes
     This helper intentionally fixes the Born object to one canonical source.
     That avoids a common category error where “the relevant tree” is inferred
     differently in different loop routes. *)
BornInterference[] :=
  AntennaSelfInterference[{A, 2, 0}];

(* AntennaIntegrationProfile[key]
   ==============================
   Summary
     Return the integration-side backend metadata for a requested antenna.

   Parameters
     key : list
       Antenna selector `{type, multiplicity, loopOrder}`.

   Returns
     Association
       Integration routing metadata.

   Notes
     Integration is separated from build metadata because the most convenient
     construction representation is not always the most convenient integration
     representation.  For example, A21 is built naturally in a PaVe language,
     while A31 and the tree-level higher-multiplicity antennae are routed into
     IBP families whose expansion orders are determined by their infrared pole
     structure. *)
AntennaIntegrationProfile[{A, 2, 1}] :=
  <|"DefaultBackend" -> PaVe, "PaVeFamily" -> "MasslessTwoPartonVertex",
    "PaXConvention" -> "PaperRealMasslessTwoParton", "KinematicScale" ->
     q2, "ExpansionOrder" -> 2|>;

AntennaIntegrationProfile[{A, 3, 0}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "X30", "ExpansionOrder"
     -> 0|>;

AntennaIntegrationProfile[{A, 4, 0}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "X40", "ExpansionOrder"
     -> 0|>;

AntennaIntegrationProfile[{B, 4, 0}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "X40", "ExpansionOrder"
     -> 0|>;

AntennaIntegrationProfile[{C, 4, 0}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "X40", "ExpansionOrder"
     -> 0|>;

AntennaIntegrationProfile[{A, 3, 1}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "A31", "ExpansionOrder"
     -> -2|>;

AntennaIntegrationProfile[{A, 2, 2}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "A22", "ExpansionOrder"
     -> 0, "ImplementationStatus" -> "ScaffoldOnly"|>;

AntennaIntegrationProfile[{type_Symbol /; SymbolName[type] === "A", 2, 1}] :=
  <|"DefaultBackend" -> PaVe, "PaVeFamily" -> "MasslessTwoPartonVertex",
    "PaXConvention" -> "PaperRealMasslessTwoParton", "KinematicScale" ->
     q2, "ExpansionOrder" -> 2|>;

AntennaIntegrationProfile[{type_Symbol /; SymbolName[type] === "A", 3, 0}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "X30", "ExpansionOrder" -> 0|>;

AntennaIntegrationProfile[{type_Symbol /; SymbolName[type] === "A", 4, 0}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "X40", "ExpansionOrder" -> 0|>;

AntennaIntegrationProfile[{type_Symbol /; SymbolName[type] === "B", 4, 0}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "X40", "ExpansionOrder" -> 0|>;

AntennaIntegrationProfile[{type_Symbol /; SymbolName[type] === "C", 4, 0}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "X40", "ExpansionOrder" -> 0|>;

AntennaIntegrationProfile[{type_Symbol /; SymbolName[type] === "A", 3, 1}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "A31", "ExpansionOrder" -> -2|>;

AntennaIntegrationProfile[{type_Symbol /; SymbolName[type] === "A", 2, 2}] :=
  <|"DefaultBackend" -> IBP, "BasisFamily" -> "A22", "ExpansionOrder" ->
     0, "ImplementationStatus" -> "ScaffoldOnly"|>;

AntennaIntegrationProfile[_] :=
  <|"DefaultBackend" -> IBP|>;
