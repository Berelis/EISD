local name = dark.pipeline()
--chargement de la liste des prénom
name:lexicon("&prenom", "prenom.txt")
--détéction d'une personne sous forme de "prénom nom"
name:pattern("[&person &prenom [&nom &ADP? (/%u%l+/)+ ] ]")

local date = dark.pipeline()
--détéction de l'année comme une suite de quatre chiffre
date:pattern("[&annee (/%d%d%d%d/)]")
--liste des jours
date:pattern([[
	[&jour (/[Ll]undi$/ |
		/[Mm]ardi$/ |
		/[Mm]ercredi$/ |
		/[Jj]eudi$/ |
		/[Vv]endredi$/)
	]
]])
--liste des mois
date:pattern([[
	[&mois (/[Jj]anvier$/ |
		/[Ff][ée]vrier$/ |
		/[Mm]ars$/ |
		/[Aa]vril$/ |
		/[Mm]ai$/ |
		/[Jj]uin$/ |
		/[Jj]uillet$/ |
		/[Aa]o[ûu]t$/ |
		/[Ss]eptembre$/ |
		/[Oo]ctobre$/ |
		/[Nn]ovembre$/ |
		/[Dd][ée]cembre$/)
	]
]])
--date sous forme jj/mm/aaaa, jour mois, mois annéé ou jour mois année
date:pattern([[
	[&date ( [&jour /%d+/] /%// [&mois /%d+/] /%// &annee ) |
		( [&jour /%d+%a*/] &mois ) |
		( &mois &annee ) |
		( &jour? /%d+/ &mois &anne? )
	]
]])

--pattern pour né le
date:pattern("[&ne_le /né/ le &date]")

local politique = dark.pipeline()
--detection du parti politique
politique:pattern(
[[
	[&parti
		(/Union/ /Pour/ /la/ /Démocratie/ /Directe/) |
		(/rassemblement/ /de/ /la/ /gauche/ /anti%-libérale/) |
		(/rassemblement/ &ADP? &DET? &orientation) |
		(/Lutte/ /Ouvrière/) |
		(/CAP/ /21/) |
		(/UDF/) |
		(/UMP/) |
		(/RPR/) |
		(/FN/) |
		(/PS/) |
		(/Parti/ /Communiste/ /Français/ (/PCF/)? ) |
		(/PCF/) |
		(/[Ff]ront/ /[Nn]ational/ (/FN/)? ) |
		(/[Pp]arti/ /[Ss]ocialiste/ (/PS/)? ) |
		(/[Gg]énération/ /[Eée]cologie/) |
		(/[Aa]lternative/ /[Ll]ibérale/) |
		(/[Pp]arti/ /[Ff]édéraliste/) |
		(/[Ll]igue/ /[Cc]ommuniste/ /[Rr]évolutionnaire/)	
	]
]])
--détéction de l'orientation politique
politique:pattern(
[[
	[&orientation
		(/[Ss]yndica[list]?e/) |
		(/[Tt]rostskiste/) |
		(/[Ff]éminisme/) |
		(/[Gg]aulliste/) |
		(/[Ss]ocialiste/) |
		(/[Cc]ommuniste/) |
		(/[Aa]narchiste/) |
		(/[Ff]édéraliste/) |
		((/[Ee]xtrême/ )?/[Dd]roite/( (/[Rr]épublicaine/|/[Nn]ationaliste/))?) |
		((/[Ee]xtrême/ )?/[Gg]auche/( (/anti%-libérale/))?) |
		(/[Cc]entre/) |
		(/[Ll]ibéralisme/) |
		(/[Ee]cologiste/)
	]
]])


local mandat = dark.pipeline()
mandat:add(politique)
--détéction du mandat en incluant, si possible, le parti et la date
mandat:pattern([[
	[&mandat
		(	(/^[Pp]orte-parole$/) |
			(/^[Dd]éputé[e]?$/) |
			(/^[Mm]ilitant[e]?$/) |
			(/^[Ii]nvestiture$/) |
			(/^[Ss]ecrétaire$/) |
			(/^[Pp]remier/? /^[Mm]inistre$/) |
			(/^[Cc]o-/?/^[Dd]irect(rice|eur)$/) |
			((/^[Aa]djoint[e]?$/ /au/ )?/^[Mm]aire$/) |
			(/^[Cc]onsultant[e]?$/) |
			(/^[Cc]onseill(er|ère)$/ /[Mm]unicipal[e]?$/) |
			(/^[Pp]résident[e]?$/ )
		)
		(&ADP | &DET | /l'/)* (&parti | &ADJ | &NNC | &NNP)? ((&ADP | &DET | /l'/)* (&date | &annee))?
	]
]])


local main = dark.pipeline()
--détéction des mots de la langue française
main:model("model/postag-fr")

--ajout des pattern créés précédemments
main:add(name)
main:add(date)
main:add(mandat)
main:add(politique)

--affichage et colorisation uniquement des tag créés
local tag = {
 person = "green",
 prenom = "yellow",
 nom = "yellow",
 
 ne_le = "white",
 date = "blue",
 annee = "red",
 mois = "red",
 jour = "red",

 mandat = "magenta",
 orientation = "black",
 parti = "green"
}

for line in io.lines() do
	local seq = main(line:gsub("[/.\",;]", " %1 "):gsub("[']", "%1 "))
	--seq:dump()
	print(seq:tostring(tag))
end
