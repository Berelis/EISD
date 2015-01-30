require('position')

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

bdd = {}


modele  = {
		langue = {},
		monnaie = "",
		religion ={},
		position = {},
		pays_frontalier = {},
		population = "",
		regime = "",
		continent = "",
		superficie = "",
		

	}

local nomPays = ""

for line in io.lines() do
	local seq = main(line:gsub("[/.\",;]", " %1 "):gsub("[']", "%1 "))
	-- print(serialize(seq["&frontalier"]))
	-- print(seq["&pays"])
	-- print(serialize(seq[146]))
	-- print(serialize(seq[170]))
	elf = get_tags2(seq, "&frontalier", "&pays")
	print(elf)
	 if elf[1] ~= nil then 
	 	pays = elf[1]
	 	print(serialize(elf))

	 	print(serialize(pays))
	 	-- print("pays = " .. pays)
	 	-- print("1er = " .. pays[1])
	 	-- print(serialize(elf))
	 	-- print(serialize(seq))
	 	-- print(serialize(elf))
	 	-- print(serialize(get_tags(elf[1],"&pays")))
	 end
	-- if #seq > 6 then
	-- 	print(get_tokens(seq, 3, 6))
	-- end
		print(serialize(get_tags(seq, "&pays")))
	if nomPays == "" then
		local res = get_tags(seq, "&pays")
		nomPays = res[1]
		print("pays " .. nomPays)
		bdd[nomPays] = modele

	end

	local res = get_tags(seq, "&continent")
	if(#res ~= 0) then
		bdd[nomPays]["continent"] = res[1]
	end

	print("affichage bdd")
 	print(serialize(bdd))
	--seq:dump()
	--print(seq:tostring(tag))
end