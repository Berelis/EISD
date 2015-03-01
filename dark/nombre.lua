nombre = dark.pipeline()

nombre:pattern(
[[
	[&puissanceDix (/millier[s]?/ | /million[s]?/)]
]])

nombre:pattern(
[[
	 [&NUM /[0-9]+$/]
]])

nombre:pattern(
[[
	[&nombre (/un$/ | 
			  /deux$/ | 
			  /trois$/ | 
			  /quatre$/ | 
			  /cinq$/ | 
			  /six$/ | 
			  /sept$/ | 
			  /huit$/ | 
			  /neuf$/ | 
			  /dix$/ | 
			  /onze$/ | 
			  /douze$/ | 
			  /treize$/ | 
			  /quatorze$/ |
			  /quinze$/ |
			  /seize$/ |
			  /vingt$/ |
			  /trente$/ |
			  /quarante$/ |
			  /cinquante$/ |
			  /soixante$/

				)]
]])

-- nombre:pattern(
-- [[
-- 	[&nombre_complet  ]
-- ]])

nombre:pattern(
[[
	[&nombre_complet ( &NUM /,/ &NUM | &NUM | &nombre)+  &puissanceDix?]
]])

