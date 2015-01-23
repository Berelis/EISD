local name = dark.pipeline()
--chargement de la liste des prénom
name:lexicon("&pays", "pays.txt")

local position = dark.pipeline()
position:pattern([[
	[&continent (
			/[Ee]urope/ |
			/[Aa]sie/ |
			/[Aa]frique/ |
			/[Oo]c[ée]anie/ |
			/[Aa]m[ée]rique/
			)
	]
]])

position:pattern([[
	[&frontalier ( /entouré/ | /bordé/) par (&CON? &DET? &pays &PCT?)+
	]
]])

local main = dark.pipeline()
--détéction des mots de la langue française
main:model("model/postag-fr")

--ajout des pattern créés précédemments
main:add(name)
main:add(position)

local tag = {
	pays = "green",
	continent = "red",
	frontalier = "blue"
}

for line in io.lines() do
	local seq = main(line:gsub("[/.\",;]", " %1 "):gsub("[']", "%1 "))
	--seq:dump()
	print(seq:tostring(tag))
end
