-- Official Luau CLI: call returned function with ArenaService and Config.Arena source.
-- Isolated platform stubs exercise production queue code; no account/store writes.
return function(serviceSource,configSource)
	local C=assert(loadstring(configSource))();C.PlaceId=0;local checks=0 -- start unconfigured
	local function check(name,ok) assert(ok,name);checks+=1 end
	local function signal() local s={};function s:Connect(fn) self.callback=fn end;return s end
	local Players={PlayerRemoving=signal()};local players={}
	function Players:GetPlayers() return players end
	local enabled,studio=true,true
	local D={IsLoaded=function(p) return p.loaded end,Get=function(p) return p.active end}
	local F={IsEnabled=function() return enabled end}
	local P={Mounted=function(p) return p.mount end}
	local position=function(distance) return setmetatable({distance=distance},{__sub=function(a,b) return {Magnitude=math.abs(a.distance-b.distance)} end}) end
	local portal={GetPivot=function() return {Position=position(0)} end,IsDescendantOf=function() return true end,IsA=function() return false end}
	local Collection={GetTagged=function() return {portal} end,GetInstanceAddedSignal=function() return signal() end}
	local Teleport={TeleportInitFailed=signal()}
	local events={};local action={};local Net={Function=function() return action end,Event=function(name)
		events[name]=events[name] or {FireClient=function() end};return events[name]
	end}
	local shared={Config={Arena=C,Weapons={ById={}}},Net=Net};local services={DataService=D,FeatureService=F,PetService=P,WeaponService={Equipped=function() return nil end}}
	local env=setmetatable({game={PlaceId=10,RunService={IsStudio=function() return studio end},ReplicatedStorage={Shared=shared,FeatureFlags={GetAttributeChangedSignal=function() return signal() end}},GetService=function(_,id) return ({Players=Players,CollectionService=Collection,TeleportService=Teleport})[id] end},script={Parent=services},workspace={},require=function(value) return value end,warn=function() end,Instance={new=function(class)
		assert(class=="TeleportOptions");return {SetTeleportData=function(self,data) self.data=data end}
	end}},{__index=getfenv()})
	local fn=assert(loadstring(serviceSource));setfenv(fn,env);local A=fn();A.Init()
	local function player()
		local p={Parent=Players,loaded=true,attributes={},health=100,distance=0}
		function p:GetAttribute(k) return self.attributes[k] end
		p.Character={FindFirstChildOfClass=function() return {Health=p.health} end,FindFirstChild=function() return {Position=position(p.distance)} end}
		table.insert(players,p);return p
	end
	local calls={};local function transport(placeId,group,options) table.insert(calls,{placeId=placeId,group=group,options=options}) end
	local function clear() A.Step(os.clock()+1000);for _,p in players do A.Leave(p) end;table.clear(calls) end
	local p=player();local b=player()
	check("Unconfigured destination rejects join",not A.Join(p,"Duel",true))
	A.SetTestTransport(transport,20);enabled=false;check("Feature off rejects join",not A.Join(p,"Duel",true));enabled=true
	check("Unknown mode rejected",not A.Join(p,{},true));check("Ranked type validated",not A.Join(p,"Duel","true"))
	p.loaded=false;check("Unloaded profile rejected",not A.Join(p,"Duel",true));p.loaded=true
	p.health=0;check("Dead character rejected",not A.Join(p,"Duel",true));p.health=100
	p.distance=25;check("Remote join checks portal distance",not A.Join(p,"Duel",true));p.distance=0
	p.active=true;check("Active Run rejected",not A.Join(p,"Duel",true));p.active=false
	p.attributes.CarryingEgg=true;check("Carried egg rejected",not A.Join(p,"Duel",true));p.attributes.CarryingEgg=nil
	p.mount="pet";check("Mounted player rejected",not A.Join(p,"Duel",true));p.mount=nil
	check("Eligible join succeeds",A.Join(p,"Duel",true));check("Duplicate join rejected",not A.Join(p,"FFA",false))
	check("Queue count replicated",A.State(p).counts.Duel==1);A.Step(os.clock());check("Duel waits for opponent",#calls==0)
	check("Casual join succeeds",A.Join(b,"Duel",false));check("Casual remains false",A.State(b).ranked==false)
	A.Step(os.clock());check("Ranked and Casual never mix",#calls==0);A.Leave(b);A.Join(b,"Duel",true);A.Step(os.clock())
	check("Duel sends exactly two",#calls==1 and #calls[1].group==2 and calls[1].placeId==20)
	check("Reserved server and mode only",calls[1].options.ShouldReserveServer and calls[1].options.data.mode=="Duel" and calls[1].options.data.ranked==true and calls[1].options.data.stats==nil)
	check("Transfer blocks requeue and cancel",not A.Join(p,"Duel",true) and not A.Leave(p))
	check("Unrelated failure ignored",not A.TransferFailed(p,21,calls[1].options) and not A.TransferFailed(p,20,{}))
	check("Matching failure clears only affected player",A.TransferFailed(p,20,calls[1].options) and not A.State(p).transferring and A.State(b).transferring)
	A.Step(os.clock()+1000);check("Timeout clears remaining transfer",not A.State(b).transferring);clear()
	A.SetTestTransport(function() error("synthetic transport failure") end,20);A.Join(p,"Duel",true);A.Join(b,"Duel",true);A.Step(os.clock())
	check("Synchronous failure frees both players",not A.State(p).transferring and not A.State(b).transferring);A.SetTestTransport(transport,20)
	A.Join(p,"FFA",false);A.Join(b,"FFA",false);A.Step(os.clock());check("FFA waits fill period",#calls==0)
	A.Step(os.clock()+16);check("FFA starts after fill period",#calls==1 and #calls[1].group==2);clear()
	for _=1,5 do player() end
	for _,x in players do A.Join(x,"FFA",true) end;A.Step(os.clock());check("Full FFA starts with seven",#calls==1 and #calls[1].group==7);clear()
	for _,id in {"TimberClash","EggHeist"} do
		for i=1,3 do A.Join(players[i],id,true) end;A.Step(os.clock()+16);check(id.." needs four",#calls==0)
		A.Join(players[4],id,true);A.Join(players[5],id,true);A.Step(os.clock()+16)
		check(id.." uses an even team count",#calls==1 and #calls[1].group==4 and A.State(players[5]).mode==id);clear()
	end
	A.Join(p,"Duel",true);p.distance=25;A.Step(os.clock());check("Leaving portal cancels queue",A.State(p).mode==nil);p.distance=0
	A.Join(p,"Duel",true);enabled=false;A.Step(os.clock());check("Flag off clears queues",A.State(p).mode==nil);enabled=true
	A.Join(p,"Duel",true);Players.PlayerRemoving.callback(p);check("Disconnect clears queue",A.State(p).mode==nil)
	check("Remote unknown action rejected",not action.OnServerInvoke(p,"Cheat"));check("Remote spam rejected",not action.OnServerInvoke(p,"Join","Duel",true))
	studio=false;check("Transport seam Studio only",not pcall(A.SetTestTransport,transport,20))
	return checks
end
