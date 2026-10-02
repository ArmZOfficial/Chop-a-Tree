-- Base decoration catalogue (plan 9.2). Cosmetic only: no collision, no power. Bought with Wood; zone sets unlock when that zone's shrine is lit.
-- Festival pieces are sold only while their Config.Events festival runs, stay forever once placed, and also dress the village during it.
local V,C=Vector3.new,Color3.fromRGB
local M=Enum.Material
local list={
	{id="fence",name="Wood Fence",price=200,beauty=1,parts={{size=V(4,3,.6),offset=V(0,1.5,0),color=C(150,105,65),material=M.WoodPlanks}}},
	{id="path",name="Path Stones",price=150,beauty=1,parts={{size=V(3.8,.3,3.8),offset=V(0,.15,0),color=C(150,145,135),material=M.Slate}}},
	{id="bush",name="Round Bush",price=300,beauty=2,parts={{size=V(3.5,3.5,3.5),offset=V(0,1.6,0),color=C(70,140,70),material=M.Grass,shape=Enum.PartType.Ball}}},
	{id="lamp",name="Lamp Post",price=400,beauty=2,parts={{size=V(.5,5,.5),offset=V(0,2.5,0),color=C(60,60,70),material=M.Metal},{size=V(1.4,1.4,1.4),offset=V(0,5.4,0),color=C(255,220,140),material=M.Neon,shape=Enum.PartType.Ball,light=true}}},
	{id="bench",name="Bench",price=500,beauty=2,parts={{size=V(4,.4,1.6),offset=V(0,1.4,0),color=C(140,95,60),material=M.Wood},{size=V(.4,1.2,1.4),offset=V(-1.6,.6,0),color=C(90,60,40),material=M.Wood},{size=V(.4,1.2,1.4),offset=V(1.6,.6,0),color=C(90,60,40),material=M.Wood}}},
	{id="flowers",name="Flower Bed",price=350,beauty=2,parts={{size=V(3.6,.6,3.6),offset=V(0,.3,0),color=C(110,80,55),material=M.Ground},{size=V(3,.6,3),offset=V(0,.8,0),color=C(240,120,170),material=M.Grass}}},
	{id="maple",name="Mini Maple",zone=2,price=1500,beauty=4,parts={{size=V(.8,4,.8),offset=V(0,2,0),color=C(110,75,50),material=M.Wood},{size=V(4,4,4),offset=V(0,5,0),color=C(220,110,40),material=M.Grass,shape=Enum.PartType.Ball}}},
	{id="sakura",name="Mini Sakura",zone=4,price=3000,beauty=5,parts={{size=V(.8,4,.8),offset=V(0,2,0),color=C(100,70,60),material=M.Wood},{size=V(4.5,4.5,4.5),offset=V(0,5.2,0),color=C(250,180,210),material=M.Grass,shape=Enum.PartType.Ball}}},
	{id="icecrystal",name="Ice Crystal",zone=6,price=5000,beauty=6,parts={{size=V(1.6,5,1.6),offset=V(0,2.5,0),color=C(170,220,255),material=M.Ice},{size=V(1,3,1),offset=V(1,1.5,.4),color=C(200,235,255),material=M.Ice}}},
	{id="trophy",name="Guardian Trophy",zone=8,price=10000,beauty=10,parts={{size=V(2,1,2),offset=V(0,.5,0),color=C(70,60,50),material=M.Marble},{size=V(2.4,1.6,1.6),offset=V(0,2.2,0),color=C(255,200,60),material=M.Neon,shape=Enum.PartType.Cylinder}}},
	{id="pumpkin",name="Pumpkin Lantern",festival="halloween",price=800,beauty=3,parts={{size=V(3,2.6,3),offset=V(0,1.3,0),color=C(235,120,30),material=M.SmoothPlastic,shape=Enum.PartType.Ball},{size=V(.4,.8,.4),offset=V(0,2.8,0),color=C(70,110,40),material=M.Wood},{size=V(1.4,.6,.2),offset=V(0,1.5,-1.45),color=C(255,230,120),material=M.Neon,light=true}}},
	{id="krathong",name="Leaf Krathong",festival="loykrathong",price=800,beauty=3,parts={{size=V(3,.8,3),offset=V(0,.4,0),color=C(80,150,70),material=M.Grass,shape=Enum.PartType.Cylinder},{size=V(2,1,2),offset=V(0,1.2,0),color=C(250,200,220),material=M.SmoothPlastic,shape=Enum.PartType.Ball},{size=V(.2,1,.2),offset=V(0,2.2,0),color=C(255,220,140),material=M.Neon,light=true}}},
	{id="pine",name="Festive Pine",festival="winter",price=800,beauty=3,parts={{size=V(.8,1.6,.8),offset=V(0,.8,0),color=C(100,70,50),material=M.Wood},{size=V(4,4,4),offset=V(0,3,0),color=C(40,110,60),material=M.Grass,shape=Enum.PartType.Ball},{size=V(2.6,2.6,2.6),offset=V(0,5.4,0),color=C(50,130,70),material=M.Grass,shape=Enum.PartType.Ball},{size=V(.8,.8,.8),offset=V(0,7,0),color=C(255,230,90),material=M.Neon,shape=Enum.PartType.Ball,light=true}}},
	{id="watergun",name="Water Gun Stand",festival="songkran",price=800,beauty=3,parts={{size=V(3,2,2),offset=V(0,1,0),color=C(60,150,220),material=M.SmoothPlastic},{size=V(2.4,.6,.6),offset=V(0,2.3,0),color=C(250,200,60),material=M.SmoothPlastic},{size=V(.6,.6,1.6),offset=V(1,2.3,0),color=C(240,90,90),material=M.SmoothPlastic}}},
}
local byId={};for _,d in list do byId[d.id]=d end
return table.freeze({List=list,ById=byId,Grid=4,MaxItems=40,Refund=.5,VillagePieces=8,VillageRadius=34,LikeRange=40})
