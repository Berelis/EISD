langue = dark.pipeline()

--langue:lexicon('&langue', 'langue.txt')

langue:pattern(
[[
	[&langue_pays /langue[s]?/ /officielle[s]?/?  &VRB &DET? [&langue  .] ]
]])