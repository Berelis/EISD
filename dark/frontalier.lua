frontalier = dark.pipeline()

frontalier:pattern([[
	[&cardinaux &ADP? &DET? (
		/[Nn]ord/ |
		/[Ss]ud/ |
		/[Oo]uest/ |
		/[Ee]st/
		)
	]
]])

frontalier:pattern([[
	[&frontalier ( /limitrophe/ /de/ | /entouré/ | /bordé/ | /frontalier/ | (/frontière/ .?)) &PCT? (&CON? &ADV? &cardinaux? (/avec/ | /par/)? (&ADP | /d'/)? &DET? (&pays | (/[Ss]ahara/ | /[Mm]er/ . | /[Oo]céan/ .) (&NNP | &ADJ)? ) &cardinaux? &PCT?)+
	]
]])

--frontalier:pattern([[
--	[&est_frontalier
--		&pays .* &frontalier
--	]
--]])