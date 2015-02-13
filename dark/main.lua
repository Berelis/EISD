require('position')
--récupération de la base de donnée actuelle
dofile("../bdd.lua")

local name = dark.pipeline()
--chargement de la liste des prénom
name:lexicon("&pays", "pays.txt")

local main = dark.pipeline()
--détéction des mots de la langue française
main:model("model/postag-fr")

--ajout des pattern créés précédemments
main:add(name)
main:add(position)

local tag = {
	pays = "green",
	continent = "red",
	frontalier = "blue",
	est_frontalier = "yellow"
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
	capitale = "",
	monnaie = "",
	religion ={},
	position = {},
	pays_frontalier = {},
	population = "",
	regime = "",
	continent = "",
	superficie = "",
}

local nomPays = nil

for line in io.lines() do
	local seq = main(line:gsub("[/.\",;]", " %1 "):gsub("[']", "%1 "))
	local seq = main(line:lower():gsub("[/.\",;]", " %1 "):gsub("[']", "%1 "))

	if nomPays == nil then
		nomPays = get_tags(seq, "&pays")[1]
		if nomPays ~= nil and bdd[nomPays] == nil then
			print("Pays " .. nomPays)
			bdd[nomPays] = modele
		end
	else
		local tmp = get_tags2(seq, "&frontalier", "&pays")
		if tmp[1] ~= nil then 
			bdd[nomPays].pays_frontalier = tmp[1]
		end
		tmp = get_tags(seq, "&continent")
		if tmp[1] ~= nil then 
			bdd[nomPays].continent = tmp[1]
		end
	end
	seq:dump()
	--print(seq:tostring(tag))
end

print("affichage bdd")
print(serialize(bdd))
if bdd["France"] == nil then
	print("Y a pas la France")
else
	print("Y a la France")
end
if bdd["Afghanistan"] == nil then
	print("Y a pas Afghanistan")
else
	print("Y a Afghanistan")
end
io.open("../bdd.lua","w"):write("bdd = " .. serialize(bdd))
