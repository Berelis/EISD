capitale = dark.pipeline()

capitale:pattern([[
	[&est_capitale (/^capitale/ .? (/est/ | /devient/) [&capitale &DET? .])
	]
]])

capitale:pattern([[
	[&est_capitale (/^capitale/ &PCT [&capitale &DET? .])
	]
]])

capitale:pattern([[
	[&est_capitale (/^capitale/ [&capitale &DET? &NNP+])
	]
]])