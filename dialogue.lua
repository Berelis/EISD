dofile("../bdd.lua")

--print(serialize(pays))

local main = dark.pipeline()

main:model("model/postag-fr")

local Q = dark.pipeline()
Q:pattern(
[[
  [&Q
    (/lequel/) |
	(/quel/) |
	(/quelle/) |
	(/laquelle/) |
	(/comment/) |
	(/lesquels/) |
	(/quels/) |
	(/lesquelles/) |
	(/quelles/) |
	(/qui/) |
	(/o[uù]/) |
	(/combien/)
  ]
]])

local QPluriel = dark.pipeline()
QPluriel:pattern(
[[
  [&QPluriel
	(/comment/) |
	(/lesquels/) |
	(/quels/) |
	(/lesquelles/) |
	(/quelles/)
  ]
]])

local QPerson = dark.pipeline()
QPerson:pattern(
[[
  [&QPerson
     (/qui/)
  ]
]])

local QLieu = dark.pipeline()
QLieu:pattern(
[[
  [&QLieu
     (/o[uù]/)
  ]
]])

local QChiffre = dark.pipeline()
QChiffre:pattern(
[[
  [&QChiffre
     (/combien/)
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
		(/parle/) |
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
main:add(QPluriel)
main:add(QPerson)
main:add(QLieu)
main:add(QChiffre)
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
	Q = "dark",
	QPluriel = "dark",
	QPerson = "dark",
	QChiffre = "dark",
	QLieu = "dark"
}

--Donne les tokens de seq entre de debut et fin
function get_tokens(seq, debut, fin)
	local tab = {}

	for i = debut, fin do
		tab[#tab + 1] = seq[i].token
	end

	return table.concat(tab, " ")
end

--Donne les tag de seq
function get_tags(seq, tag)
	local res = {}

	for idx, pos in ipairs(seq[tag]) do
		res[#res + 1] = get_tokens(seq, pos[1], pos[2])
	end

	return res
end

-- Si para == true, indique si on a le tag tag dans seq
-- Sinon on renvoit le nb de tag tag dans seq
function get_question(seq, tag, para)
	local res = get_tags(seq, tag)

	if para == true then
		if res[1] ~= nil then
			res = true
		else
			res = false
		end
	else
		if res[1] ~= nil then
			res = #res
		else
			res = 0
		end
	end

	return res
end

-- Trouver la reponse a un sujet et un context
function get_reponse(i,question)
	print(serialize(question.sujet))
	print(i)

	question.reponse[i] = {}

	--Trouver la reponse
	if bdd[question.contexte] ~= nil and
	bdd[question.contexte][question.sujet[i]] ~= nil then
		question.reponse[#question.reponse + 1] = bdd[question.contexte][question.sujet[i]]

		-- Si Reponse vide
		if #question.reponse[i][1] ~= nil and #question.reponse[i] == 0 then
			print("Nous n'avons pas la reponse a cette question.")
		-- Sinon
		else			
			if #question.reponse[i] == 1 then
				print("La reponse a votre question est : " .. question.reponse[i][1])
			else
				print("Les reponses a votre question sont :")
				for j = 1, #question.reponse[i] do
					print(question.reponse[i][j])
				end
			end	
		end
	else
		print("Nous ne gerons pas encore cette question.")
	end
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
		-- Si la question porte sur un pays
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

	--Nombre de question
	local nb_question = get_question(seq, "&Q",false)
	--Si la question porte sur des personnes 
	local person = get_question(seq, "&QPerson",true)
	--Si la question porte sur un lieu
	local lieu = get_question(seq, "&QLieu",true)
	--Si la question porte sur des chiffres
	local chiffre = get_question(seq, "&QChiffre",true)
	--Si la question attend plusieurs réponses
	local pluriel = get_question(seq, "&QPluriel",true)

----------------------------------------------------------------------------------------------------
	
	if question.contexte ~= nil then

		--Trouver ce sur quoi porte la question
		question.sujet = {}

		for k, v in pairs(tokentag) do
			for K , V in pairs(bdd[question.contexte]) do
				if (v:gsub("&", "") == K) then
					question.sujet[#question.sujet + 1] = K;
					break;
				end
			end
		end

		print(serialize(question.sujet))

		if question.sujet[1] ~= nil then
			if #question.sujet == 1 then
				print("Le sujet de votre question est : " .. question.sujet[1])
			else
				print("Les sujets de votre question sont : ")
				for i = 1, #question.sujet do	
					print("-->" .. question.sujet[i])
				end
			end
		elseif listequestions[questionnumber-1] ~= nil and
		listequestions[questionnumber-1].sujet[1] ~= nil then
			if #listequestions[questionnumber-1].sujet == 1 then
				print("Le sujet de votre question est le même que celui de la question précédante : " .. listequestions[questionnumber-1].sujet[1])
			else
				print("Les sujets de votre question sont les mêmes que ceux de la question précédante: ")
				for i = 1, #listequestions[questionnumber-1].sujet do	
					print("-->" .. listequestions[questionnumber-1].sujet[i])
				end
			end
		else
			print("Votre question ne porte sur rien")
			question.sujet = nil
		end

		--[[
		for k, v in pairs(tokentag) do
			for K , V in pairs(bdd[question.contexte]) do
				if (v:gsub("&", "") == K) then
					question.sujet = K;
					break;
				end
			end
		end

		if question.sujet ~= nil then
			print("Le sujet de votre question est : " .. question.sujet)
		elseif listequestions[questionnumber-1] ~= nil and
		listequestions[questionnumber-1].sujet ~= nil then
			print("Votre question a pour sujet celui de la question precedante : " .. listequestions[questionnumber-1].sujet)
			question.sujet = listequestions[questionnumber-1].sujet
		else
			print("Votre question ne porte sur rien")
			question.sujet = nil
		end

		--]]

----------------------------------------------------------------------------------------------------

		if question.sujet[1] ~= nil then

			question.reponse = {}
			
			--Un sujet dans la question
			if #question.sujet == 1 then
				get_reponse(1,question)
			--Plusieurs sujets dans la question
			else
				for i = 1, #question.sujet do
					get_reponse(i,question)
				end
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
