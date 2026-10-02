return table.freeze({
 Topic="ChopWeatherLive_v1",Store="ChopWeatherLive_v1",TTL=3600,PollSeconds=30,StartDelay=5,
 MaxSteps=6,MinSeconds=10,MaxSeconds=600,MaxTotal=1800,
 Message="ArmZ Live Event • Rare weather streak!",
 Sequence={{id="Sakura",seconds=120},{id="Golden",seconds=120},{id="Aurora",seconds=120}},
})
