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
}
