dofile("../bdd.lua")
--local dir = arg[1]
local nbPays = 0
local tabInfo = {
	langue = 0,
	capitale = 0,
	monnaie = 0,
	religion =0,
	position = 0,
	pays_frontalier = 0,
	population = 0,
	regime = 0,
	continent = 0,
	superficie = 0
}

for nomPays,pays in pairs(bdd) do
	nbPays = nbPays +1
	for k,v in pairs(pays) do
		if v ~= nil and v ~= "" and #v ~= 0 then
			tabInfo[k] = tabInfo[k] + 1
		else
			if k == 'continent' then
				print(nomPays)
			end
		end
	end
end

print(serialize(tabInfo))

for k,v in pairs(tabInfo) do
	tabInfo[k] = (v/nbPays) * 100
end

print(serialize(tabInfo))
