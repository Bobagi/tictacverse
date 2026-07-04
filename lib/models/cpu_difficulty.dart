enum CpuDifficulty {
  easy,
  medium,
  hard,
}

CpuDifficulty cpuDifficultyFromName(String? name) {
  return CpuDifficulty.values.firstWhere(
    (CpuDifficulty difficulty) => difficulty.name == name,
    orElse: () => CpuDifficulty.medium,
  );
}
