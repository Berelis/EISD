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

for line in io.lines() do
	local seq = main(line:gsub("[/.\",;]", " %1 "):gsub("[']", "%1 "))
	print(serialize(get_tags(seq, "&pays")))
	if #seq > 6 then
		print(get_tokens(seq, 3, 6))
	end
	--seq:dump()
	print(seq:tostring(tag))
end