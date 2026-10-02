-- Base decoration. Add to the main place ServerScriptService in Edit, press Play, read workspace DecorResults, then delete it.
-- Always restores the real profile.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services
local D=require(V.DataService);local F=require(V.FeatureService);local Dec=require(V.DecorService);local G=require(V.GardenService);local R=require(V.RunService)
local C=require(game.ReplicatedStorage.Shared.Config.Decor)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait();assert(D.WaitForData(p,120));task.wait(2)
local original=D.ExportJSON(p);local pivot=p.Character:GetPivot();local flags={Decor=F.IsEnabled("Decor"),AutoSave=F.IsEnabled("AutoSave")}
local results={}
local function check(name,ok) assert(ok,name);table.insert(results,name) end
local base=G.Base(p);local slab=base.PrimaryPart
local function at(x,z) p.Character:PivotTo(slab.CFrame*CFrame.new(x,4,z));task.wait(.2) end
local function wood() return D.GetCurrency(p,"Wood") end
local function count() local n=0;for _ in D.Get(p,"Decor.items") do n+=1 end;return n end
local ok,err=xpcall(function()
	R.End(p,false);F.Set("Decor",true);F.Set("AutoSave",false);D.Set(p,"Meta.AdminTouched",true)
	D.Set(p,"Decor",{items={},next=0});D.Set(p,"Progress.Shrines",{});D.SetCurrency(p,"Wood",1e6);Dec.Build(p)
	at(5,7);local w=wood()
	check("Placing buys the piece on the 4-stud grid",Dec.Place(p,"fence") and wood()==w-C.ById.fence.price and D.Get(p,"Decor.items").d1.x==4 and D.Get(p,"Decor.items").d1.z==8)
	local model=base.Decor:FindFirstChild("d1")
	check("Pieces are built without collision and add beauty",model and #model:GetChildren()==1 and not model:GetChildren()[1].CanCollide and base:GetAttribute("Beauty")==C.ById.fence.beauty)
	check("A taken cell is refused",not Dec.Place(p,"bush") and count()==1)
	at(13,7);check("Zone pieces stay locked until their shrine is lit",not Dec.Place(p,"maple") and count()==1)
	D.Set(p,"Progress.Shrines",{["2"]=true});check("Lit shrine unlocks the zone piece",Dec.Place(p,"maple") and count()==2)
	at(60,0);check("Off your own slab is refused",not Dec.Place(p,"bush") and count()==2)
	at(5,7);check("Rotate turns the nearest piece",Dec.Rotate(p) and D.Get(p,"Decor.items").d1.r==1)
	w=wood();check("Remove refunds half",Dec.Remove(p) and wood()==w+math.floor(C.ById.fence.price*C.Refund) and not D.Get(p,"Decor.items").d1 and not base.Decor:FindFirstChild("d1"))
	D.SetCurrency(p,"Wood",0);check("Not enough Wood is refused",not Dec.Place(p,"bush") and count()==1);D.SetCurrency(p,"Wood",1e6)
	local full={};for i=1,C.MaxItems do full["f"..i]={id="path",x=100+i,z=0,r=0} end;D.Set(p,"Decor",{items=full,next=0})
	check("The piece cap is enforced",not Dec.Place(p,"bush") and count()==C.MaxItems)
	D.Set(p,"Decor",{items={},next=0});F.Set("Decor",false);check("Feature off refuses decorating",not Dec.Place(p,"bush"));F.Set("Decor",true)
end,debug.traceback)
for id,v in flags do F.Set(id,v) end
D.ImportJSON(p,original);p.Character:PivotTo(pivot);Dec.Build(p);D.SaveNow(p)
local o=game.HttpService:JSONDecode(original)
local restored=D.GetCurrency(p,"Wood")==o.Currencies.Wood and D.Get(p,"Meta.AdminTouched")==o.Meta.AdminTouched and game.HttpService:JSONEncode(D.Get(p,"Progress.Shrines"))==game.HttpService:JSONEncode(o.Progress.Shrines)
workspace:SetAttribute("DecorResults",game.HttpService:JSONEncode({passed=ok and restored,restored=restored,checks=results,error=not ok and err or nil}))
print("[DecorScenario]",ok and "passed" or err,#results,"restored",restored)
