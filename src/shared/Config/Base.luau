-- Base, egg and stealing rules (plan 4.7, 9.3, 11). Values are initial Phase 10 balance inputs.
return table.freeze({
	IncubatorSlots=3,IncubatorRange=16,PenRange=24,BaseRadius=30,
	PenSlots=8,PenStep=4,PenMaxLevel=4,
	IncubatorStep=.25,IncubatorMaxLevel=4, -- ×2 hatch speed at max, matching the hatch Game Pass
	LockSeconds=60,LockStep=20,LockMaxLevel=3,LockCooldown=120,
	UpgradeWood={lock=2000,incubator=1500,pen=1000},
	OfflineHours=8,EquipSlots=3,MaxEquipSlots=6,MaxEggs=60,MaxPets=200,
	StealSlow=.75,NestSlow=.8,ThiefCooldown=180,SafeProgress=.75,StealBonus=.1,ReclaimRange=12,
	NewPlayerShield=1800,AfkShield=600,
	BeltSeconds=20,BeltVisible=3,
	NestRefillMin=120,NestRefillMax=180,GuardianSpeed=12,GuardianBurst=15,BurstSeconds=4,GuardianLeash=90,CatchRadius=4.5,WarpSecureRange=14,
	ChestEggChance=.08,
	MountSpeed={Common=1.3,Rare=1.5,Epic=1.8,Legendary=2.1,Mythic=2.5,Secret=2.5},
	MountChapter=2, -- enforced only once the Story feature is enabled (Phase 6)
})
