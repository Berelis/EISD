langue = dark.pipeline()

langue:pattern(
[[
	[&langue_pays /langue[s]?/ /officielle[s]?/? /nationale/?  &VRB &DET? [&langue  .] ]
]])

langue:pattern(
[[
	[&langue_pays /pays/ [&langue /.+phone/] ]
]])