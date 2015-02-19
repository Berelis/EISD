local dir = arg[1]
print('ls -a " '.. dir ..'"')
for f in io.popen('ls -a "'.. dir ..'"'):lines() do
	print(f)
	print("./dark main.lua < " .. f)
	os.execute("./dark main.lua < " .. dir..f)
end
