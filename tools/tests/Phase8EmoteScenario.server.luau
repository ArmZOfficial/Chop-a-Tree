-- Phase 8f showcase aura. Inject in Studio Play; reads the equipped weapon, writes no profile data.
assert(game:GetService("RunService"):IsStudio())
local V=game.ServerScriptService.Server.Services;local S=game.ReplicatedStorage.Shared
local F=require(V.FeatureService);local E=require(V.EmoteService);local W=require(V.WeaponService);local Weapons=require(S.Config.WeaponCatalog);local Rarities=require(S.Config.Rarities)
local p=game.Players:GetPlayers()[1];local results={};local flag=F.IsEnabled("Emotes")
local function check(name,ok) assert(ok,name);table.insert(results,{name=name,passed=true}) end
local function aura() return p.Character.HumanoidRootPart:FindFirstChild("ShowcaseAura") end
workspace:SetAttribute("Phase8EmoteStatus","running")
local ok,err=xpcall(function()
 F.Set("Emotes",true);task.wait(4.1)
 local item=W.Equipped(p);local def=item and Weapons.ById[item.id]
 check("Aura colour follows the equipped weapon element or rarity",def==nil and E.Color(p)==Color3.new(1,1,1) or def.element==nil and E.Color(p)==Rarities.Color[def.rarity] or def.element~=nil and E.Color(p)~=nil)
 check("Showcase creates a replicated aura",E.Showcase(p) and aura()~=nil and aura():FindFirstChildOfClass("ParticleEmitter").Color.Keypoints[1].Value==E.Color(p))
 check("Cooldown blocks spam",not E.Showcase(p))
 task.wait(3.3);check("Aura is removed after 3 seconds",aura()==nil)
 task.wait(1);F.Set("Emotes",false);check("Feature off blocks showcase",not E.Showcase(p));F.Set("Emotes",true)
end,debug.traceback)
F.Set("Emotes",flag)
workspace:SetAttribute("Phase8EmoteResults",game.HttpService:JSONEncode({passed=ok,checks=results,error=not ok and err or nil}));workspace:SetAttribute("Phase8EmoteStatus",ok and "passed" or "failed")
print("[Phase8EmoteScenario]",ok and "passed" or err,#results)
