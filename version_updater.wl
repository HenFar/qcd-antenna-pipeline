repoRoot = DirectoryName[$InputFileName];

archive = CreatePacletArchive[repoRoot, $TemporaryDirectory];

PacletInstall[archive, ForceVersionInstall -> True];

PacletDataRebuild[];
