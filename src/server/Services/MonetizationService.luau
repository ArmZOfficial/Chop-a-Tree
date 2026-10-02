-- Robux shop (plan 17). Pass ownership is cached in the profile so shared math and UI can
-- read it; developer products grant only inside ProcessReceipt, once per PurchaseId.
local Players=game:GetService("Players")
local MS=game:GetService("MarketplaceService")
local S=game.ReplicatedStorage.Shared
local C=require(S.Config.Products)
local Eggs=require(S.Config.Eggs)
local Seeds=require(S.Config.Seeds)
local Net=require(S.Net)
local D=require(script.Parent.DataService)
local F=require(script.Parent.FeatureService)
local Reward=require(script.Parent.RewardService)
local W=require(script.Parent.WeaponService)
local P=require(script.Parent.PetService)
local G=require(script.Parent.GardenService)
local Steal=require(script.Parent.StealService)
local Ach=require(script.Parent.AchievementService)
local Season=require(script.Parent.SeasonService)
local M={}
local GEMS={gems100=100,gems550=550,gems1200=1200,gems6500=6500}
local BOOST={wood15={"Wood",900},wood30={"Wood",1800},coins15={"Coins",900},coins30={"Coins",1800},exp15={"Exp",900},exp30={"Exp",1800},luck15={"Luck",900},luck30={"Luck",1800}}
local last={}

function M.Owns(p,key) return D.IsLoaded(p) and D.Get(p,"Purchases.passes")[key]==true end
function M.Refresh(p)
	if not D.IsLoaded(p) then return end
	p:SetAttribute("VIP",M.Owns(p,"VIP"));Ach.RefreshTitle(p);P.Refresh(p);G.Send(p)
end
function M.SetPass(p,key,on)
	if not C.PassByKey[key] or not D.IsLoaded(p) then return false end
	local t=table.clone(D.Get(p,"Purchases.passes"));t[key]=on or nil;D.Set(p,"Purchases.passes",t);M.Refresh(p);return true
end
-- Checked before prompting so a utility product never sells into a no-op.
local READY={
	instantHatch=function(p) for _,e in D.Get(p,"Pets.incubator") do if not e.done and not e.carriedBy then return true end end;return false,"No eggs hatching in the incubator" end,
	instantGrow=function(p) for _,pl in D.Get(p,"Garden.plots") do if not pl.mature then return true end end;return false,"No growing trees" end,
	baseLock=function(p) local id=G.BaseIndex(p);if not id then return false,"No base yet" end;if Steal.Locked(id) then return false,"Base already locked" end;return true end,
}
-- Applies one product. Must not yield: ProcessReceipt writes the receipt marker right after.
function M.Grant(p,key)
	local now=os.time()
	if GEMS[key] then D.AddCurrency(p,"Gems",GEMS[key])
	elseif BOOST[key] then Reward.Grant(p,{boost={kind=BOOST[key][1],seconds=BOOST[key][2]}},now)
	elseif key=="serverLuck" then
		local untilAt=math.max(now,game.ReplicatedStorage:GetAttribute("ServerLuckUntil") or 0)+C.ServerLuckSeconds
		game.ReplicatedStorage:SetAttribute("ServerLuckUntil",untilAt)
		Net.Event("Notify"):FireAllClients({text=p.DisplayName.." activated +25% server Luck for 15 min!",color="Accent"})
	elseif key=="instantHatch" then
		local d=D.Get(p,"Pets");for _,e in d.incubator do if not e.done and not e.carriedBy then e.progress=Eggs.ById[e.id].hatch end end
		P.Advance(p,now,true);D.Set(p,"Pets",d);P.Send(p)
	elseif key=="instantGrow" then
		local d=D.Get(p,"Garden");for _,pl in d.plots do if not pl.mature then pl.progress=Seeds.ById[pl.id].grow end end
		G.Advance(p,now,true);D.Set(p,"Garden",d);G.Send(p)
	elseif key=="chestKey" then W.GrantChest(p,"Legendary",10,G.ShopZone(p),1,D.Get(p,"Meta.AdminTouched")==true)
	elseif key=="baseLock" then Steal.ForceLock(p)
	elseif key=="seasonPremium" then return Season.GrantPremium(p,now)
	else error("unknown product "..tostring(key)) end
end
function M.ProcessReceipt(info)
	local row=info.ProductId==C.SeasonPremium.id and C.SeasonPremium or C.ProductById[info.ProductId];local p=Players:GetPlayerByUserId(info.PlayerId)
	if not row or not p or not D.IsLoaded(p) then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local id=tostring(info.PurchaseId)
	if not D.Get(p,"Purchases.receipts")[id] then
		local ok,text=pcall(M.Grant,p,row.key)
		if not ok then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local now=os.time();local t=table.clone(D.Get(p,"Purchases.receipts"))
		for k,at in t do if at<now-C.ReceiptKeepSeconds then t[k]=nil end end
		t[id]=now;D.Set(p,"Purchases.receipts",t)
		Net.Event("Notify"):FireClient(p,{text=(text or "Received "..row.name.." done").." Thank you for your support!"})
	end
	-- Report success only once the receipt marker is in the saved copy (no double grants after a crash).
	local saved=D.SaveAndWait(p,function(data) return data and data.Purchases and data.Purchases.receipts and data.Purchases.receipts[id]~=nil end,30)
	return saved and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
end
function M.Prompt(p,key)
	if not F.IsEnabled("Shop") then return false,"Shop disabled" end
	local pass=C.PassByKey[key]
	if pass then
		if M.Owns(p,key) then return false,"Owned "..pass.name.." done" end
		MS:PromptGamePassPurchase(p,pass.id);return true,"Open purchase for "..pass.name
	end
	if key=="seasonPremium" then
		local ok,msg=Season.CanBuy(p);if not ok then return false,msg end
		Season.MarkPending(p);MS:PromptProductPurchase(p,C.SeasonPremium.id);return true,"Open purchase for "..C.SeasonPremium.name
	end
	local row=C.ProductByKey[key];if not row then return false,"Product not found" end
	local check=READY[key];if check then local ok,msg=check(p);if not ok then return false,msg end end
	MS:PromptProductPurchase(p,row.id);return true,"Open purchase for "..row.name
end
local function checkPasses(p)
	M.Refresh(p)
	for _,pass in C.Passes do task.spawn(function()
		local ok,owns=pcall(MS.UserOwnsGamePassAsync,MS,p.UserId,pass.id)
		if ok and owns and p.Parent and D.IsLoaded(p) and not M.Owns(p,pass.key) then M.SetPass(p,pass.key,true) end
	end) end
end
function M.Init()
	MS.ProcessReceipt=M.ProcessReceipt
	MS.PromptGamePassPurchaseFinished:Connect(function(p,id,bought)
		local pass=C.PassById[id]
		if bought and pass and D.IsLoaded(p) then M.SetPass(p,pass.key,true);Net.Event("Notify"):FireClient(p,{text="Game Pass received "..pass.name.." done!"}) end
	end)
	D.PlayerLoaded:Connect(checkPasses)
	Net.Function("ShopAction").OnServerInvoke=function(p,action,key)
		if not D.IsLoaded(p) then return false,"Loading data" end
		local now=os.clock();if now-(last[p] or -math.huge)<.5 then return false,"Please wait" end;last[p]=now
		if action=="Prompt" and type(key)=="string" then return M.Prompt(p,key) end
		if action=="Warp" then
			if not M.Owns(p,"Teleport") then return false,"Requires the Teleport Anywhere pass" end
			Net.Event("StoryShow"):FireClient(p,{kind="warp"});return true,"Choose Warp Destination"
		end
		return false,"Invalid command"
	end
	Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
end
function M.Start() for _,p in Players:GetPlayers() do if D.IsLoaded(p) then checkPasses(p) end end end
return M
