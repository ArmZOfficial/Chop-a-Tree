-- Base decoration (plan 9.2): Wood-bought cosmetic pieces on a grid inside your own base slab.
-- Pieces never collide or give power, so they cannot block incubators or thieves. Rebirth keeps them.
local Players=game:GetService("Players")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local C=require(S.Config.Decor)
local Data=require(script.Parent.DataService);local Features=require(script.Parent.FeatureService);local Garden=require(script.Parent.GardenService)
local Weather=require(script.Parent.WeatherService)
local D={};local folders,last={},{};local villageFestival
-- One piece at a CFrame (used by bases and the festival village dressing).
function D.Piece(def,origin,parent,name)
	local m=Instance.new("Model");m.Name=name or def.id
	for _,spec in def.parts do
		local part=Instance.new("Part");part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
		part.Size=spec.size;part.CFrame=origin*CFrame.new(spec.offset);part.Color=spec.color;part.Material=spec.material;if spec.shape then part.Shape=spec.shape end
		if spec.light then local l=Instance.new("PointLight");l.Range=14;l.Color=spec.color;l.Parent=part end
		part.Parent=m
	end
	m.Parent=parent;return m
end
local function enabled(p) return Features.IsEnabled("Decor") and Data.IsLoaded(p) end
local function slab(p) local b=Garden.Base(p);return b and b.PrimaryPart end
function D.Beauty(items) local n=0;for _,it in items do local def=C.ById[it.id];if def then n+=def.beauty end end;return n end
function D.Build(p)
	if folders[p] then folders[p]:Destroy();folders[p]=nil end
	local s=slab(p);if not s or not Data.IsLoaded(p) then return end
	local folder=Instance.new("Folder");folder.Name="Decor";folder.Parent=s.Parent;folders[p]=folder
	local top=s.CFrame*CFrame.new(0,s.Size.Y/2,0);local items=Data.Get(p,"Decor.items")
	for uid,it in items do local def=C.ById[it.id];if def then D.Piece(def,top*CFrame.new(it.x,0,it.z)*CFrame.Angles(0,it.r*math.pi/2,0),folder,uid) end end
	s.Parent:SetAttribute("Beauty",D.Beauty(items))
	-- Like prompt on the slab; the owner is resolved when it fires, so a reassigned base never credits the old owner.
	local prompt=s:FindFirstChild("LikePrompt")
	if not prompt then
		prompt=Instance.new("ProximityPrompt");prompt.Name="LikePrompt";prompt.ActionText="Like Base";prompt.KeyboardKeyCode=Enum.KeyCode.L
		prompt.MaxActivationDistance=C.LikeRange/2;prompt.RequiresLineOfSight=false;prompt.Parent=s
		prompt.Triggered:Connect(function(liker)
			local ok,msg=D.Like(liker,Players:GetPlayerByUserId(s.Parent:GetAttribute("OwnerUserId") or 0))
			Net.Event("Notify"):FireClient(liker,{text=msg,kind=not ok and "warn" or nil})
		end)
	end
	prompt.ObjectText=tostring(Data.Get(p,"Decor.likes") or 0).." ♥"
end
-- One like per base owner per UTC day. The liker keeps only today's marks, so the ledger stays tiny.
function D.Like(p,owner)
	if not enabled(p) or not owner or not Data.IsLoaded(owner) then return false,"Base unavailable" end
	if owner==p then return false,"You cannot like your own base" end
	local s=slab(owner);local hr=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not s or not hr or (hr.Position-s.Position).Magnitude>C.LikeRange then return false,"Walk to that base first" end
	local day=os.time()//86400;local key=tostring(owner.UserId);local liked=Data.Get(p,"Decor.liked")
	if liked[key]==day then return false,"You already liked this base today" end
	for k,d in liked do if d~=day then liked[k]=nil end end
	liked[key]=day;Data.Set(p,"Decor.liked",liked)
	Data.Increment(owner,"Decor.likes",1);s.LikePrompt.ObjectText=tostring(Data.Get(owner,"Decor.likes")).." ♥"
	Net.Event("Notify"):FireClient(owner,{text="{1} liked your base!",vars={p.DisplayName}})
	return true,"Base liked"
end
-- Grid cell under the player in base-local space, or nil when off their own slab.
local function cellOf(p)
	local s=slab(p);local hr=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if not s or not hr then return end
	local o=s.CFrame:PointToObjectSpace(hr.Position);local half=s.Size.X/2-2
	local x,z=math.round(o.X/C.Grid)*C.Grid,math.round(o.Z/C.Grid)*C.Grid
	if math.abs(x)>half or math.abs(z)>half or o.Y<0 or o.Y>12 then return end
	return x,z
end
local function nearest(p)
	local x,z=cellOf(p);if not x then return end
	local best,bd;for uid,it in Data.Get(p,"Decor.items") do local d=math.abs(it.x-x)+math.abs(it.z-z);if d<=C.Grid*2 and (not bd or d<bd) then best,bd=uid,d end end
	return best
end
function D.Place(p,id,r)
	if not enabled(p) then return false,"Decorations unavailable" end
	local def=type(id)=="string" and C.ById[id];if not def then return false,"Item not owned" end
	if def.zone and not Data.Get(p,"Progress.Shrines")[tostring(def.zone)] then return false,"Unlock by lighting the shrine in zone "..def.zone end
	local fest=Weather.Festival();if def.festival and not (fest and fest.id==def.festival) then return false,"Available only during the festival" end
	local x,z=cellOf(p);if not x then return false,"Stand on your own base floor first" end
	local d=Data.Get(p,"Decor");local count=0
	for _,it in d.items do count+=1;if it.x==x and it.z==z then return false,"Slot already occupied" end end
	if count>=C.MaxItems then return false,"Placement limit "..C.MaxItems.." items" end
	if Data.GetCurrency(p,"Wood")<def.price then return false,"Wood Not enough" end
	Data.AddCurrency(p,"Wood",-def.price);d.next+=1
	d.items["d"..d.next]={id=id,x=x,z=z,r=(type(r)=="number" and r%1==0 and r>=0 and r<=3) and r or 0}
	Data.Set(p,"Decor",d);D.Build(p);return true,"Place "..def.name.." done"
end
function D.Rotate(p)
	if not enabled(p) then return false,"Decorations unavailable" end
	local uid=nearest(p);if not uid then return false,"Stand near your decoration first" end
	local d=Data.Get(p,"Decor");d.items[uid].r=(d.items[uid].r+1)%4;Data.Set(p,"Decor",d);D.Build(p);return true,"Rotated"
end
function D.Remove(p)
	if not enabled(p) then return false,"Decorations unavailable" end
	local uid=nearest(p);if not uid then return false,"Stand near your decoration first" end
	local d=Data.Get(p,"Decor");local def=C.ById[d.items[uid].id];d.items[uid]=nil;Data.Set(p,"Decor",d)
	local refund=def and math.floor(def.price*C.Refund) or 0;if refund>0 then Data.AddCurrency(p,"Wood",refund) end
	D.Build(p);return true,"Stored. Refunded "..refund.." Wood"
end
function D.Init()
	Net.Function("DecorAction").OnServerInvoke=function(p,action,arg)
		local now=os.clock();if now-(last[p] or -math.huge)<.3 then return false,"Please wait" end;last[p]=now
		if action=="Place" then return D.Place(p,arg) elseif action=="Rotate" then return D.Rotate(p) elseif action=="Remove" then return D.Remove(p) end
		return false,"Invalid command"
	end
	Data.PlayerLoaded:Connect(function(p) task.defer(D.Build,p) end) -- after GardenService assigns the base
	Data.Changed:Connect(function(p,path) if path=="" then task.defer(D.Build,p) end end)
	Players.PlayerRemoving:Connect(function(p) if folders[p] then folders[p]:Destroy() end;folders[p]=nil;last[p]=nil end)
end
-- Village dressing: a ring of the running festival's piece around the village spawn, removed when it ends.
function D.DressVillage()
	local fest=Features.IsEnabled("Decor") and Weather.Festival();local id=fest and fest.id
	if id==villageFestival then return end;villageFestival=id
	local village=workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Village");if not village then return end
	local old=village:FindFirstChild("FestivalDecor");if old then old:Destroy() end
	local def;for _,d in C.List do if id and d.festival==id then def=d end end;if not def then return end
	local spawn=village:FindFirstChild("VillageSpawn");if not spawn then return end
	local folder=Instance.new("Folder");folder.Name="FestivalDecor";folder.Parent=village
	local params=RaycastParams.new();params.FilterDescendantsInstances={folder}
	for i=1,C.VillagePieces do
		local a=i/C.VillagePieces*math.pi*2;local pos=spawn.Position+Vector3.new(math.cos(a),0,math.sin(a))*C.VillageRadius
		local hit=workspace:Raycast(pos+Vector3.new(0,40,0),Vector3.new(0,-80,0),params)
		if hit then D.Piece(def,CFrame.lookAt(hit.Position,Vector3.new(spawn.Position.X,hit.Position.Y,spawn.Position.Z)),folder) end
	end
end
function D.Start() while true do pcall(D.DressVillage);task.wait(5) end end
return D
