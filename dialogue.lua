dofile("../bdd.lua")

--print(serialize(pays))

local main = dark.pipeline()

main:model("model/postag-fr")

local Q = dark.pipeline()
Q:pattern(
[[
  [&Q
     (/qui/) |
     (/quoi/) |
     (/combien/) |
     ((/l[ea]/)?/quel[le]?[s]?/) |
     (/ou/)     
  ]
]])

local capitale = dark.pipeline()

capitale:pattern(
[[
	[&capitale
		(/capital[e]?/) |
		(/ville/ /principale/)
	]
]])

local population = dark.pipeline()

population:pattern(
[[
	[&population
		(/population[s]?/) |
		((/nombre/ )?(
			(/d'/)|(/de/ )
		)?(
			(/habitant[s]?/) |
			(/personne[s]?/) |
			(/resident[s]?/)
		))
	]
]])

local langue = dark.pipeline()

langue:pattern(
[[
	[&langue
		(/langue[s]?/) |
		(/dialecte[s]?/) |
		(/langage[s]?/)
	]
]])

local monnaie = dark.pipeline()

monnaie:pattern(
[[
	[&monnaie
		(/monnaie[s]?/) |
		(/argent[s]?/) |
		(/devise[s]?/)
	]
]])

local superficie = dark.pipeline()

superficie:pattern(
[[
	[&superficie
		(/superficie/) |
		(/taille/) |
		(/aire/) |
		(/surface/) |
		(/espace/) |
		((/nombre/ /de/ )?(/kilo/)?/metre[s]?/( /carre[s]?/)?)
	]
]])

local religion = dark.pipeline()

religion:pattern(
[[
	[&religion
		(/religion/) |
		(/culte/) |
		(/croyance[s]?/) |
		(/dogme[s]?/) |
		(/confession/) |
		(/superstition/) |
		(/foi/)
	]
]])

local continent = dark.pipeline()

continent:pattern(
[[
	[&continent
		(/continent/) |
		(/africain/) |
		(/afrique/) |
		(/europe/) |
		(/europeen/) |
		(/asie/) |
		(/asiatique/) |
		(/oceanie/) |
		(/oceanique/) |
		(/amerique/) |
		(/americain[e]?/) |
		(/articque/) |
		(/antarticque/)
	]
]])

local position = dark.pipeline()

position:pattern(
[[
	[&position
		(/position/) |
		(/[geo]?localisation/)
	]
]])

local pays_frontalier = dark.pipeline()

pays_frontalier:pattern(
[[
	[&pays_frontalier
		(/pays/ /frontalier[s]?/) |
		(/voisin[s]?/)
	]
]])

local pays = dark.pipeline()
pays:lexicon("&pays", "pays.txt")

main:add(capitale)
main:add(population)
main:add(langue)
main:add(monnaie)
main:add(superficie)
main:add(pays)
main:add(Q)
main:add(religion)
main:add(regime)
main:add(continent)
main:add(position)
main:add(pays_frontalier)

local tag = {
	capitale = "blue",
	regime = "blue",
	population = "red",
	position = "red",
	langue = "green",
	monnaie = "yellow",
	religion = "yellow",
	superficie = "magenta",
	continent = "magenta",
	pays ="cyan",
	pays_frontalier = "cyan",
	Q = "dark"
}

function get_tokens(seq, debut, fin)
	local tab = {}

	for i = debut, fin do
		tab[#tab + 1] = seq[i].token
	end

	return table.concat(tab, " ")
end

function get_tags(seq, tag)
	local res = {}

	for idx, pos in ipairs(seq[tag]) do
		res[#res + 1] = get_tokens(seq, pos[1], pos[2])
	end

	return res
end

local listequestions = {}
local questionnumber = 1
local answer = nil

repeat
	--Recuperer la reponse
	print("\nQuelle question voulez-vous nous poser (q pour quitter) ?\n")
	local answer=io.read()

	local question = {
		texte = answer
	}

	answer = string.lower(answer)

	local seq = main(answer)

	io.write("\n")

	print(seq:tostring(tag))

	local tokentag = {}

	for i = 1, #seq do
		
		--print(seq[i].token)

		if #seq[i] >= 2 then
			for j = 1, #seq[i] - 1 do
				--print(seq[i][j+1].name)
				tokentag[seq[i].token] = seq[i][j+1].name
			end
		end
	end

	print(serialize(tokentag))

----------------------------------------------------------------------------------------------------

	--Trouver sujet question
	local res = get_tags(seq, "&pays")

	if res[1] ~= nil then
		print("Le contexte de votre question est : " .. res[1])
		question.contexte = res[1]
	elseif listequestions[questionnumber-1] ~= nil and
	listequestions[questionnumber-1].contexte ~= nil then
		print("Votre question a pour contexte celui de la question precedante : " .. listequestions[questionnumber-1].contexte)
		question.contexte = listequestions[questionnumber-1].contexte
	else
		print("Votre question n'a pas de contexte")
		question.contexte = nil
	end

----------------------------------------------------------------------------------------------------

	--Determiner le type de reponse via Q

----------------------------------------------------------------------------------------------------
	
	if question.contexte ~= nil then

		--Trouver ce sur quoi porte la question
		for k, v in pairs(tokentag) do
			for K , V in pairs(bdd[question.contexte]) do
				if (v:gsub("&", "") == K) then
					question.sujet = K;
					break;
				end
			end
		end

		if question.sujet ~= nil then
			print("Le champs de votre question est : " .. question.sujet)
		elseif listequestions[questionnumber-1] ~= nil and
		listequestions[questionnumber-1].sujet ~= nil then
			print("Votre question a pour sujet celui de la question precedante : " .. listequestions[questionnumber-1].sujet)
			question.sujet = listequestions[questionnumber-1].sujet
		else
			print("Votre question ne porte sur rien")
			question.sujet = nil
		end

----------------------------------------------------------------------------------------------------

		if question.sujet ~= nil then

			--Trouver la reponse
			if bdd[question.contexte] ~= nil and
			bdd[question.contexte][question.sujet] ~= nil then
				question.reponse = bdd[question.contexte][question.sujet]
				print("La reponse a votre question est : " .. question.reponse)
			else
				print("Nous n'avons pas la reponse ou nous ne la gerons pas encore")
			end

		end

	end


	listequestions[#listequestions + 1] = question
	questionnumber = questionnumber + 1 
until answer == "q"

print("\n\nHistorique question :")
for i = 1, #listequestions do
	print(listequestions[i].texte)
end
