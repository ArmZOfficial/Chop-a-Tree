-- Phase 9 lobby. Arena sub-place in the main universe; PvP flag gates the portal.
return {
	PlaceId = 135249057761883,
	PortalRange = 24,
	FillSeconds = 15,
	TransferTimeout = 60,
	Modes = {
		{ id="Duel", name="Duel 1v1", min=2, max=2 },
		{ id="FFA", name="Free-for-All", min=2, max=7 },
		{ id="TimberClash", name="Timber Clash", min=4, max=6, teams=true },
		{ id="EggHeist", name="Egg Heist", min=4, max=6, teams=true },
	},
	-- Match results come back through the ArenaPending DataStore ledger; RP only moves in Ranked and resets each UTC month.
	Tokens = { win=15, draw=8, loss=5, left=0 },
	RankPoints = { win=25, draw=0, loss=-10, left=-10 },
	Ranks = { {name="Wood",rp=0}, {name="Bronze",rp=100}, {name="Silver",rp=250}, {name="Gold",rp=500}, {name="Diamond",rp=900}, {name="Mythic",rp=1400} },
}
