position = dark.pipeline()
position:pattern([[
	[&continent (
			/[Ee]urope/ |
			/[Aa]sie/ |
			/[Aa]frique/ |
			/[Oo]c[ée]anie/ |
			/[Aa]m[ée]rique/
			)
	]
]])

position:pattern([[
	[&frontalier ( /entouré/ | /bordé/) par (&CON? &DET? &pays &PCT?)+
	]
]])