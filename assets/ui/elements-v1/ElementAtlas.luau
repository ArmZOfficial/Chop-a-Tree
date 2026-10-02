-- Source atlases are 1254 square; pass actual uploaded texture dimensions.
local Atlas={}
Atlas.Rects={
	frames={
		windowWide={36,116,552,310},
		windowTall={609,53,250,380},
		menuTile={914,114,306,308},
		cardCommon={61,483,345,337},
		cardRare={461,482,340,338},
		cardEpic={865,482,335,338},
		cardLegendary={60,840,347,339},
		cardMythic={461,840,340,339},
		woodInset={817,930,414,161},
	},
	controls={
		buttonGreen={7,211,413,174},
		buttonRed={420,212,412,173},
		buttonGold={834,212,410,172},
		buttonBlue={7,530,426,171},
		buttonWood={453,529,460,176},
		close={950,483,261,249},
		add={69,810,273,268},
		lock={427,809,270,269},
		progressTrack={751,886,482,132},
	},
	systems={
		chest={40,81,344,281},
		incubator={466,59,327,325},
		pet={870,81,340,302},
		gardenPlot={45,458,350,335},
		wateringCan={464,487,350,276},
		seedPouch={867,481,341,297},
		seasonTicket={49,900,358,254},
		shrine={443,842,369,324},
		merchant={866,857,365,306},
	},
	resources={
		coins={25,82,397,294},
		wood={436,66,387,310},
		gems={835,90,397,297},
		arenaToken={49,446,332,318},
		questBook={422,468,435,284},
		trophy={864,453,359,320},
		shield={42,821,356,346},
		clock={451,798,358,373},
		emptyPlot={823,853,420,316},
	},
}
function Atlas.Create(className,atlasName,spriteName,imageAssetId,textureSize,parent)
 assert(className=="ImageLabel" or className=="ImageButton","Use an image GUI class")
 assert(type(imageAssetId)=="number" and imageAssetId>0,"Provide the uploaded image asset ID")
 assert(textureSize.X>0 and textureSize.Y>0,"Provide uploaded texture dimensions")
 local group=assert(Atlas.Rects[atlasName],"Unknown atlas")
 local r=assert(group[spriteName],"Unknown sprite")
 local sx,sy=textureSize.X/1254,textureSize.Y/1254
 local x,y=math.floor(r[1]*sx),math.floor(r[2]*sy)
 local right,bottom=math.ceil((r[1]+r[3])*sx),math.ceil((r[2]+r[4])*sy)
 local gui=Instance.new(className)
 gui.Name=spriteName;gui.BackgroundTransparency=1;gui.Image="rbxassetid://"..imageAssetId
 gui.ImageRectOffset=Vector2.new(x,y);gui.ImageRectSize=Vector2.new(right-x,bottom-y)
 gui.ScaleType=Enum.ScaleType.Fit;gui.Size=UDim2.fromOffset(r[3],r[4]);gui.Parent=parent
 return gui
end
return Atlas
