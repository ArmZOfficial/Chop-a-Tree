-- Minimal deterministic Roblox boundary used ONLY by run_map_systems.py; no DataStore APIs exist here.
local registry, loaders = {}, {}
local now = 100
local realOS = os
local os = { clock=function() return now end, time=function() return 1790956800+now end }
local warnings = {}
local function warn(message) table.insert(warnings,message) end
local function signal()
	local callbacks={}
	return {Connect=function(_,fn) callbacks[fn]=true;return {Disconnect=function() callbacks[fn]=nil end} end,
		Fire=function(_,...) for fn in callbacks do fn(...) end end}
end
local runtimeFolders={}
local function node(path)
	return setmetatable({_path=path},{__index=function(_,key)
		if key=="WaitForChild" then return function(_,name) return node(path.."."..name) end end
		if key=="FindFirstChild" then return function(_,name) return runtimeFolders[name] end end
		if key=="Parent" then return node(path:match("^(.*)%.[^.]+$") or "") end
		return node(path.."."..key)
	end})
end
local vectors={}
local function vec(x,y,z) return setmetatable({X=x,Y=y,Z=z or 0,_type="Vector3"},vectors) end
vectors.__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectors.__sub=function(a,b) return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectors.__mul=function(a,b) if type(a)=="number" then a,b=b,a end;return vec(a.X*b,a.Y*b,a.Z*b) end
vectors.__index=function(v,k) if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end end
local Vector3={new=vec,zero=vec(0,0,0)}
local Vector2={new=vec}
local Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end}
Color3.new=function(r,g,b) return {R=r,G=g,B=b} end
local cframes={}
cframes.__add=function(a,b) return setmetatable({Position=a.Position+b},cframes) end
cframes.__sub=function(a,b) return setmetatable({Position=a.Position-b},cframes) end
local CFrame={new=function(v,y,z) return setmetatable({Position=type(v)=="table" and v or vec(v,y,z)},cframes) end}
local Instance={new=function(class)
	local obj={ClassName=class,attributes={},Parent=true}
	function obj:SetAttribute(k,v) self.attributes[k]=v end
	function obj:GetAttribute(k) return self.attributes[k] end
	function obj:Destroy() self.Parent=nil end
	if class=="BindableEvent" then obj.Event=signal();function obj:Fire(...) self.Event:Fire(...) end end
	return obj
end}
local Enum={RaycastFilterType={Exclude="Exclude"}}
local RaycastParams={new=function() return {} end}
local OverlapParams=RaycastParams
local delayed={}
local task={delay=function(_,fn) table.insert(delayed,fn) end,spawn=function(fn) fn() end,defer=function(fn) fn() end}
local Random={new=function() return {NextNumber=function() return .9 end,NextInteger=function(_,a) return a end} end}
local list={}
local Players={PlayerRemoving=signal(),GetPlayers=function() return list end}
local tags={}
local Collection={GetTagged=function(_,tag) return tags[tag] or {} end,GetInstanceAddedSignal=function() return signal() end,GetInstanceRemovedSignal=function() return signal() end}
local workspace={blocked=false}
function workspace:GetServerTimeNow() return now end
local spawn={GetPivot=function() return CFrame.new(vec(0,4,1010)) end,IsDescendantOf=function() return true end}
local village={FindFirstChild=function(_,name) return name=="VillageSpawn" and spawn end}
local map={FindFirstChild=function(_,name) return name=="Village" and village end}
function workspace:FindFirstChild(name) return name=="Map" and map end
function workspace:Raycast() if not self.blocked then return {Instance={IsDescendantOf=function() return true end}} end end
function workspace:GetPartBoundsInBox() return self.blocked and {{CanCollide=true}} or {} end
local RS={Heartbeat=signal(),IsStudio=function() return true end}
local game={ReplicatedStorage=node("ReplicatedStorage"),ServerStorage=node("ServerStorage")}
function game:GetService(name) return ({Players=Players,RunService=RS,CollectionService=Collection,ReplicatedStorage=self.ReplicatedStorage,ServerStorage=self.ServerStorage})[name] or {} end
local function require(module)
	local path=module._path
	if registry[path]~=nil then return registry[path] end
	assert(loaders[path],"unmocked dependency "..path)
	local result=loaders[path]();registry[path]=result;return result
end
local function register(path,fn) loaders[path]=fn end
local function makePlayer(x,y,z)
	local p={Parent=Players,attributes={},data=nil,_arena={}}
	function p:SetAttribute(k,v) self.attributes[k]=v end
	function p:GetAttribute(k) return self.attributes[k] end
	function p:RequestStreamAroundAsync() if self.onStream then self.onStream() end end
	function p:GetAttributeChangedSignal() return signal() end
	local root={Position=vec(x,y,z)};local hum={Health=100}
	local char={attributes={}}
	function char:FindFirstChild(name) return name=="HumanoidRootPart" and root end
	function char:FindFirstChildOfClass() return hum end
	function char:SetAttribute(k,v) self.attributes[k]=v end
	function char:GetPivot() return CFrame.new(root.Position) end
	function char:PivotTo(cf) root.Position=cf.Position end
	p.Character=char;p.root=root;p.hum=hum
	table.insert(list,p);return p
end
local Data
local enabled={MapSystems=true,Story=true,Forest=true,Rebirth=true,IndexBonuses=true,Chests=true,Weather=true,WeatherEncounters=true}
registry["ServerScriptService.Server.Services.FeatureService"]={IsEnabled=function(key) return enabled[key]==true end}
registry["ServerScriptService.Server.Services.ArenaService"]={State=function(p) return p._arena end}
local mult=1
registry["ServerScriptService.Server.Services.PetService"]={Mult=function() return mult end,Dismount=function() end}
registry["ServerScriptService.Server.Services.RewardService"]={Mult=function() return 1 end}
registry["ServerScriptService.Server.Services.GardenService"]={ExpBuff=function() return 1 end,TreeDrop=function() end,Base=function(p) return p.base end}
registry["ServerScriptService.Server.Services.NestService"]={Drop=function() end,Secure=function() end}
local weather={id="Clear",endsAt=500,eventKey="mock"}
registry["ServerScriptService.Server.Services.WeatherService"]={Def=function() return {wood=1,coins=1,exp=1,hp=1} end,State=function() return weather end,Force=function(id) weather.id=id or "Clear" end}
registry["ReplicatedStorage.Shared.CollectionMath"]={Bonus=function() return 0 end,Permanent=function() return 1 end}
registry["ReplicatedStorage.Shared.RebirthMath"]={AutoReward=function() return .55 end,Rank=function() return 0 end}
registry["ReplicatedStorage.Shared.Loot"]={}
registry["ReplicatedStorage.Shared.ChestBuilder"]={}
registry["ReplicatedStorage.Shared.Config.Eggs"]={}
registry["ServerScriptService.Server.Services.BossService"]={}
local remotes={}
registry["ReplicatedStorage.Shared.Net"]={Event=function(name)
	if not remotes[name] then remotes[name]={OnServerEvent=signal(),FireClient=function() end,FireAllClients=function() end} end;return remotes[name]
end}
registry["ServerScriptService.Server.Packages.ProfileStore"]={}
local grants=0
registry["ServerScriptService.Server.Services.WeaponService"]={Combat=function() return {power=125,speed=1,area=0} end,GrantChest=function(p) if p.failGrant then return false end;grants+=1;return true end}
local function makeTree(zone)
	local root={Position=vec(810,9,0),Size=vec(2,10,2),Transparency=0,CanCollide=true,Color=Color3.fromRGB(80,150,60),Parent=true}
	function root:IsA(class) return class=="BasePart" end
	local model={attributes={Zone=zone,Tier=1},PrimaryPart=root,Parent=workspace,scale=1}
	function model:IsA(class) return class=="Model" end
	function model:IsDescendantOf() return self.Parent~=nil end
	function model:GetAttribute(k) return self.attributes[k] end
	function model:SetAttribute(k,v) self.attributes[k]=v end
	function model:GetDescendants() return {root} end
	function model:GetScale() return self.scale end
	function model:ScaleTo(value) root.Size=root.Size*(value/self.scale);self.scale=value end
	function model:GetPivot() return CFrame.new(root.Position) end
	function model:PivotTo(cf) root.Position=cf.Position end
	return model
end
