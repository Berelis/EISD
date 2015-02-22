religion = dark.pipeline()

religion:pattern(
[[
	[&est_religion  &DET /religion/ /national/? &VRB &DET [&religion .]  ]
]])


--Règle pour match avec arabie saoudite (009)
religion:pattern(
[[
	[&est_religion /lieux/ /saints/ . .  [&religion .] ]
]])

religion:pattern(
[[
	[&est_religion &VRB /convertie/ &ADP &DET? [&religion .] ]
]])



religion:pattern(
[[
	[&religion (/catholi/ | /islam/ | /protestant/ | /juif/)]	
]])



