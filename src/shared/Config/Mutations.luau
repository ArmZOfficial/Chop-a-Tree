return table.freeze({
	Values={Wet=2,Shocked=15,Chilled=2,Frozen=10,Electrified=40,Golden=20},
	Colors={Wet=Color3.fromRGB(96,180,255),Shocked=Color3.fromRGB(200,120,255),Chilled=Color3.fromRGB(180,240,255),Frozen=Color3.fromRGB(135,220,255),Electrified=Color3.fromRGB(235,225,100),Golden=Color3.fromRGB(255,205,70)},
	Special={Golden=true},
	Combos={{"Wet","Chilled","Frozen"},{"Shocked","Wet","Electrified"}},
})
