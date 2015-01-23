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
	[&frontalier ( /entouré/ | /bordé/ | /frontalier/ | (/frontière/ /commune/?))  (&CON? &cardinaux? (/avec/ | /par/)? &DET? &pays &cardinaux? &PCT?)+
	]
]])

position:pattern([[
	[&est_frontalier
		&pays .* &frontalier
	]
]])