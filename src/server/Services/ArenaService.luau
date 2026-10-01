-- Local-server lobby queues; no profile stats/rewards come from TeleportData.
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Teleport=game:GetService("TeleportService")
local S=game.ReplicatedStorage.Shared
local C=require(S.Config.Arena);local Net=require(S.Net)
local D=require(script.Parent.DataService);local F=require(script.Parent.FeatureService)
local P=require(script.Parent.PetService)
local A={};local queued,transferring,last={},{},{}
local testTransport,testPlace
local function mode(id) for _,m in C.Modes do if m.id==id then return m end end end
local function target() return testPlace or C.PlaceId end
local function eligible(p)
	if not F.IsEnabled("PvP") or not D.IsLoaded(p) or p.Parent~=Players then return false,"Arena ยังไม่เปิด" end
	local character=p.Character;local h=character and character:FindFirstChildOfClass("Humanoid")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not h or h.Health<=0 or not root then return false,"ตัวละครยังไม่พร้อม" end
	if D.Get(p,"Run.Active") or p:GetAttribute("CarryingEgg") or P.Mounted(p) then return false,"จบ Run และวางไข่/ลงจากสัตว์ก่อน" end
	for _,portal in Collection:GetTagged("ArenaPortal") do
		if portal:IsDescendantOf(workspace) and (portal:GetPivot().Position-root.Position).Magnitude<=C.PortalRange then return true end
	end
	return false,"เดินไปที่พอร์ทัล Chop Arena ก่อน"
end
function A.State(p)
	local counts={};for _,m in C.Modes do counts[m.id]=0 end
	for _,q in queued do counts[q.mode]+=1 end
	local q=queued[p];local t=transferring[p]
	local entry=q or t
	return {mode=entry and entry.mode,ranked=entry and entry.ranked,transferring=t~=nil,counts=counts,ready=F.IsEnabled("PvP") and target()>0}
end
local function send(p) if p.Parent==Players then Net.Event("ArenaState"):FireClient(p,A.State(p)) end end
local function broadcast() for _,p in Players:GetPlayers() do send(p) end end
function A.Leave(p)
	if transferring[p] then return false,"กำลังส่งเข้าสนาม" end
	queued[p]=nil;broadcast();return true,"ออกจากคิวแล้ว"
end
function A.Join(p,id,ranked)
	if not mode(id) or type(ranked)~="boolean" then return false,"โหมดไม่ถูกต้อง" end
	local ok,msg=eligible(p);if not ok then return false,msg end
	if target()<=0 or target()==game.PlaceId then return false,"สนาม Arena ยังไม่พร้อม" end
	if transferring[p] then return false,"กำลังส่งเข้าสนาม" end
	if queued[p] then return false,"ออกจากคิวเดิมก่อน" end
	queued[p]={mode=id,ranked=ranked,at=os.clock()};broadcast();return true,"เข้าคิว "..mode(id).name
end
function A.TransferFailed(p,placeId,options)
	local t=transferring[p]
	if not t or t.placeId~=placeId or t.options~=options then return false end
	transferring[p]=nil;send(p);if p.Parent==Players then Net.Event("Notify"):FireClient(p,"เข้า Arena ไม่สำเร็จ กรุณาเข้าคิวใหม่") end
	return true
end
function A.Step(now)
	for p,t in transferring do if p.Parent~=Players or now>=t.untilTime then A.TransferFailed(p,t.placeId,t.options) end end
	for p in queued do if not eligible(p) then queued[p]=nil end end
	if not F.IsEnabled("PvP") or target()<=0 then table.clear(queued);broadcast();return end
	for _,m in C.Modes do for _,ranked in {true,false} do
		local group={};for p,q in queued do if q.mode==m.id and q.ranked==ranked then table.insert(group,p) end end
		table.sort(group,function(a,b) return queued[a].at<queued[b].at end)
		local n=math.min(#group,m.max);if m.teams then n-=n%2 end
		if n<m.min or (#group<m.max and now-queued[group[1]].at<C.FillSeconds and m.id~="Duel") then continue end
		while #group>n do table.remove(group) end
		local options=Instance.new("TeleportOptions");options.ShouldReserveServer=true
		options:SetTeleportData({mode=m.id,ranked=ranked}) -- hints only; destination validates the reserved match
		local placeId=target()
		for _,p in group do queued[p]=nil;transferring[p]={mode=m.id,ranked=ranked,placeId=placeId,options=options,untilTime=now+C.TransferTimeout};send(p) end
		local ok,err=pcall(function()
			if testTransport then testTransport(placeId,group,options)
			elseif game.RunService:IsStudio() then error("Teleport needs the Roblox client")
			else Teleport:TeleportAsync(placeId,group,options) end
		end)
		if not ok then
			warn("[Arena] Transfer failed: "..tostring(err))
			for _,p in group do A.TransferFailed(p,placeId,options) end
		end
	end end
	broadcast()
end
-- Studio transport seam never grants currency or writes profile data.
function A.SetTestTransport(callback,placeId)
	assert(game.RunService:IsStudio());testTransport=callback;testPlace=placeId
end
function A.Init()
	Net.Function("ArenaAction").OnServerInvoke=function(p,action,id,ranked)
		local now=os.clock();if now<(last[p] or 0) then return false,"รอสักครู่" end;last[p]=now+.35
		if action=="State" then return true,"",A.State(p) end
		if action=="Join" then return A.Join(p,id,ranked) elseif action=="Leave" then return A.Leave(p) end
		return false,"คำสั่งไม่ถูกต้อง"
	end
	Players.PlayerRemoving:Connect(function(p) queued[p]=nil;transferring[p]=nil;last[p]=nil;broadcast() end)
	Teleport.TeleportInitFailed:Connect(function(p,_,_,placeId,options) A.TransferFailed(p,placeId,options) end)
	local function attach(portal)
		local part=portal:IsA("Model") and portal.PrimaryPart or portal:IsA("BasePart") and portal
		if not part or part:FindFirstChild("ArenaPrompt") then return end
		local prompt=Instance.new("ProximityPrompt");prompt.Name="ArenaPrompt";prompt.ActionText="เลือกโหมด";prompt.ObjectText="Chop Arena";prompt.MaxActivationDistance=C.PortalRange;prompt.RequiresLineOfSight=false;prompt.Parent=part
		prompt.Triggered:Connect(function(p) if eligible(p) then Net.Event("ArenaShow"):FireClient(p) end end)
	end
	for _,portal in Collection:GetTagged("ArenaPortal") do attach(portal) end
	Collection:GetInstanceAddedSignal("ArenaPortal"):Connect(attach)
	game.ReplicatedStorage.FeatureFlags:GetAttributeChangedSignal("PvP"):Connect(function() if not F.IsEnabled("PvP") then table.clear(queued);broadcast() end end)
end
function A.Start() while true do task.wait(1);A.Step(os.clock()) end end
return A
