langue = dark.pipeline()

--langue:lexicon('&langue', 'langue.txt')

langue:pattern(
[[
	[&langue_pays /langue[s]?/ /officielle[s]?/? /nationale/?  &VRB &DET? [&langue  .] ]
]])

langue:pattern(
[[
	[&langue_pays /pays/ [&langue /.+phone/] ]
]])