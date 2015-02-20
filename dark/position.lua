position = dark.pipeline()
position:pattern([[
	[&continent (
			/^[Ee]urope$/ |
			/^[Aa]sie$/ |
			/^[Aa]frique$/ |
			/^[Oo]céanie$/ |
			(/^[Aa]mérique$/ (/du/ (/[Nn]ord/ | /[Ss]ud/))?)
			)
	]
]])
-- (du (/[Nn]ord/|/[Ss]ud/))?)
position:pattern([[
	[&cardinaux &ADP? &DET? (
		/[Nn]ord/ |
		/[Ss]ud/ |
		/[Oo]uest/ |
		/[Ee]st/
		)
	]
]])

position:pattern([[
	[&frontalier ( /limitrophe/ /de/ | /entouré/ | /bordé/ | /frontalier/ | (/frontière/ .?)) &PCT? (&CON? &ADV? &cardinaux? (/avec/ | /par/)? (&ADP | /d'/)? &DET? (&pays | (/[Ss]ahara/ | /[Mm]er/ . | /[Oo]céan/ .) (&NNP | &ADJ)? ) &cardinaux? &PCT?)+
	]
]])

position:pattern([[
	[&est_capitale (/^capitale/ .? (/est/ | /devient/) [&capitale &DET? .])
	]
]])

position:pattern([[
	[&est_capitale (/^capitale/ &PCT [&capitale &DET? .])
	]
]])

position:pattern([[
	[&est_capitale (/^capitale/ [&capitale &DET? &NNP+])
	]
]])

--position:pattern([[
--	[&est_frontalier
--		&pays .* &frontalier
--	]
--]])