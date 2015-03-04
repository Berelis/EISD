--récupération de la base de donnée actuelle
if io.open("bdd.lua","r") == nil then
	local f = io.open("bdd.lua","w")
	f:write("bdd = {}")
	f:close()
end

dofile("bdd.lua")

--Appel des fichiers extérieurs
require('frontalier')
require('capitale')
require('continent')
require('langue')
require('monnaie')
require('religion')
require('nombre')
require('population')
require('superficie')
require('regime')



local name = dark.pipeline()
--chargement de la liste des pays
name:lexicon("&pays", "pays.txt")

local main = dark.pipeline()
--détéction des mots de la langue française
main:model("model/postag-fr")

--ajout des pattern créés précédemments
main:add(continent)
main:add(nombre)
main:add(name)
main:add(frontalier)
main:add(capitale)
main:add(langue)
main:add(monnaie)
main:add(religion)
main:add(population)
main:add(superficie)
main:add(regime)

local tag = {
	pays = "blue",
	continent = "red",
	frontalier = "blue",
	est_frontalier = "yellow",
	monnaie = "black",
	zone_euro = "black",
	est_monnaie = "black",
	devises = "black",
	monnaie_complet = "blue",
	est_capitale = "blue",
	capitale = "yellow",
	langue_pays = "green",
	langue = "green",
	est_religion = "red",
	religion = "red",
	NUM = "white",
	population = "magenta",
	nb_population = "cyan",
	superficie_pays = "black",
	superficie = "yellow",
	--nombre = "yellow",
	nombre_complet = "yellow",
	est_regime = "green",
	regime_complet = "white",
	--ADP = "black",
	--DET = "cyan",
	regime = "cyan"

}

function table_contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

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

--Meme fonction que précedement mais renvoie un tableau au lieu de concatener les tokens
function get_tokensTab(seq, debut, fin)
	local tab = {}
	for i = debut, fin do
		tab[#tab + 1] = seq[i].token
	end
	return tab
end

function get_tagsTab(seq, tag)
	local res = {}
	for idx, pos in ipairs(seq[tag]) do
		res[#res + 1] = get_tokensTab(seq, pos[1], pos[2])
	end
	return res
end

function ConcatSousTab(tab, debut, fin)
	local res = {}
	for i=debut, fin,1 do
		res[#res+1] = tab[i]
	end
	return table.concat(res, " ")
end

function get_tokens2(seq, debut, fin, tagIn)
	local tab = {}
	for i = debut, fin do
		for j=1,#seq[i] do
			if seq[i][j].name == tagIn then
				tab[#tab + 1] = seq[i].token
			end
		end
	end
	return tab
end

function get_tags2(seq, tag, tagIn)
	local res = {}
	for idx, pos in ipairs(seq[tag]) do
		res[#res + 1] = get_tokens2(seq, pos[1], pos[2], tagIn)
	end
	return res
end

modele  = {
	langue = {},
	capitale = {},
	monnaie = "",
	religion ={},
	pays_frontalier = {},
	population = "",
	regime = "",
	continent = "",
	superficie = "",
}

local nomPays = nil

for line in io.lines() do
	--local seq = main(line:gsub("[/.\",;]", " %1 "):gsub("[']", "%1 "))
	local seq = main(line:lower():gsub("[/.\",;()]", " %1 "):gsub("[']", "%1 "))

	if nomPays == nil then
		nomPays = get_tags(seq, "&pays")[1]
		if nomPays ~= nil and bdd[nomPays] == nil then
			print("Pays " .. nomPays)
			bdd[nomPays] = modele
		end
	else
		--Extraction Pays Frontaliers
		local tmp = get_tags2(seq, "&frontalier", "&pays")
		if tmp[1] ~= nil then 
			bdd[nomPays].pays_frontalier = tmp[1]
		end
		--Exrtraction Continent
		tmp = get_tags(seq, "&continent")
		if tmp[1] ~= nil then 
			bdd[nomPays].continent = tmp[1]
		end
		--Extraction Capitale
		tmp = get_tags(seq,"&capitale");
		if tmp[1] ~= nil then
			print("Capitale : " .. serialize(tmp))
			for i=1,#tmp do
				if not table_contains(bdd[nomPays].capitale, tmp[i]) then
					bdd[nomPays].capitale[#bdd[nomPays].capitale + 1] = tmp[i]
				end
			end
		end


		--Extraction monnaie
		if bdd[nomPays].monnaie == "" then
			tmp = get_tags(seq, "&zone_euro")
			if tmp[1] ~= nil then
				bdd[nomPays].monnaie = "euro"
			else
				tmp = get_tags(seq, "&monnaie_complet")
				if tmp[1] ~= nil then
					bdd[nomPays].monnaie = tmp[1]
				else
					tmp = get_tagsTab(seq, "&est_monnaie")
					if tmp[1] ~= nil then
						local res = ConcatSousTab(tmp[1], #tmp[1] , #tmp[1])
						print(res)
						bdd[nomPays].monnaie = res
					end
				end
			end
		end

		--Extraction relgion
		--if bdd[nomPays].religion == "" then
			tmp = get_tags(seq, "&religion")
			if tmp[1] ~= nil then
				print("Religion : " .. serialize(tmp))
				for i=1,#tmp do
					if not table_contains(bdd[nomPays].religion, tmp[i]) then
						bdd[nomPays].religion[#bdd[nomPays].religion + 1] = tmp[i]
					end
				end
			end
				--bdd[nomPays].religion = tmp[1]
			--end
		--end

		--Extraction langue
		--if bdd[nomPays].langue == "" then
			tmp = get_tags(seq, "&langue")
			if tmp[1] ~= nil then
				for i=1,#tmp do
					if not table_contains(bdd[nomPays].langue, tmp[i]) then
						bdd[nomPays].langue[#bdd[nomPays].langue + 1] = tmp[i]
					end
				end
				--bdd[nomPays].langue = tmp[1]
			end
		--end

		--Extraction population
		tmp = get_tags(seq, "&nb_population")
		if tmp[1] ~= nil then
			bdd[nomPays].population = tmp[1]
		end


		--Extraction superficie
		tmp = get_tags(seq, "&superficie")
		if tmp[1] ~= nil then
			bdd[nomPays].superficie = tmp[1]
		end

		--Extraction régime
		if bdd[nomPays].regime == "" then
			tmp = get_tags(seq, "&regime")
			if tmp[1] ~= nil then
				bdd[nomPays].regime = tmp[1]
			end
		end

	end
	--seq:dump()
	print(seq:tostring(tag))
end

--print("affichage bdd")
--print(serialize(bdd))

f = io.open("bdd.lua","w"):write("bdd = " .. serialize(bdd))
f:flush()
f.close()

	
