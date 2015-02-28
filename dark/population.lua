population = dark.pipeline()


population:pattern(
[[
	[&puissanceDix (/millier[s]?/ | /million[s]?/)]
]])

population:pattern(
[[
	 [&NUM /0[0-9]+$/]
]])

population:pattern(
[[
	[&DET /d'$/]
]])

population:pattern(
[[
	[&nombre (/un/ | 
			  /deux/ | 
			  /trois/ | 
			  /quatre/ | 
			  /cinq/ | 
			  /six/ | 
			  /sept/ | 
			  /huit/ | 
			  /neuf/ | 
			  /dix/ | 
			  /onze/ | 
			  /douze/ | 
			  /treize/ | 
			  /quatorze/ |
			  /quinze/ |
			  /seize/ |
			  /vingt/ |
			  /trente/ |
			  /quarante/ |
			  /cinquante/ |
			  /soixante/

				)]
]])

population:pattern(
[[
	[&population [&nb_population  ( &NUM* | &nombre)  &puissanceDix? ] &DET? (/habitants/ | /personnes/)]
]])