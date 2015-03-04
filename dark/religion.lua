religion = dark.pipeline()

religion:pattern(
[[
	[&est_religion  &DET /religion/ /national/? &VRB &DET [&religion .]  ]
]])

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



