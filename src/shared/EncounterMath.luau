local C=require(script.Parent.Config.WeatherEncounters)
local M={}
function M.Payout(share)
 if type(share)~="number" or share~=share or share==math.huge or share<C.MinShare then return {gems=0,dust=0} end
 share=math.clamp(share,0,1);return {gems=math.floor(C.WorldGems*share),dust=math.floor(C.WorldDust*share)}
end
return M
