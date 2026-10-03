-- Client Play audit of every visible list: padding, clipping, scrollbar lane, first grid row fits. Reports only failures.
local pg=game.Players.LocalPlayer.PlayerGui
local failures,checked={},0
local function shown(o)
 local p=o
 while p and p~=pg do
  if p:IsA("GuiObject") and not p.Visible then return false end
  if p:IsA("ScreenGui") and not p.Enabled then return false end
  p=p.Parent
 end
 return true
end
for _,scroll in pg:GetDescendants() do
 local sg=scroll:FindFirstAncestorWhichIsA("ScreenGui")
 if scroll:IsA("ScrollingFrame") and sg and sg.Name~="AdminPanel" and sg.Name~="ToolHotbar" and shown(scroll) then
  checked+=1
  local path=scroll:GetFullName()
  local function fail(reason) table.insert(failures,path..": "..reason) end
  -- ScrollEdges no longer draws colour fades (2026-10-03): a leftover overlay means an old UIKit.
  if scroll.Parent:FindFirstChild(scroll.Name.."Edges") then fail("stale edge overlay") end
  local pad=scroll:FindFirstChildOfClass("UIPadding")
  if not pad or pad.PaddingTop.Offset<8 or pad.PaddingBottom.Offset<8 then fail("outline padding") else
   if not scroll.ClipsDescendants then fail("not clipped") end
   if scroll.VerticalScrollBarInset~=Enum.ScrollBarInset.ScrollBar then fail("scrollbar overlaps cards") end
   -- A single complete grid cell must fit at the start; scrolling ancestors are otherwise allowed to clip.
   local grid=scroll:FindFirstChildOfClass("UIGridLayout")
   if grid then
    local scale=scroll.AbsoluteSize.Y/scroll.Size.Y.Offset
    local panel=scroll:FindFirstAncestor("Panel");local uiScale=panel and panel:FindFirstChildOfClass("UIScale")
    scale=uiScale and uiScale.Scale or 1
    if grid.CellSize.Y.Offset*scale+(pad.PaddingTop.Offset+pad.PaddingBottom.Offset)*scale>scroll.AbsoluteWindowSize.Y+1 then fail("first grid row taller than window") end
   end
  end
 end
end
return "Scrolls "..checked.." | failures "..#failures.."\n"..table.concat(failures,"\n")
