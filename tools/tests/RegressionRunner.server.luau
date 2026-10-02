-- Studio-only driver: for each disabled scenario Script, Prepare (RegressionHarness) -> enable it -> wait for
-- its workspace status attribute -> Finish. MCP threads cannot invoke the harness BindableFunctions, so run
-- this Script instead. Attribute Scenarios = "Phase4Scenario=Phase4TestStatus,Phase5Scenario=Phase5TestStatus".
-- Result: attribute Summary = "Phase4Scenario:passed:55:restored ..." and Done = true.
assert(game:GetService("RunService"):IsStudio())
local SSS = game:GetService("ServerScriptService")
local Http = game:GetService("HttpService")
local harness = SSS:WaitForChild("RegressionHarness")
harness.Enabled = true
local t = os.clock()
repeat task.wait(0.5) until harness:GetAttribute("Ready") or os.clock() - t > 40
local summary = {}
for name, key in string.gmatch(script:GetAttribute("Scenarios"), "([%w_]+)=([%w_]+)") do
	pcall(function() return harness.Prepare:Invoke() end)
	SSS:WaitForChild(name).Enabled = true
	t = os.clock()
	-- Older scenarios only publish <Name>Results (JSON with "passed"); newer ones also publish a status.
	local resultsKey = key:gsub("Status$", "Results")
	local status
	repeat
		task.wait(1)
		status = workspace:GetAttribute(key)
		if key == resultsKey and status then status = status:find('"passed":true') and "passed" or "failed" end
	until status == "passed" or status == "failed" or os.clock() - t > (script:GetAttribute("Timeout") or 240)
	local ok, restored, changes = pcall(function() return harness.Finish:Invoke() end)
	local results = workspace:GetAttribute(resultsKey) or ""
	local _, checks = results:gsub('"name":', "")
	local err = results:match('"error":"(.-)"') or ""
	table.insert(summary, string.format("%s:%s:%d:%s %s %s", name, tostring(status), checks, ok and restored and "restored" or "NOT-RESTORED", ok and changes or tostring(restored), err:sub(1, 300)))
	task.wait(16) -- let trees felled by the scenario respawn (15 s) before the next one
end
script:SetAttribute("Summary", table.concat(summary, "\n"))
script:SetAttribute("Done", true)
