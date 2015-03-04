dofile("bdd.lua")

--print(serialize(pays))

local main = dark.pipeline()

main:model("model/postag-fr")

local leur = dark.pipeline()
leur:pattern(
[[
  [&leur
	(/chacun[e]?/) |
	((/parmi/)( /eux/)?) |
	(/leur[s]?/)
  ]
]])

local base = dark.pipeline()
base:pattern(
[[
  [&base
    ((/base/)( /de/ /donne[e]?[s]?/)?) |
	(/system[e]?/) |
	(/pays/) |
	(/etat[s]?/)
  ]
]])

local fin = dark.pipeline()
fin:pattern(
[[
  [&fin
    (/?/)
  ]
]])

local jointure = dark.pipeline()
jointure:pattern(
[[
  [&jointure
    (/commun[e]?[s]?/) |
	(/similaire[s]?/) |
	(/semblable[s]?/) |
	(/identique[s]?/) |
	(/entre/)
  ]
]])

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
		(/continent/)
	]
]])

local continent_nom = dark.pipeline()

continent_nom:pattern(
[[
	[&continent_nom
		(/africain[s]?/) |
		(/afrique/) |
		(/europe/) |
		(/europeen[s]?/) |
		(/asie/) |
		(/asiatique[s]?/) |
		(/oceanie/) |
		(/oceanique[s]?/) |
		(/amerique/) |
		(/americain[e]?/) |
		(/articque[s]?/) |
		(/antarticque[s]?/)
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

--Fonction pour lower un fichier
--[[local file = io.open("pays2.txt", "r")
local stringfile = file:read("*all")
file:close()

stringfile = stringfile:lower()

file = io.open("pays.txt", "w")
file:write(stringfile)
file:close()--]]

pays:lexicon("&pays", "pays.txt")

local sujet_possible = {}

-- Ajoute les pipeline a main et le nom des token a la liste des sujets possibles si different de "" et nil
function add_pipeline(token,tstring)
	main:add(token)
	if tstring ~= "" and tstring ~= nil then
		sujet_possible[#sujet_possible + 1] = tstring
	end
end

add_pipeline(capitale,"capitale")
add_pipeline(population,"population")
add_pipeline(langue,"langue")
add_pipeline(monnaie,"monnaie")
add_pipeline(superficie,"superficie")
add_pipeline(pays,"")
add_pipeline(Q,"")
add_pipeline(QPluriel,"")
add_pipeline(QPerson,"")
add_pipeline(QLieu,"")
add_pipeline(QChiffre,"")
add_pipeline(religion,"religion")
add_pipeline(regime,"regime")
add_pipeline(continent,"continent")
add_pipeline(continent_nom,"")
add_pipeline(position,"position")
add_pipeline(pays_frontalier,"pays_frontalier")
add_pipeline(jointure,"")
add_pipeline(fin,"")
add_pipeline(base,"")
add_pipeline(leur,"")

--print(serialize(sujet_possible))

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
	continent_nom = "magenta",
	pays ="cyan",
	pays_frontalier = "cyan",
	jointure = "dark",
	Q = "dark",
	QPluriel = "dark",
	QPerson = "dark",
	QChiffre = "dark",
	QLieu = "dark",
	fin = "dark",
	base = "dark",
	leur = "dark"
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

-- Trouver la reponse adequat en fonction d'un sujet
function get_print_sujet(sujet,pluriel)

	local string_reponse = ""

	if sujet == "capitale" then
		if pluriel then
			string_reponse = string_reponse .. "Les capitales "
		else
			string_reponse = string_reponse .. "La capitale "
		end
	elseif sujet == "regime" then
		string_reponse = string_reponse .. "Le regime "
	elseif sujet == "population" then
		string_reponse = string_reponse .. "La population  "
	elseif sujet == "position" then
		if pluriel then
			string_reponse = string_reponse .. "Les positions "
		else
			string_reponse = string_reponse .. "La position "
		end
	elseif sujet == "langue" then
		if pluriel then
			string_reponse = string_reponse .. "Les langues "
		else
			string_reponse = string_reponse .. "La langue "
		end
	elseif sujet == "monnaie" then
		string_reponse = string_reponse .. "La monnaie "
	elseif sujet == "religion" then
		if pluriel then
			string_reponse = string_reponse .. "Les religions "
		else
			string_reponse = string_reponse .. "La religion "
		end
	elseif sujet == "superficie" then
		string_reponse = string_reponse .. "La superficie "
	elseif sujet == "continent" then
		string_reponse = string_reponse .. "Le continent "
	elseif sujet == "pays_frontalier" then
		if pluriel then
			string_reponse = string_reponse .. "Les pays frontaliers "
		else
			string_reponse = string_reponse .. "Le pays frontalier "
		end
	end	

	return string_reponse

end

-- Trouver la ou les reponses a un sujet et un context
function get_reponse(contexte,sujet,question)

	--Trouver la reponse
	if bdd[contexte] ~= nil and
	bdd[contexte][sujet] ~= nil then
		question.reponse[#question.reponse + 1] = bdd[contexte][sujet]

		-- Si Reponse vide reponse = "" ou reponse {}
		if #question.reponse[#question.reponse] == 0 then 
			print("Nous n'avons pas la reponse a cette question (" .. sujet .. " du pays nomme " .. contexte .. ").")
		-- Sinon
		else	
			-- Si la reponse n'est pas un tableau
			if question.reponse[#question.reponse][1] == nil then
				print(get_print_sujet(sujet,false) .. "du pays nomme " .. contexte .. " est " .. question.reponse[#question.reponse] .. ".")
			-- Si la reponse est un tableau de taille un
			elseif #question.reponse[#question.reponse] == 1 then
				print(get_print_sujet(sujet,false) .. "du pays nomme " .. contexte .. " est " .. question.reponse[#question.reponse][1] .. ".")
			-- Si la reponse est un tableau de taille > 1
			else
				local reponse_string = ""

				for j = 1, #question.reponse[#question.reponse] do
					if j ~= #question.reponse[#question.reponse] then 
						reponse_string = reponse_string .. question.reponse[#question.reponse][j] .. ", "					
					else
						reponse_string = reponse_string .. "et " .. question.reponse[#question.reponse][j] .. "."
					end
				end
				print(get_print_sujet(sujet,true) .. "du pays nomme " .. contexte .. " sont " .. reponse_string)
			end	
		end
	else
		print("Nous ne pouvons pas repondre a cette question ( Un des deux elements suivant n'est pas dans la base " .. sujet .. " ou " .. contexte .. ").")
	end
end

-- Retourne true si exist dans la table sinon false
function tableContains(table, key)
    return table[key] ~= nil
end


-- Trouver la ou les reponses communes entre des contextes pour un sujet
function get_reponse_jointure(contexte,sujet,question)

	local temp = {}

	--Trouver la reponse pour chaque pays, on recupere toutes les nouvelles reponses, et pour chaque pays qui l'a, on incremente de 1
	for i = 0, #contexte do
		if bdd[contexte[i]] ~= nil and bdd[contexte[i]][sujet] ~= nil then
			-- Si pas de reponse
			if #bdd[contexte[i]][sujet] == 0 then

			-- Si la reponse n'est pas sous forme de tableau et non nul
			elseif bdd[contexte[i]][sujet][1] == nil then
				if tableContains(temp, bdd[contexte[i]][sujet]) then 
					temp[bdd[contexte[i]][sujet]] = temp[bdd[contexte[i]][sujet]] + 1
				else
					temp[bdd[contexte[i]][sujet]] = 1
				end
			-- Si la reponse est sous forme d'un tableau et non nul
			else
				for j = 1, #bdd[contexte[i]][sujet] do
					if tableContains(temp, bdd[contexte[i]][sujet][j]) then 
						temp[bdd[contexte[i]][sujet][j]] = temp[bdd[contexte[i]][sujet][j]] + 1
					else
						temp[bdd[contexte[i]][sujet][j]] = 1
					end
				end
			end
		end
	end

	question.reponse[#question.reponse + 1] = temp

	local i = 0

	for k, v in pairs(temp) do
		if v ~= 1 then
			print((v / #contexte)*100 .. "% des pays selectionnes ont en commun " .. k)
			i = i + 1
		end
	end

	if i == 0 then
		print("Il n'y a pas de " .. sujet .. " commun entre les pays selectionnes")
	end
end

-- Trouver la reponse pour un sujet dans la base
function get_reponse_base(sujet,question)

	local res = {}
	for k, token in pairs(bdd) do
		if token ~= nil then
			for s, v in pairs(token) do
				if s == sujet then --and tableContains(resultat, s) == false then
					if(v ~= nil and v ~= "") then
						if(type(v) == "table") then
								for l, m in pairs(v) do
									if(m ~= nil and m ~= "") then
										res[#res + 1] = m
									end
								end
						else 
							res[#res + 1] = v
						end
					end
				end
			end
		end
	end
	res = remove_duplicate(res)
	question.reponse[#question.reponse + 1] = res	
	return res
end

-- supprime les doublons dans une table et renvoie le resultat
function remove_duplicate(t) 
	local hash = {}
	local res = {}
	for k,v in pairs(t) do
		if(not hash[v]) then
			res[#res+1] = v
			hash[v] = true
		end
	end
	return res
end

-- affiche les elements d'une table de hachage
function print_table(t) 
	print("---------------------------")
	for k,v in pairs(t) do
		print(v)
	end
	print("---------------------------")
end

----------------------------------------------------------------------------------------------------

local listequestions = {}
local questionnumber = 1
local answer = nil

while true do
	--Recuperer la reponse
	print("\nQuelle question voulez-vous nous poser (q pour quitter) ? Doit se terminer par ?, tout le reste sera supprime, sinon la question ne sera pas comprise.\n")
	local answer=io.read()

	if answer == "q" then
		break
	end

	local question = {
		texte = answer
	}

	answer = string.lower(answer)

	local seq = main(answer:lower():gsub("[/.\",;]", " %1 "):gsub("[']", "%1 "):gsub("?.*", "?"))

	--io.write("\n")

	--print(seq:tostring(tag))

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

	local fin = get_tags(seq, "&fin")

	question.contexte = {}
	question.sujet = {}
	question.reponse = {}

	if #fin == 0 and #tokentag >= 0 then
		print("La question n'est pas reconnu comme ayant une fin. Veuillez poser une question cette fois.")
	else

----------------------------------------------------------------------------------------------------

		--Determiner le type de reponse via Q

		--Nombre de question
		question.nb_question = get_question(seq, "&Q",false)
		--Si la question porte sur des personnes 
		question.person = get_question(seq, "&QPerson",true)
		--Si la question porte sur un lieu
		question.lieu = get_question(seq, "&QLieu",true)
		--Si la question porte sur des chiffres
		question.chiffre = get_question(seq, "&QChiffre",true)
		--Si la question attend plusieurs réponses
		question.pluriel = get_question(seq, "&QPluriel",true)
		--Si la question porte sur la base
		question.base = get_question(seq, "&base",true)
		--Si la question implique une jointure
		question.jointure = get_question(seq, "&jointure",true)
		--Si la question porte sur un nom de continent
		question.continent_nom = get_question(seq, "&continent_nom",true)
		--Si la question porte sur des element d'une liste de pays, par exemple la reponse a la question precedante
		question.listepays = get_question(seq, "&leur",true)

----------------------------------------------------------------------------------------------------

		--Trouver contexte question (les pays)
		local res = get_tags(seq, "&pays")

		if #res ~= 0 then
			-- Si la question porte sur un pays
			if #res == 1 then
				print("Votre question porte sur le pays suivant : " .. res[1])
				question.contexte[1] = res[1]
			-- Si la question porte sur plusieurs pays
			else
				print("Votre question porte sur les pays suivants : ")
				for K , V in pairs(res) do
					question.contexte[#question.contexte + 1] = V
					print("--> (" .. K .. ") ".. question.contexte[#question.contexte])
				end
			end
			-- Dans tous les cas elle ne porte pas sur la base
			question.base = false
		end

		if question.base then 
			-- Pas de jointure sur la base
			question.jointure = false
		end

----------------------------------------------------------------------------------------------------

		--Trouver sujet question


		--Trouver ce sur quoi porte la question

		for k, v in pairs(tokentag) do
			local V = v:gsub("&", "")
			for i = 1, #sujet_possible do
				if V == sujet_possible[i] then 
					--if V == "pays_frontalier" then
						--question.listepays = true
					--end
					question.sujet[#question.sujet + 1] = sujet_possible[i];
					break;
				end
			end
		end
		
		if #question.sujet ~= 0 then

			-- Si la question porte sur un sujet
			if #question.sujet == 1 then
				print("Le sujet de votre question est : " .. question.sujet[1])
			-- Si la question porte sur plusieurs sujets
			else
				print("Les sujets de votre question sont : ")
				for i = 1, #question.sujet do	
					print("--> (" .. i .. ") " .. question.sujet[i])
				end
			end
		end

----------------------------------------------------------------------------------------------------

		-- Question sans contexte, ni sujet, n'interroge pas la base
		if #question.contexte == 0 and #question.sujet == 0 and not question.base then
			print("Nous ne comprenons pas votre question, desole.")

		-- Question avec contexte mais sans sujet, on recupere le sujet d'avant si possible, sinon pas de question
		elseif (#question.contexte ~= 0 or question.base) and #question.sujet == 0 then
			-- Si la question d'avant n'est pas nul, qu'elle a au moins un sujet et que le contexte actuel n'est pas la base alors que la question d'avant demander une jointure
			if listequestions[questionnumber-1] ~= nil and
			#listequestions[questionnumber-1].sujet ~= 0 and 
			(not question.base or not listequestions[questionnumber-1].jointure)
			then
				-- Si elle en a un
				if #listequestions[questionnumber-1].sujet == 1 then
					print("Le sujet de votre question est le même que celui de la question précédante à savoir : " .. listequestions[questionnumber-1].sujet[1])
					question.sujet[1] = listequestions[questionnumber-1].sujet[1]
				-- Si elle en a plusieurs
				else
					print("Les sujets de votre question sont les mêmes que ceux de la question précédante, à savoir: ")
					for i = 1, #listequestions[questionnumber-1].sujet do	
						print("--> (" .. i .. ") " .. listequestions[questionnumber-1].sujet[i])
						question.sujet[i] = listequestions[questionnumber-1].sujet[i]
					end
				end

				--On transmet aussi ses informations pour personaliser la reponse
				question.nb_question = listequestions[questionnumber-1].nb_question
				question.person = listequestions[questionnumber-1].person
				question.lieu = listequestions[questionnumber-1].lieu
				question.chiffre = listequestions[questionnumber-1].chiffre
				question.pluriel = listequestions[questionnumber-1].pluriel
				question.jointure = listequestions[questionnumber-1].jointure
        
                if #listequestions[questionnumber-1].reponse == 1 and listequestions[questionnumber-1].listepays then
                    question.listepays = listequestions[questionnumber-1].listepays
                end

			-- Si elle n'a pas de sujet ou n'existe pas
			else
				-- On ne peut pas gerer ce cas
				if question.base and listequestions[questionnumber-1] ~= nil and listequestions[questionnumber-1].jointure then
					print("Votre question porte sur la base de donnees mais la question precedente regroupait des informations multiples. La base ne peut pas regrouper d'informations multiples sur elle même.")
				else
					print("Votre question ne porte sur aucun sujet present en base de donnees.")
				end
			end
		
		-- Question avec sujet mais sans contexte, on recupere le contexte d'avant si possible, sinon pas de question. Seulement si la question ne porte pas directement sur la base
		elseif not question.base and #question.contexte == 0 and #question.sujet ~= 0 then
			-- Si la question d'avant n'est pas nul, quel a au moins un contexte et quel n'utilisait pas la base alors que la question actuelle porte sur une jointure
			if listequestions[questionnumber-1] ~= nil and
			#listequestions[questionnumber-1].contexte ~= 0 and
			(not listequestions[questionnumber-1].base or not question.jointure) then
				if #listequestions[questionnumber-1].reponse == 1 and question.listepays then
					--On prend comme contexte les pays de la reponse de la question d'avant
					-- Si elle en a un
					if #listequestions[questionnumber-1].reponse[1] == 1 then
						print("Votre question concerne le pays qui etait la reponse de la question precedente : " .. listequestions[questionnumber-1].reponse[1][1])
						question.contexte = listequestions[questionnumber-1].reponse[1][1]
					-- Si elle en a plusieurs
					else
						print("Votre question concerne les pays qui etaient la reponse de la question precedente : ")
						question.contexte = {}
						for K , V in pairs(listequestions[questionnumber-1].reponse[1]) do
							question.contexte[#question.contexte + 1] = V
							print("--> (" .. K .. ") " .. question.contexte[#question.contexte])
						end
					end
				else
					-- Si elle en a un
					if #listequestions[questionnumber-1].contexte == 1 then
						print("Votre question concerne le meme pays que pour la question precedante : " .. listequestions[questionnumber-1].contexte[1])
						question.contexte = listequestions[questionnumber-1].contexte
					-- Si elle en a plusieurs
					else
						print("Votre question concerne les memes pays que pour la question precedante : ")
						question.contexte = {}
						for K , V in pairs(listequestions[questionnumber-1].contexte) do
							question.contexte[#question.contexte + 1] = V
							print("--> (" .. K .. ") " .. question.contexte[#question.contexte])
						end
					end
				end
			-- Si elle existe, n'a pas de sujet mais interroge la base
			elseif listequestions[questionnumber-1] ~= nil and listequestions[questionnumber-1].base then
				question.base = listequestions[questionnumber-1].base
			-- Si elle n'a pas de sujet, n'interroge pas la base ou n'existe pas
			else
				-- On ne peut pas gerer ce cas
				if listequestions[questionnumber-1] ~= nil and listequestions[questionnumber-1].base and question.jointure then
					print("Votre question precedente portait sur la base de donnees mais votre question actuel regroupe plusieurs informations. La base ne peut pas regrouper d'information sur elle même.")
				else
					print("Votre question ne porte sur aucun pays.")
				end
			end
		end

----------------------------------------------------------------------------------------------------

		-- Si on a pas de contexte  et ne porte pas sur la base ou n'a pas de sujet on demande une autre question
		if (not question.base and #question.contexte == 0) or #question.sujet == 0 then
			print("Veuillez poser une autre question.")

		-- Sinon on peut chercher une reponse
		else
			
			-- Si elle porte sur un ou des pays
			if #question.contexte ~= 0 then
				-- Si on attend pas de jointure
				if not question.jointure then
					for i = 1, #question.contexte do
						for j = 1, #question.sujet do
							get_reponse(question.contexte[i],question.sujet[j],question)
						end
					end
				-- sinon
				else
					if #question.contexte >= 2 then
						for i = 1, #question.sujet do
							get_reponse_jointure(question.contexte,question.sujet[i],question)
						end
					else
						print("On ne peut pas faire de jonction pour un seul pays. Veuillez poser une autre question.")
					end
				end
			
			-- Si elle porte sur la base (jointure est faut normalement)
			else
				for i = 1, #question.sujet do
					local resultat_base = get_reponse_base(question.sujet[i],question)
					-- On propose d'afficher les resultat
					if #resultat_base ~= 0 then
						print("Votre requete sur la base donnees concernant le sujet '" .. question.sujet[i] .. "' a renvoye " .. #resultat_base .. " resultats. \nSouhaitez vous les afficher ? (y = Oui; n = Non)")
						while true do
							local choice = io.read()
							if choice == "y" or choice == "Y" then
								print_table(resultat_base)
								break							
							end
							if choice == "n" or choice == "N" then 
								break
							end
						end
					else 
						print("Votre requete sur la base de donnees concernant le sujet '" .. question.sujet[i] .. "' n'a pas renvoye de resultat.")	
					end
				end
			end
		end
		
	end

	listequestions[#listequestions + 1] = question
	questionnumber = questionnumber + 1 
end

print("Voulez vous afficher l'historique de vos questions (sous forme d'un tableau) ? (y = Oui; n = Non)")
while true do
	local choice = io.read()
	if choice == "y" or choice == "Y" then
		print(serialize(listequestions))
		break							
	end
	if choice == "n" or choice == "N" then 
		break
	end
end

