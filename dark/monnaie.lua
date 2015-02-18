monnaie = dark.pipeline()

monnaie:pattern(
[[
	[&monnaie
		(/monnaie[s]?/) |
		(/argent[s]?$/) |
		(/devise[s]?/) 
	]
]])

monnaie:pattern(
[[
	[&devises 
	(/dinar$/) | 
	(/livre$/) | 
	(/franc$/) | 
	(/dirham$/) |
 	(/ouguiya$/) | 
 	(/peseta$/) | 
 	(/dollar$/) | 
 	(/shilling$/) | 
 	(/roupie$/)| 
 	(/peso$/)  
 	]

]])

monnaie:pattern(
[[
	[&zone_euro /zone/ /euro/]
]])


monnaie:pattern(
[[
	[&monnaie_complet &devises /[^.,]+/]
]])

monnaie:pattern(
[[
	[&est_monnaie &DET &monnaie &VRB? &DET . &monnaie_complet]
]])

monnaie:pattern(
[[
	[&est_monnaie &DET &monnaie &VRB? &DET . /[^.,]+/? /[^.,]+/? ]
]])
