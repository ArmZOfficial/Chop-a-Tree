-- Finish before stopping Play; never publish a global event from this harness.
assert(game.RunService:IsStudio())
local V=game.ServerScriptService.Server.Services
local D=require(V.DataService);local F=require(V.FeatureService);local WX=require(V.WeatherService);local L=require(V.LiveEventService)
local p=game.Players:GetPlayers()[1];assert(D.WaitForData(p,30))
local original=D.ExportJSON(p);script:SetAttribute("OriginalData",original)
local weather=WX.GetOverride();local preview=L.GetPreview();local flags={};for _,id in {"Weather","LiveEvents","Leaderboard"} do flags[id]=F.IsEnabled(id) end
local root=p.Character.HumanoidRootPart;local anchor=root.Anchored
root.Anchored=true;F.Set("Weather",true);F.Set("LiveEvents",true);F.Set("Leaderboard",false);L.Preview(nil);WX.Force("Clear",300)
script:SetAttribute("Ready",true)
while not script:GetAttribute("Finish") do task.wait(.1) end
D.ImportJSON(p,original);L.Preview(preview);for id,v in flags do F.Set(id,v) end
if weather then WX.Force(weather.id,math.max(1,weather.endsAt-os.time())) else WX.Force(nil) end
root.Anchored=anchor;require(V.PetService).Refresh(p);require(V.GardenService).Send(p);require(V.QuestService).Send(p,true);require(V.RunService).Send(p)
local after=D.ExportJSON(p);local b=game.HttpService:JSONDecode(original);local a=D.GetData(p);local changes={}
local function same(x,y,path) if type(x)~=type(y) then table.insert(changes,path);return end;if type(x)=="table" then for k,v in x do same(v,y[k],path.."."..tostring(k)) end;for k in y do if x[k]==nil then table.insert(changes,path.."."..tostring(k)) end end elseif x~=y then table.insert(changes,path) end end
for _,key in {"Currencies","Inventory","Progress","Index","Achievements","Rebirth","Garden","Quests"} do same(b[key],a[key],key) end
workspace:SetAttribute("WeatherGUIRestoration",game.HttpService:JSONEncode({passed=#changes==0,mismatches=changes}));script:SetAttribute("Restored",true)
