return table.freeze({
	Values={Wet=2,Shocked=15,Chilled=2,Frozen=10,Electrified=40,Golden=20,Misty=3,Windswept=3,Blossom=8,Celestial=80,Aurora=40,Bloodlit=30,Rainbow=50,Rotten=25,Cosmic=150},
	Colors={Wet=Color3.fromRGB(96,180,255),Shocked=Color3.fromRGB(200,120,255),Chilled=Color3.fromRGB(180,240,255),Frozen=Color3.fromRGB(135,220,255),Electrified=Color3.fromRGB(235,225,100),Golden=Color3.fromRGB(255,205,70)},
	Special={Golden=true,Rainbow=true},
	-- New mutation colors; original colors above remain unchanged.
	ExtraColors={Misty=Color3.fromRGB(190,200,215),Windswept=Color3.fromRGB(130,215,150),Blossom=Color3.fromRGB(255,145,195),Celestial=Color3.fromRGB(160,160,255),Aurora=Color3.fromRGB(100,255,200),Bloodlit=Color3.fromRGB(215,50,70),Rainbow=Color3.fromRGB(240,140,255),Rotten=Color3.fromRGB(105,75,130),Cosmic=Color3.fromRGB(210,130,255)},
	Combos={{"Wet","Chilled","Frozen"},{"Shocked","Wet","Electrified"},{"Celestial","Aurora","Cosmic"}},
})
