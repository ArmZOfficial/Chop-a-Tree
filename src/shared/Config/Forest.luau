-- Runtime mechanics for Phase 2; economy formulas remain in BalanceConfig.
return table.freeze({
	StarterPower = 125,
	AttackInterval = 1,
	AttackRange = 14,
	ContributionWindow = 10,
	RespawnSeconds = 15,
	ChestClearRadius = 22,
	ChestCollectRange = 28,
	MaxRunChests = 50,
	StarterVisual = table.freeze({
		AssetId = "108477167298944",
		MeshId = "rbxassetid://145815658",
		TextureId = "rbxassetid://235687506",
		-- Visual properties only; all original scripts were discarded.
		Size = Vector3.new(0.2, 3.2, 1),
		Scale = Vector3.new(1, 0.7, 0.7),
	}),
})
