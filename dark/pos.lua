local main = dark.pipeline()
main:model("model/postag-fr")

main:pattern("[&DATE &NUM/&NUM/&NUM]")
main:pattern("[&NP &DET? &ADJ* (&NNC | &NNP)+ &ADJ* ]")

main:pattern("[&PER &NND* (&NNP | &part | /^%u%a*$/ )]")


local tag = {
	ADJ = "black", ADP = "black", ADV = "black", CON = "black",
	DET = "red", NNC = "black", NNP = "green", NUM = "black",
	OTH = "black", PCT = "black", PRO = "black", PRT = "black",
	VRB = "blue", NP = "yellow",
	ORG = "red", PER = "green", MISC = "yellow", LOC = "blue",
	DATE = "magenta", TITLE = "yellow"
}

for line in io.lines() do
	local seq = main(line:gsub("%p", "%1"))
	seq:dump()
	print(seq:tostring(tag))
end
