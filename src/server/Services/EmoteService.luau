-- Weapon showcase aura (plan 9.4). Animations replicate from the client; the aura is
-- created here so every player sees it. Colour comes from the equipped weapon only.
local Debris=game:GetService("Debris")
local S=game.ReplicatedStorage.Shared
local Weapons=require(S.Config.Weapons)
local Rarities=require(S.Config.Rarities)
local Net=require(S.Net)
local D=require(script.Parent.DataService)
local F=require(script.Parent.FeatureService)
local W=require(script.Parent.WeaponService)
local E={}
local ELEMENT={["ไฟ"]=Color3.fromRGB(255,110,50),["น้ำ"]=Color3.fromRGB(70,170,255),["ลม"]=Color3.fromRGB(150,240,190),["สายฟ้า"]=Color3.fromRGB(255,230,80),
	["เงา"]=Color3.fromRGB(130,70,200),["แสง"]=Color3.fromRGB(255,245,190),["ธรรมชาติ"]=Color3.fromRGB(90,210,90),["จักรวาล"]=Color3.fromRGB(200,120,255)}
local COOLDOWN,SECONDS=4,3
local last={}
function E.Color(p)
	local item=W.Equipped(p);local def=item and Weapons.ById[item.id]
	if not def then return Color3.fromRGB(255,255,255) end
	return ELEMENT[def.element] or Rarities.Color[def.rarity]
end
function E.Showcase(p)
	local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid");local hr=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not F.IsEnabled("Emotes") or not D.IsLoaded(p) or not hum or hum.Health<=0 or not hr then return false end
	local now=os.clock();if now<(last[p] or 0) then return false end;last[p]=now+COOLDOWN
	local color=E.Color(p);local fx=Instance.new("Attachment");fx.Name="ShowcaseAura"
	local e=Instance.new("ParticleEmitter");e.Color=ColorSequence.new(color);e.LightEmission=1;e.Rate=60;e.Lifetime=NumberRange.new(.6,1.1)
	e.Speed=NumberRange.new(4,7);e.SpreadAngle=Vector2.new(180,180);e.Size=NumberSequence.new(.5,0);e.Parent=fx
	local light=Instance.new("PointLight");light.Color=color;light.Range=14;light.Brightness=3;light.Parent=fx
	fx.Parent=hr;Debris:AddItem(fx,SECONDS);return true
end
function E.Init()
	Net.Event("EmoteAction").OnServerEvent:Connect(function(p,action) if action=="Showcase" then E.Showcase(p) end end)
	game.Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
end
function E.Start() end
return E
