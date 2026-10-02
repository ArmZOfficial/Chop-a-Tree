-- Actual source dimensions differ between images; uploaded dimensions are required.
local Atlas={}
Atlas.Data={
	window={size=Vector2.new(1586,992),sprites={
		wideWindow={31,42,1527,895},
	}},
	detail={size=Vector2.new(972,1619),sprites={
		detailPanel={35,42,902,1533},
	}},
	chrome={size=Vector2.new(1254,1254),sprites={
		navNormal={62,181,322,310},
		navGold={471,180,324,312},
		navGreen={878,175,326,317},
		tabNormal={28,666,390,107},
		tabGold={438,662,383,110},
		tabGreen={839,662,384,111},
		headerPlaque={25,918,430,156},
		infoRow={482,951,390,104},
		currencyCapsule={899,951,330,103},
	}},
	controls={size=Vector2.new(1254,1254),sprites={
		buttonGreen={19,246,403,181},
		buttonGold={435,245,383,182},
		buttonRed={833,245,401,182},
		buttonDisabled={20,567,405,182},
		close={518,548,216,217},
		delete={915,540,234,229},
		badgeReady={19,897,409,159},
		badgeClaimed={443,897,368,159},
		progressTrack={822,908,415,138},
	}},
	cards={size=Vector2.new(1254,1254),sprites={
		common={42,29,365,353},
		rare={443,29,368,353},
		epic={847,29,366,353},
		legendary={40,424,366,360},
		mythic={443,425,368,356},
		unknown={848,425,363,356},
		product={40,824,367,357},
		today={442,822,370,359},
		selected={847,821,368,360},
	}},
	incubation={size=Vector2.new(1536,1024),sprites={
		cradleEmpty={42,81,454,449},
		cradleGrowing={541,81,456,449},
		cradleReady={1041,81,455,449},
		eggGrowing={119,614,281,329},
		eggReady={629,618,278,321},
		nest={1040,717,451,216},
	}},
	garden={size=Vector2.new(1254,1254),sprites={
		plotEmpty={19,397,399,239},
		plotGrowing={436,307,388,330},
		plotReady={841,122,406,515},
		fruit={64,783,301,343},
		wateringCan={396,774,448,354},
		seedPouch={878,771,323,360},
	}},
	rewards={size=Vector2.new(1254,1254),sprites={
		gemsSmall={20,174,412,304},
		gemsMedium={433,139,386,344},
		gemsLarge={819,91,416,404},
		rareChest={49,539,368,304},
		epicChest={455,546,368,291},
		woodBoost={857,538,356,295},
		luckBoost={77,876,343,311},
		chestKey={483,869,324,323},
		gift={870,870,318,322},
	}},
	pets={size=Vector2.new(1254,1254),sprites={
		pet_bunny={35,119,357,484},
		pet_fox={409,131,443,472},
		pet_bee={873,215,353,362},
		pet_deer={25,668,357,508},
		pet_wolf={404,711,436,460},
		pet_drake={852,743,395,421},
	}},
	weapons={size=Vector2.new(1254,1254),sprites={
		wpn_bent_halberd={74,76,294,318},
		wpn_stone_chainsaw={490,112,292,271},
		wpn_stone_trident={935,108,236,289},
		wpn_old_guitar={68,482,278,310},
		wpn_stone_chakram={503,525,264,236},
		wpn_copper_grimoire={898,506,294,274},
		wpn_oak_longbow={66,845,313,278},
		wpn_old_pickaxe={511,871,286,273},
		wpn_rusty_orb={964,880,214,268},
	}},
}
function Atlas.Create(className,atlasName,spriteName,imageAssetId,textureSize,parent)
 assert(className=="ImageLabel" or className=="ImageButton","Use an image GUI class")
 assert(type(imageAssetId)=="number" and imageAssetId>0,"Provide an uploaded image ID")
 assert(textureSize.X>0 and textureSize.Y>0,"Provide uploaded texture dimensions")
 local atlas=assert(Atlas.Data[atlasName],"Unknown atlas")
 local r=assert(atlas.sprites[spriteName],"Unknown sprite")
 local sx,sy=textureSize.X/atlas.size.X,textureSize.Y/atlas.size.Y
 local x,y=math.floor(r[1]*sx),math.floor(r[2]*sy)
 local right,bottom=math.ceil((r[1]+r[3])*sx),math.ceil((r[2]+r[4])*sy)
 local gui=Instance.new(className)
 gui.Name=spriteName;gui.BackgroundTransparency=1
 gui.Image="rbxassetid://"..imageAssetId
 gui.ImageRectOffset=Vector2.new(x,y);gui.ImageRectSize=Vector2.new(right-x,bottom-y)
 gui.ScaleType=Enum.ScaleType.Fit;gui.Size=UDim2.fromOffset(r[3],r[4]);gui.Parent=parent
 return gui
end
return Atlas
