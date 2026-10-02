-- v3: additive and idempotent. Never unlock a zone or infer visits from unlocks.
return function(data)
	data.Progress = data.Progress or {}
	data.Progress.VisitedZones = data.Progress.VisitedZones or {}
	data.Explorer = data.Explorer or {}
	data.Explorer.collected = data.Explorer.collected or {}
	data.Explorer.completed = data.Explorer.completed or {}
	return data
end
