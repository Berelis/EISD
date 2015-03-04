continent = dark.pipeline()

continent:pattern([[
	[&continent (
			/^[Ee]urope$/ |
			/^[Aa]sie$/ |
			/^[Aa]frique$/ |
			/^[Oo]céanie$/ |
			(/^[Aa]mérique$/ (/du/ (/[Nn]ord/ | /[Ss]ud/))?)
			)
	]
]])