-- Base decoration catalogue (plan 9.2). Cosmetic only: no collision, no power. Bought with Wood; zone sets unlock when that zone's shrine is lit.
local V,C=Vector3.new,Color3.fromRGB
local M=Enum.Material
local list={
	{id="fence",name="รั้วไม้",price=200,beauty=1,parts={{size=V(4,3,.6),offset=V(0,1.5,0),color=C(150,105,65),material=M.WoodPlanks}}},
	{id="path",name="หินทางเดิน",price=150,beauty=1,parts={{size=V(3.8,.3,3.8),offset=V(0,.15,0),color=C(150,145,135),material=M.Slate}}},
	{id="bush",name="พุ่มไม้กลม",price=300,beauty=2,parts={{size=V(3.5,3.5,3.5),offset=V(0,1.6,0),color=C(70,140,70),material=M.Grass,shape=Enum.PartType.Ball}}},
	{id="lamp",name="โคมไฟเสา",price=400,beauty=2,parts={{size=V(.5,5,.5),offset=V(0,2.5,0),color=C(60,60,70),material=M.Metal},{size=V(1.4,1.4,1.4),offset=V(0,5.4,0),color=C(255,220,140),material=M.Neon,shape=Enum.PartType.Ball,light=true}}},
	{id="bench",name="ม้านั่ง",price=500,beauty=2,parts={{size=V(4,.4,1.6),offset=V(0,1.4,0),color=C(140,95,60),material=M.Wood},{size=V(.4,1.2,1.4),offset=V(-1.6,.6,0),color=C(90,60,40),material=M.Wood},{size=V(.4,1.2,1.4),offset=V(1.6,.6,0),color=C(90,60,40),material=M.Wood}}},
	{id="flowers",name="แปลงดอกไม้",price=350,beauty=2,parts={{size=V(3.6,.6,3.6),offset=V(0,.3,0),color=C(110,80,55),material=M.Ground},{size=V(3,.6,3),offset=V(0,.8,0),color=C(240,120,170),material=M.Grass}}},
	{id="maple",name="เมเปิลจิ๋ว",zone=2,price=1500,beauty=4,parts={{size=V(.8,4,.8),offset=V(0,2,0),color=C(110,75,50),material=M.Wood},{size=V(4,4,4),offset=V(0,5,0),color=C(220,110,40),material=M.Grass,shape=Enum.PartType.Ball}}},
	{id="sakura",name="ซากุระจิ๋ว",zone=4,price=3000,beauty=5,parts={{size=V(.8,4,.8),offset=V(0,2,0),color=C(100,70,60),material=M.Wood},{size=V(4.5,4.5,4.5),offset=V(0,5.2,0),color=C(250,180,210),material=M.Grass,shape=Enum.PartType.Ball}}},
	{id="icecrystal",name="คริสตัลน้ำแข็ง",zone=6,price=5000,beauty=6,parts={{size=V(1.6,5,1.6),offset=V(0,2.5,0),color=C(170,220,255),material=M.Ice},{size=V(1,3,1),offset=V(1,1.5,.4),color=C(200,235,255),material=M.Ice}}},
	{id="trophy",name="ถ้วยรางวัลผู้พิทักษ์",zone=8,price=10000,beauty=10,parts={{size=V(2,1,2),offset=V(0,.5,0),color=C(70,60,50),material=M.Marble},{size=V(2.4,1.6,1.6),offset=V(0,2.2,0),color=C(255,200,60),material=M.Neon,shape=Enum.PartType.Cylinder}}},
}
local byId={};for _,d in list do byId[d.id]=d end
return table.freeze({List=list,ById=byId,Grid=4,MaxItems=40,Refund=.5})
