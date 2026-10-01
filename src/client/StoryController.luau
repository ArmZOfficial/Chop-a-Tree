-- Story UI: quest tracker + guide beam, dialogue, banners, boss bar, quest/Index/warp panel,
-- and per-player zone gates/shrines (local collision only; rewards stay server-checked).
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Tween=game:GetService("TweenService")
local S=game.ReplicatedStorage.Shared
local Net=require(S.Net);local UI=require(S.UIKit);local NF=require(S.NumberFormat);local Balance=require(S.Balance)
local Zones=require(S.Config.Zones);local Weapons=require(S.Config.Weapons);local Pets=require(S.Config.Pets);local Seeds=require(S.Config.Seeds)
local Mutations=require(S.Config.Mutations)
local Data=require(script.Parent.ClientData)
local Controller={}
local TABS={{"Main","เควสหลัก"},{"Daily","รายวัน"},{"Weekly","รายสัปดาห์"},{"Index","Index"},{"Warp","วาร์ป"}}
local CATS={{"weapons","อาวุธ"},{"pets","สัตว์เลี้ยง"},{"seeds","ต้นไม้/เมล็ด"},{"mutations","Mutation"}}

local function tagged(tag,attr,value)
	for _,x in Collection:GetTagged(tag) do if x:IsDescendantOf(workspace) and x:GetAttribute(attr)==value then return x end end
end
local function myBase(player) return tagged("PlayerBase","BaseIndex",player:GetAttribute("BaseIndex")) end

function Controller.Start()
	local player=Players.LocalPlayer
	local gui=UI.New("ScreenGui",{Name="StoryHUD",ResetOnSpawn=false,DisplayOrder=8,Parent=player:WaitForChild("PlayerGui")})
	local quest,power=nil,0
	Net.Event("RunState").OnClientEvent:Connect(function(s) power=s.power or power end)

	-- Tracker in the left column under the menu buttons (the right side holds weather and the Run panel).
	local tracker=UI.New("Frame",{Name="Tracker",AnchorPoint=Vector2.new(0,0),Position=UDim2.fromOffset(16,475),Size=UDim2.fromOffset(250,96),BackgroundColor3=UI.Colors.Panel,BackgroundTransparency=.1,Visible=false,Parent=gui},{UI.Corner(12),UI.Stroke(3),UI.Padding(8)})
	local trackTitle=UI.Label("",13,{Name="Title",Size=UDim2.new(1,0,0,18),TextColor3=UI.Colors.AccentText,Parent=tracker})
	local trackStep=UI.Label("",15,{Name="Step",Position=UDim2.fromOffset(0,20),Size=UDim2.new(1,0,0,40),TextWrapped=true,Parent=tracker})
	local trackBack=UI.New("Frame",{Position=UDim2.new(0,0,1,-12),Size=UDim2.new(1,0,0,10),BackgroundColor3=UI.Colors.PanelDark,Parent=tracker},{UI.Corner(5)})
	local trackFill=UI.New("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=UI.Colors.Green,Parent=trackBack},{UI.Corner(5)})

	-- Guide beam on the ground toward the current objective.
	local beamFolder=Instance.new("Folder");beamFolder.Name="QuestGuide";beamFolder.Parent=workspace
	local a0=Instance.new("Attachment");local a1=Instance.new("Attachment")
	local anchor=Instance.new("Part");anchor.Name="GuideEnd";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.Transparency=1;anchor.Size=Vector3.one;anchor.Parent=beamFolder;a1.Parent=anchor
	local beam=Instance.new("Beam");beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=.6;beam.Width1=.1;beam.FaceCamera=true;beam.LightEmission=1
	beam.Color=ColorSequence.new(Color3.fromRGB(255,220,90));beam.Transparency=NumberSequence.new(.15,.6);beam.Enabled=false;beam.Parent=anchor
	local guideBill=Instance.new("BillboardGui");guideBill.Size=UDim2.fromOffset(170,30);guideBill.AlwaysOnTop=true;guideBill.StudsOffset=Vector3.new(0,1.5,0);guideBill.Enabled=false;guideBill.Parent=anchor
	local guideLabel=UI.Label("",14,{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=UI.Colors.AccentText,Parent=guideBill});UI.TextStroke(2).Parent=guideLabel

	local function target(cur)
		if not cur or cur.blocked then return nil end
		local unlocked=Data.Get("Progress.UnlockedZones") or {1};local forest=1
		for _,z in unlocked do if Zones.List[z] and Zones.List[z].built then forest=math.max(forest,z) end end
		local base=myBase(player)
		if cur.kind=="talk" then return tagged("NPC","NpcId",cur.npc)
		elseif cur.kind=="zone" then return tagged("ZoneSpawn","Zone",cur.zone)
		elseif cur.kind=="boss" then return tagged("Boss","Zone",cur.zone) or tagged("BossArena","Zone",cur.zone)
		elseif cur.kind=="shrine" then return tagged("Shrine","Zone",cur.zone)
		elseif cur.stat=="ChestsOpened" then return workspace.Map.Village:FindFirstChild("ChestAltar")
		elseif cur.stat=="SeedsPlanted" or cur.stat=="Harvests" then return base and base:FindFirstChild("GardenSlots") and base.GardenSlots:FindFirstChild("Slot1")
		elseif cur.stat=="EggsHatched" then return base and base:FindFirstChild("Incubator")
		elseif cur.stat=="BossKills" then return tagged("Boss","Zone",forest)
		else return tagged("ZoneSpawn","Zone",forest) end
	end

	-- Big centre banner (chapter end, shrine, boss intro/defeat).
	local banner=UI.New("Frame",{Name="Banner",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.32),Size=UDim2.fromOffset(620,110),BackgroundTransparency=1,Visible=false,Parent=gui})
	local bannerTitle=UI.Label("",40,{Name="Title",Size=UDim2.new(1,0,0,56),TextXAlignment=Enum.TextXAlignment.Center,TextColor3=UI.Colors.Accent,Parent=banner});UI.TextStroke(4).Parent=bannerTitle
	local bannerSub=UI.Label("",18,{Name="Sub",Position=UDim2.fromOffset(0,60),Size=UDim2.new(1,0,0,40),TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=true,Parent=banner});UI.TextStroke(2).Parent=bannerSub
	local bannerToken=0
	local function showBanner(title,sub,color)
		bannerToken+=1;local token=bannerToken
		bannerTitle.Text=title;bannerSub.Text=sub or "";bannerTitle.TextColor3=color or UI.Colors.Accent;banner.Visible=true
		bannerTitle.TextTransparency=1;bannerSub.TextTransparency=1;banner.Size=UDim2.fromOffset(780,140)
		Tween:Create(banner,TweenInfo.new(.35,Enum.EasingStyle.Back),{Size=UDim2.fromOffset(620,110)}):Play()
		Tween:Create(bannerTitle,TweenInfo.new(.25),{TextTransparency=0}):Play();Tween:Create(bannerSub,TweenInfo.new(.25),{TextTransparency=0}):Play()
		task.delay(3,function() if bannerToken==token then
			Tween:Create(bannerTitle,TweenInfo.new(.4),{TextTransparency=1}):Play();Tween:Create(bannerSub,TweenInfo.new(.4),{TextTransparency=1}):Play()
			task.wait(.45);if bannerToken==token then banner.Visible=false end
		end end)
	end

	-- Dialogue box; lines are short and always skippable (plan 1.1).
	local dialog=UI.New("Frame",{Name="Dialog",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-170),Size=UDim2.fromOffset(620,150),BackgroundColor3=UI.Colors.Panel,Visible=false,Parent=gui},{UI.Corner(16),UI.Stroke(4),UI.Padding(12)})
	local speaker=UI.Label("",18,{Name="Speaker",Size=UDim2.new(1,0,0,24),TextColor3=UI.Colors.AccentText,Parent=dialog})
	local line=UI.Label("",17,{Name="Line",Position=UDim2.fromOffset(0,28),Size=UDim2.new(1,0,0,60),TextWrapped=true,Parent=dialog})
	local lines,lineIndex={},1
	local function showLine() line.Text=lines[lineIndex] or "";dialog.Visible=lines[lineIndex]~=nil end
	local nextButton=UI.Button({text="ต่อไป",color=UI.Colors.Green,size=UDim2.fromOffset(140,40),onClick=function() lineIndex+=1;showLine() end})
	nextButton.Name="Next";nextButton.AnchorPoint=Vector2.new(1,1);nextButton.Position=UDim2.new(1,-150,1,0);nextButton.Parent=dialog
	local skipButton=UI.Button({text="ข้าม",color=UI.Colors.Slate,size=UDim2.fromOffset(140,40),onClick=function() dialog.Visible=false end})
	skipButton.Name="Skip";skipButton.AnchorPoint=Vector2.new(1,1);skipButton.Position=UDim2.new(1,0,1,0);skipButton.Parent=dialog
	local function talk(name,list) speaker.Text=name;lines=list;lineIndex=1;showLine() end

	-- Boss bar.
	local bossBar=UI.New("Frame",{Name="BossBar",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,118),Size=UDim2.fromOffset(460,58),BackgroundColor3=UI.Colors.PanelDark,BackgroundTransparency=.15,Visible=false,Parent=gui},{UI.Corner(12),UI.Stroke(3,UI.Colors.Purple),UI.Padding(8)})
	local bossName=UI.Label("",17,{Name="Name",Size=UDim2.new(1,0,0,20),TextXAlignment=Enum.TextXAlignment.Center,Parent=bossBar})
	local bossBack=UI.New("Frame",{Position=UDim2.new(0,0,1,-16),Size=UDim2.new(1,0,0,14),BackgroundColor3=UI.Colors.Input,ClipsDescendants=true,Parent=bossBar},{UI.Corner(7)})
	local bossFill=UI.New("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=UI.Colors.Purple,Parent=bossBack},{UI.Corner(7)})
	local introduced={}

	-- Panel (quests / Index / warp).
	local panel=UI.New("Frame",{Name="Panel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(780,570),Visible=false,BackgroundColor3=UI.Colors.Panel,Parent=gui},{UI.Corner(18),UI.Stroke(4),UI.Padding(14)})
	UI.Label("เควส • Index • วาร์ป",22,{Parent=panel})
	local message=UI.Label("",14,{Name="Message",Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,0,28),Parent=panel})
	local list=UI.New("ScrollingFrame",{Name="Items",Position=UDim2.fromOffset(0,112),Size=UDim2.new(1,0,1,-170),BackgroundTransparency=1,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Parent=panel},{UI.List(Enum.FillDirection.Vertical,8)})
	local tab="Main";local busy=false;local render
	local function call(action,arg)
		if busy then return end;busy=true
		task.spawn(function()
			local ok,success,msg=pcall(function() return Net.Function("StoryAction"):InvokeServer(action,arg) end)
			message.Text=ok and (msg or "") or "ติดต่อเซิร์ฟเวอร์ไม่ได้ ลองใหม่"
			message.TextColor3=ok and success and UI.Colors.Text or UI.Colors.Accent
			if ok and success and action=="Warp" then panel.Visible=false end
			task.wait(.32);busy=false;render()
		end)
	end
	-- Rows are updated in place so clicks are not lost during the 1-second refresh.
	local callbacks,keep,order={},{},0
	local function row(name,text,color,callback)
		order+=1;callbacks[name]=callback;keep[name]=true
		local b=list:FindFirstChild(name)
		if b then local label=b.Button:FindFirstChildWhichIsA("TextLabel",true);if label then label.Text=text end;UI.SetButtonColor(b,color)
		else b=UI.Button({text=text,color=color,size=UDim2.new(1,-7,0,54),onClick=function() local fn=callbacks[name];if fn then fn() end end});b.Name=name;b.Parent=list end
		b.LayoutOrder=order;return b
	end
	local function none() end
	local function sideRows(rows,kind,ends)
		row("Reset_"..kind,(kind=="daily" and "เควสรายวัน" or "เควสรายสัปดาห์").." • รีเซ็ตอีก "..math.max(0,math.floor((ends-os.time())/3600)).." ชม.",UI.Colors.Slate,none)
		for _,q in rows do local id=q.id
			row(kind.."_"..id,q.text.." • "..q.have.."/"..q.need.."\n"..(q.claimed and "รับรางวัลแล้ว" or (q.have>=q.need and "กดรับ +"..q.gems.." Gems" or "รางวัล "..q.gems.." Gems")),
				q.claimed and UI.Colors.Disabled or (q.have>=q.need and UI.Colors.Green or UI.Colors.Blue),function() call("Claim",{kind=kind,id=id}) end)
		end
	end
	render=function()
		if not panel.Visible or not quest then return end
		keep,order={},0
		if tab=="Main" then
			row("Chapter",quest.title,UI.Colors.Purple,none)
			for i,s in quest.steps do row("Step"..i,(s.done and "✓ " or (i==#quest.steps+1 and "" or "• "))..s.text,s.done and UI.Colors.Green or UI.Colors.Slate,none) end
			if quest.current then row("Current","ตอนนี้: "..quest.current.text..(quest.current.need>1 and " ("..quest.current.have.."/"..quest.current.need..")" or "")..(quest.current.blocked and "\nโซนนี้สร้างเต็มใน Phase 7" or ""),UI.Colors.Orange,none) end
		elseif tab=="Daily" then sideRows(quest.daily,"daily",quest.dailyEnds)
		elseif tab=="Weekly" then sideRows(quest.weekly,"weekly",quest.weeklyEnds)
		elseif tab=="Index" then
			local idx=Data.Get("Index") or {}
			for _,c in CATS do local cat=c[1];local n=quest.index[cat]
				row("Cat_"..cat,c[2].." • "..n.have.."/"..n.total..(idx.done and idx.done[cat] and " • ครบแล้ว!" or "").."\nของใหม่ +1 Gem • ครบหมวด +50 Gems (ไม่นับของที่แอดมินเสก)",n.have>=n.total and UI.Colors.Green or UI.Colors.Teal,none)
			end
			local function names(cat,listDefs,label)
				local have,missing=0,{};for _,d in listDefs do if idx[cat] and idx[cat][d.id] then have+=1 else table.insert(missing,d.name) end end
				row("Missing_"..cat,label.." ที่ยังไม่มี: "..(#missing==0 and "-" or table.concat(missing,", ")),UI.Colors.Slate,none)
			end
			names("pets",Pets.List,"สัตว์");names("seeds",Seeds.List,"เมล็ด")
			local muts={};for id in Mutations.Values do table.insert(muts,{id=id,name=id}) end;for id in Pets.Mutations do if not Mutations.Values[id] then table.insert(muts,{id=id,name=id}) end end
			table.sort(muts,function(a,b) return a.id<b.id end);names("mutations",muts,"Mutation")
			local rarity={};for _,w in Weapons.List do rarity[w.rarity]=rarity[w.rarity] or {0,0};rarity[w.rarity][2]+=1;if idx.weapons and idx.weapons[w.id] then rarity[w.rarity][1]+=1 end end
			local parts={};for _,r in {"Common","Rare","Epic","Legendary","Mythic"} do if rarity[r] then table.insert(parts,r.." "..rarity[r][1].."/"..rarity[r][2]) end end
			row("WeaponRarity","อาวุธตามความหายาก: "..table.concat(parts," • "),UI.Colors.Slate,none)
		else
			local unlocked=Data.Get("Progress.UnlockedZones") or {1}
			row("Warp0","หมู่บ้าน Rootfall\nจบ Run (ถ้ามี) แล้วกลับหมู่บ้าน",UI.Colors.Green,function() call("Warp",0) end)
			for _,z in Zones.List do local id=z.id;local open=table.find(unlocked,id)~=nil and z.built
				row("Warp"..id,"โซน "..id.." • "..z.thai.."\n"..(open and "วาร์ปแล้วเริ่ม Run ทันที" or (not z.built and "สร้างเต็มใน Phase 7" or "🔒 ล้มบอสและจุดศาลเจ้าโซนก่อนหน้า")),open and UI.Colors.Teal or UI.Colors.Disabled,function() if open then call("Warp",id) end end)
			end
		end
		for _,v in list:GetChildren() do if v:IsA("GuiObject") and not keep[v.Name] then v:Destroy() end end
	end
	for i,t in TABS do local target=t[1]
		local b=UI.Button({text=t[2],color=UI.Colors.Purple,size=UDim2.new(1/#TABS,-8,0,42),onClick=function() tab=target;message.Text="";render() end})
		b.Name="Tab"..target;b.Position=UDim2.new((i-1)/#TABS,0,0,64);b.Parent=panel
	end
	local close=UI.Button({text="ปิด",color=UI.Colors.Slate,size=UDim2.new(1,0,0,42),onClick=function() panel.Visible=false end})
	close.Name="Close";close.Position=UDim2.new(0,0,1,-48);close.Parent=panel
	local function resize() local size=workspace.CurrentCamera.ViewportSize;panel.Size=UDim2.fromOffset(math.min(780,size.X-28),math.min(570,size.Y-56)) end
	local function show(target)
		for _,name in {"InventoryHUD","GardenHUD","PetHUD"} do local other=player.PlayerGui:FindFirstChild(name);if other and other:FindFirstChild("Panel") then other.Panel.Visible=false end end
		if target then tab=target end;panel.Visible=true;resize();render()
	end
	local toggle=UI.Button({text="เควส & Index",color=UI.Colors.Purple,size=UDim2.fromOffset(178,48),onClick=function() if panel.Visible then panel.Visible=false else show() end end})
	toggle.Name="Toggle";toggle.Position=UDim2.fromOffset(16,417);toggle.Parent=gui
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	for _,name in {"InventoryHUD","GardenHUD","PetHUD"} do task.spawn(function()
		local other=player.PlayerGui:WaitForChild(name,30);local p=other and other:WaitForChild("Panel",10)
		if p then p:GetPropertyChangedSignal("Visible"):Connect(function() if p.Visible then panel.Visible=false end end) end
	end) end

	Net.Event("QuestState").OnClientEvent:Connect(function(packet)
		quest=packet;tracker.Visible=packet.enabled;toggle.Visible=packet.enabled
		trackTitle.Text=packet.title
		local cur=packet.current
		trackStep.Text=cur and (cur.text..(cur.need>1 and " "..cur.have.."/"..cur.need or "")..(cur.blocked and " (Phase 7)" or "")) or "จบบทหลักแล้ว"
		trackFill.Size=UDim2.fromScale(cur and math.clamp(cur.have/cur.need,0,1) or 1,1)
		render()
	end)
	Net.Event("StoryShow").OnClientEvent:Connect(function(msg)
		if msg.kind=="dialog" then talk(msg.speaker,msg.lines)
		elseif msg.kind=="banner" then showBanner(msg.title,msg.sub)
		elseif msg.kind=="shrine" then showBanner(msg.title,"",Color3.fromRGB(120,255,160));talk("ศาลเจ้า",msg.lines)
		elseif msg.kind=="warp" then show("Warp") end
	end)
	Net.Event("BossEvent").OnClientEvent:Connect(function(msg)
		local boss=tagged("Boss","Zone",msg.zone);local hr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if msg.kind=="defeated" and boss and hr and (hr.Position-boss:GetPivot().Position).Magnitude<160 then
			showBanner(msg.name,"ผู้พิทักษ์ถูกชำระแล้ว!",Color3.fromRGB(120,255,160))
			local cam=workspace.CurrentCamera;local fov=cam.FieldOfView
			Tween:Create(cam,TweenInfo.new(.25),{FieldOfView=fov+18}):Play();task.delay(.6,function() Tween:Create(cam,TweenInfo.new(.8),{FieldOfView=fov}):Play() end)
		end
	end)

	local originals={}
	task.spawn(function() while true do
		local hr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		-- Guide beam
		local goal=quest and quest.enabled and target(quest.current)
		local pos=goal and (goal:IsA("BasePart") and goal.Position or goal:GetPivot().Position)
		if hr and pos and (pos-hr.Position).Magnitude>14 then
			a0.Parent=hr;local flatDir=Vector3.new(pos.X-hr.Position.X,0,pos.Z-hr.Position.Z).Unit
			anchor.Position=hr.Position+flatDir*10+Vector3.new(0,-1.5,0);beam.Enabled=true;guideBill.Enabled=true
			guideLabel.Text=math.floor((pos-hr.Position).Magnitude).." studs"
		else beam.Enabled=false;guideBill.Enabled=false end
		-- Boss bar and intro
		local shown=false
		for _,boss in Collection:GetTagged("Boss") do
			local p=boss.PrimaryPart and boss.PrimaryPart.Position
			if hr and p and boss:GetAttribute("Alive")~=false and (p-hr.Position).Magnitude<90 then
				shown=true;local zone=boss:GetAttribute("Zone");local rb=Data.Get("Progress.Rebirth") or 0
				local weather=game.ReplicatedStorage:FindFirstChild("WeatherState");local health=weather and weather:GetAttribute("HealthMult") or 1
				local hp=Balance.BossHP(zone,rb)*health;local req=Balance.BossRequiredPower(zone,rb)*health;local ratio=boss:GetAttribute("HealthRatio") or 1
				bossName.Text=boss:GetAttribute("BossName").." • "..(power<req and ("🔒 ต้องการ Power "..NF.Short(req)) or (NF.Short(hp*ratio).." / "..NF.Short(hp)))
				bossName.TextColor3=power<req and UI.Colors.Red or UI.Colors.Text
				bossFill.Size=UDim2.fromScale(math.clamp(ratio,0,1),1)
				if not introduced[boss] then introduced[boss]=true;showBanner(string.upper(boss:GetAttribute("BossName")),"GUARDIAN • "..Zones.List[zone].thai,Color3.fromRGB(220,130,255)) end
			end
		end
		bossBar.Visible=shown
		-- Gates and shrines follow this player's progress only.
		local unlocked=Data.Get("Progress.UnlockedZones") or {1};local shrines=Data.Get("Progress.Shrines") or {}
		for _,gate in Collection:GetTagged("ZoneGate") do
			local wall=gate:FindFirstChild("RotBarrier")
			if wall then
				originals[wall]=originals[wall] or {wall.Transparency,wall.CanCollide}
				local open=table.find(unlocked,gate:GetAttribute("ToZone"))~=nil
				wall.CanCollide=not open and originals[wall][2];wall.Transparency=open and .9 or originals[wall][1]
			end
		end
		for _,shrine in Collection:GetTagged("Shrine") do
			local crystal=shrine:FindFirstChild("Crystal")
			if crystal then
				originals[crystal]=originals[crystal] or {crystal.Color,crystal.Material}
				local lit=shrines[tostring(shrine:GetAttribute("Zone"))]==true
				crystal.Color=lit and Color3.fromRGB(110,255,150) or originals[crystal][1];crystal.Material=lit and Enum.Material.Neon or originals[crystal][2]
				local light=crystal:FindFirstChild("ShrineLight")
				if lit and not light then light=Instance.new("PointLight");light.Name="ShrineLight";light.Color=Color3.fromRGB(110,255,150);light.Range=30;light.Brightness=4;light.Parent=crystal
				elseif not lit and light then light:Destroy() end
			end
		end
		if panel.Visible and (tab=="Warp" or tab=="Index") then render() end
		task.wait(.25)
	end end)
	task.spawn(function() while not Data.IsReady() do task.wait(.1) end;pcall(function() Net.Function("StoryAction"):InvokeServer("Sync") end) end)
end
return Controller
