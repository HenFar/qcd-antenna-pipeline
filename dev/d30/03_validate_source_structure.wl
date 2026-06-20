Get[FileNameJoin[{DirectoryName[DirectoryName[DirectoryName[$InputFileName]]],
  "AntennaPipeline.wl"}]];

validate[tag_, test_] :=
  If[TrueQ[test],
    Print[tag <> ": PASS"],
    Print[tag <> ": FAIL"];
    Quit[1]
  ];

groups = D30SourceAmplitudeTermGroups[];
groupAssoc = D30SourceAmplitudeGroupAssociation[];

validate["group-contact-present", KeyExistsQ[groupAssoc, "Contact"]];
validate["group-gluino-exchange-present",
  KeyExistsQ[groupAssoc, "GluinoExchange"]];
validate["group-gluon-exchange-present",
  KeyExistsQ[groupAssoc, "GluonExchange"]];

validate["group-contact-nonzero", groupAssoc["Contact"] =!= 0];
validate["group-gluino-exchange-nonzero",
  groupAssoc["GluinoExchange"] =!= 0];
validate["group-gluon-exchange-nonzero",
  groupAssoc["GluonExchange"] =!= 0];

ward2 = D30SourceWardIdentityZeroQ[2];
ward3 = D30SourceWardIdentityZeroQ[3];
wardGroups2 = D30SourceWardGroupZeroQAssociation[2];
wardGroups3 = D30SourceWardGroupZeroQAssociation[3];

Print["group-map: ", groups];
Print["ward-k2-zeroq: ", ward2];
Print["ward-k3-zeroq: ", ward3];
Print["ward-k2-groups: ", wardGroups2];
Print["ward-k3-groups: ", wardGroups3];
