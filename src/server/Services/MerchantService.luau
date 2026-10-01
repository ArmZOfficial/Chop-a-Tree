-- Squirrel merchant: UTC hourly visit, server-owned stock/price/limits.
-- UI lives in the Garden panel; GardenService forwards State/Buy through SetMerchant.
local Players=game:GetService("Players")
local S=game.ReplicatedStorage.Shared
local C=require(S.Config.Merchant)
local Math=require(S.MerchantMath)
local Net=require(S.Net)
local D=require(script.Parent.DataService)
local F=require(script.Parent.FeatureService)
local G=require(script.Parent.GardenService)
local P=require(script.Parent.PetService)
local W=require(script.Parent.WeaponService)
local M={}
local summon,model,shownKey
local FEATURE={seed="Garden",egg="Eggs",chest="Chests"}

function M.Visit()
	if not F.IsEnabled("Merchant") then return nil end
	local now=os.time()
	if summon and summon.endsAt>now then return summon end
	summon=nil;return (Math.Visit(now))
end
function M.Summon(seconds)
	local now=os.time();summon=seconds and {key="admin:"..now,seed=now,endsAt=now+seconds} or nil;M.Update()
end
local function near(p)
	local char=p.Character;local hum=char and char:FindFirstChildOfClass("Humanoid");local hr=char and char:FindFirstChild("HumanoidRootPart")
	return hum and hum.Health>0 and hr and model and model.Parent and not D.Get(p,"Run.Active") and (hr.Position-model:GetPivot().Position).Magnitude<=C.Range
end
local function bought(p,key) local b=D.Get(p,"Merchant.bought")[key];return b and b.n or {} end
function M.State(p)
	local visit=M.Visit();if not visit or not D.IsLoaded(p) then return nil end
	local zone,have,rows=G.ShopZone(p),bought(p,visit.key),{}
	for _,id in Math.Stock(visit.seed) do
		local currency,price=Math.Price(id,zone)
		table.insert(rows,{id=id,name=Math.Name(id),currency=currency,price=price,left=C.ById[id].limit-(have[id] or 0)})
	end
	return {key=visit.key,endsAt=visit.endsAt,offers=rows}
end
function M.Buy(p,id)
	local visit=M.Visit();local o=C.ById[id]
	if not visit or not D.IsLoaded(p) then return false,"พ่อค้าเร่ยังไม่มา" end
	if not o or not table.find(Math.Stock(visit.seed),id) then return false,"รอบนี้ไม่มีของชิ้นนี้" end
	if not F.IsEnabled(FEATURE[o.kind]) then return false,"ระบบนี้ปิดอยู่" end
	if not near(p) then return false,"ไปคุยกับพ่อค้าเร่ในหมู่บ้าน (นอก Run)" end
	local marks=D.Get(p,"Merchant.bought");local row=marks[visit.key] or {at=os.time(),n={}}
	if (row.n[id] or 0)>=o.limit then return false,"ซื้อครบจำนวนรอบนี้แล้ว" end
	if o.kind=="egg" and P.EggRoom(p)<=0 then return false,"ไข่เต็มกระเป๋า" end
	local zone=G.ShopZone(p);local currency,price=Math.Price(id,zone)
	if D.GetCurrency(p,currency)<price then return false,currency.." ไม่พอ" end
	-- Validated; marker, debit and grant commit together without yielding.
	for key,r in marks do if r.at<os.time()-C.KeepSeconds then marks[key]=nil end end
	row.n[id]=(row.n[id] or 0)+1;marks[visit.key]=row;D.Set(p,"Merchant.bought",marks);D.AddCurrency(p,currency,-price)
	local admin,rb=D.Get(p,"Meta.AdminTouched")==true,D.Get(p,"Progress.Rebirth")
	if o.kind=="seed" then G.GrantSeed(p,o.item,zone,rb,1,admin)
	elseif o.kind=="egg" then P.GrantEgg(p,{id=o.item,rebirthDrop=rb,admin_spawned=admin})
	else W.GrantChest(p,o.item,o.level,zone,1,admin) end
	return true,"ซื้อ "..Math.Name(id).." แล้ว"
end
function M.Update()
	local visit=M.Visit();local key=visit and visit.key
	if model then model.Parent=visit and workspace or nil end
	if key and key~=shownKey then Net.Event("Notify"):FireAllClients({text="พ่อค้าเร่กระรอกมาถึงหมู่บ้านแล้ว! อยู่ 10 นาที"}) end
	shownKey=key
end
function M.GetModel() return model end
local function build()
	-- ponytail: placeholder Part squirrel; real model/animation in Phase 10.
	local m=Instance.new("Model");m.Name="MerchantSquirrel"
	local function part(name,size,offset,color,ball)
		local x=Instance.new("Part");x.Name=name;x.Size=size;x.Anchored=true;x.CanCollide=false;x.Color=color;x.Material=Enum.Material.SmoothPlastic
		if ball then x.Shape=Enum.PartType.Ball end;x.Position=C.Position+offset;x.Parent=m;return x
	end
	local ray=workspace:Raycast(C.Position+Vector3.new(0,60,0),Vector3.new(0,-120,0))
	local ground=ray and ray.Position.Y or 2
	local body=part("Body",Vector3.new(3,3.4,2.6),Vector3.new(0,ground+1.7,0),Color3.fromRGB(176,104,52))
	part("Head",Vector3.new(2.4,2.4,2.4),Vector3.new(0,ground+4.4,0),Color3.fromRGB(196,122,64),true)
	part("Tail",Vector3.new(1.6,4,1.6),Vector3.new(0,ground+3,1.9),Color3.fromRGB(150,86,40),true)
	part("Stall",Vector3.new(7,1,4),Vector3.new(0,ground+.5,-3),Color3.fromRGB(120,82,48))
	m.PrimaryPart=body
	local prompt=Instance.new("ProximityPrompt");prompt.Name="MerchantPrompt";prompt.ActionText="ดูของ";prompt.ObjectText="พ่อค้าเร่กระรอก"
	prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=C.Range-2;prompt.Parent=body
	prompt.Triggered:Connect(function(p) if M.Visit() then Net.Event("GardenShow"):FireClient(p,"Merchant");G.Send(p) end end)
	return m
end
function M.Init() model=build();G.SetMerchant(M) end
function M.Start() task.spawn(function() while true do M.Update();task.wait(1) end end) end
return M
