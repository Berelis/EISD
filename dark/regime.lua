regime = dark.pipeline()


regime:pattern(
[[
	[&est_regime &DET /régime/ /politique/ &VRB? &ADP /type/  [&regime .*?] &PCT ]
]])

regime:pattern(
[[
	[&est_regime &DET /régime/ &VRB? &ADP?  [&regime .*?] &PCT ]
]])

