#!/usr/bin/lua

if(arg[2] == nil) then
	print( "usage: process_dofiles input.lua output_combined.lua");
	os.exit(0);
end


local fin = io.open(arg[1],"r");
local fout = io.open(arg[2],"w");

function include_file(name)
	local f= io.open(name,"r");
	
	while true do
		local line = fin.read(f);
		if(line == nil) then break; end

		if(string.match(line,"^#!") == nil) then
			fout.write(fout, line.."\n");
		end
	end
	
	io.close(f);
end

while true do
	local line = fin.read(fin);
	if(line == nil) then break; end
	
	local fname = string.match(line,"^my_dofile%(\"(%S+)\"%)");


	if(fname ~= nil) then 
		print("Including "..fname);
		include_file(fname); 
	else
		fout.write(fout, line.."\n");
	end
end

io.close(fin);
