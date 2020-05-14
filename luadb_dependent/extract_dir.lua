-----------------------------------------------
-- start luadb in all modules

extractor 		= require "src.luadb.extraction.moduleExtractor"
astManager      = require "src.luadb.manager.AST"
utils     		= require "src.luadb.utils"
ast 			= require "src.luadb.ast"

utils.logger:setLevel(logging.INFO)

localDir = "/home/michael/luadb/etc/luarocks_test"
astMan = astManager.new()
path = arg[1]
extractedGraph  = extractor.extract(path, astMan)
myGraph = {}
nodesCount = 0

local function compare(a, b)
  return a.position < b.position
end

local function getStatements(AST)
	local statementNodes = {}

	if (AST.key == "Assign" or AST.key == "Do" or AST.key == "While" or AST.key == "Repeat" or AST.key == "If" or
		AST.key == "NumericFor" or AST.key == "GenericFor" or AST.key == "GlobalFunction" or AST.key == "LocalFunction" or
		AST.key == "LocalAssign" or AST.key == "LastStat") then

		table.insert(statementNodes, AST)
	end

	for _, node in pairs(AST.data) do
		local tmpNodes = getStatements(node)

		for _, v in pairs(tmpNodes) do 
			table.insert(statementNodes, v) 
		end
	end

	return statementNodes

end

local function areEqual(node1, node2)
	return (node1.key == node2.key and node1.tag == node2.tag and node1.position == node2.position and node1.text == node2.text) 
end

local function notContained(astNodes, node)
	for _, n in pairs(astNodes) do
		if (areEqual(n, node)) then return false end
	end

	return true
end

local function countCharacters(text)
	return string.len(text)
end

local function countLines(text)
	local counter = 0
	for i = 1, #text do
		if (text:sub(i, i) == "\n") then counter = counter + 1 end
	end

	if (text:sub(#text, #text) ~= "\n") then counter = counter + 1 end

	return counter
end

local function getLineNumber(text, position)
	local counter = 0
	for i = 1, position do
		if (text:sub(i, i) == "\n") then counter = counter + 1 end
	end

	return counter + 1
end

local function sortChildren(node)

	if (node.childrenCount > 0) then
		table.sort(node.children, compare)
		for _, child in pairs(node.children) do
			sortChildren(child)

		end
	end
end


-- tuto funkciu volam az ked viem ze urcite tam je minimalne jedne child na vypisanie
local function printChildrenTree(file, node, level)

	for i = 1, level do	file:write("\t\t") end

	file:write("\t\"children\": [\n")

	for index, child in pairs(node.children) do

		-- counting nodes
		nodesCount = nodesCount + 1

		if (index ~= 1) then file:write(",\n") end

		for i = 1, (level + 1) do file:write("\t\t") end	
		file:write("{\n")

		for i = 1, (level + 1) do file:write("\t\t") end
		file:write("\t\"index\": ".. index .. ",\n")

		for i = 1, (level + 1) do file:write("\t\t") end
		file:write("\t\"tag\": \"".. child.tag .. "\",\n")

		for i = 1, (level + 1) do file:write("\t\t") end
		file:write("\t\"position\": ".. child.position .. ",\n")
		
		for i = 1, (level + 1) do file:write("\t\t") end
		file:write("\t\"container\": \"".. child.container .. "\",\n")

		for i = 1, (level + 1) do file:write("\t\t") end
		modifiedText = string.gsub(child.text, "\n", "\\n")
		modifiedText = string.gsub(modifiedText, "\"", "\\\"")
		file:write("\t\"text\": \"".. modifiedText .. "\",\n")

		for i = 1, (level + 1) do file:write("\t\t") end
		file:write("\t\"line\": ".. child.line .. ",\n")		

		for i = 1, (level + 1) do file:write("\t\t") end
		file:write("\t\"lines_count\": ".. child.linesCount .. ",\n")

		for i = 1, (level + 1) do file:write("\t\t") end
		file:write("\t\"characters_count\": ".. child.charactersCount .. ",\n")

		for i = 1, (level + 1) do file:write("\t\t") end

		if (child.container ~= "function") then
			file:write("\t\"children_count\": ".. child.childrenCount)
		else
			file:write("\t\"children_count\": 0")
		end

		if (child.childrenCount > 0 and child.container ~= "function") then 

			file:write(",\n")
			printChildrenTree(file, child, level + 1)

		else

			file:write("\n")

		end

		for i = 1, (level + 1) do file:write("\t\t") end
		file:write("}")

	end

	file:write("\n")
	for i = 1, level do	file:write("\t\t") end
	file:write("\t]\n")

end


-- get important parts from the extra large graph
for _, edge in pairs(extractedGraph.modified_edges) do

	-- file with module one to one
	if (edge.from[1].meta.type == "file" and edge.to[1].meta.type == "module") then
		table.insert(myGraph, edge)


	-- from every module to 4 containers
	elseif (edge.label == "contains" and edge.from[1].meta.type == "module" and edge.to[1].meta.type == "require container") then
		table.insert(myGraph, edge)

	elseif (edge.label == "provides" and edge.from[1].meta.type == "module" and edge.to[1].meta.type == "interface container") then
		table.insert(myGraph, edge)

	elseif (edge.label == "contains" and edge.from[1].meta.type == "module" and edge.to[1].meta.type == "function container") then
		table.insert(myGraph, edge)

	elseif (edge.label == "contains" and edge.from[1].meta.type == "module" and edge.to[1].meta.type == "variable container") then
		table.insert(myGraph, edge)


	-- functions and variables etc. in each container
	elseif (edge.label == "declares" and edge.from[1].meta.type == "function container" and edge.to[1].meta.type == "function") then
		table.insert(myGraph, edge)

	elseif (edge.label == "initializes" and edge.from[1].meta.type == "variable container") then
		table.insert(myGraph, edge)

	elseif (edge.label == "initializes" and edge.from[1].meta.type == "require container") then
		table.insert(myGraph, edge)

	elseif (edge.label == "provides" and edge.from[1].meta.type == "interface container") then
		table.insert(myGraph, edge)

	end
end


os.execute("mkdir data 2> /dev/null")
repo = string.match(path, "/(.*)")
os.execute("mkdir data/"..repo.." 2> /dev/null")

for _, moduleEdge in pairs(myGraph) do 

	local astNodes = {}

	-- make json file for each module
	if (moduleEdge.from[1].meta.type == "file" and moduleEdge.to[1].meta.type == "module") then

		local AST = astMan:findASTByID(moduleEdge.from[1].data.astID)
		-- print('AST root id ' .. AST.nodeid)

		-- find corresponding nodes from AST (meaning finding twins or whatever for the found nodes in the big graph)
		for _, edge in pairs(myGraph) do 

			if (moduleEdge.from[1].data.astID == edge.to[1].data.astID and
				edge.label == "declares" and edge.from[1].meta.type == "function container" and edge.to[1].meta.type == "function") then

				node = ast.getNodeInASTByID(AST, edge.to[1].data.astNodeID)

				node.container = "function"
				node.childrenCount = 0
				node.children = {}
				table.insert(astNodes, node)


			elseif (moduleEdge.from[1].data.astID == edge.to[1].data.astID and
				edge.label == "initializes" and edge.from[1].meta.type == "variable container") then

				node = ast.getNodeInASTByID(AST, edge.to[1].data.astNodeID)

				node.container = "variable"
				node.childrenCount = 0
				node.children = {}
				table.insert(astNodes, node)


			elseif (moduleEdge.from[1].data.astID == edge.to[1].data.astID and
				edge.label == "initializes" and edge.from[1].meta.type == "require container") then

				node = ast.getNodeInASTByID(AST, edge.to[1].data.astNodeID)

				node.container = "require"
				node.childrenCount = 0
				node.children = {}
				table.insert(astNodes, node)


			elseif (moduleEdge.from[1].data.astID == edge.to[1].data.astID and 
				edge.label == "provides" and edge.from[1].meta.type == "interface container") then

				node = ast.getNodeInASTByID(AST, edge.to[1].data.astNodeID)

				node.container = "interface"
				node.childrenCount = 0
				node.children = {}
				table.insert(astNodes, node)

			end
		end


		-- add statement nodes directly from AST
		local statements = getStatements(AST)

		for _, node in pairs(statements) do
			if (notContained(astNodes, node)) then
				node.container = "other"
				node.childrenCount = 0
				node.children = {}
				table.insert(astNodes, node)

			end
		end

		-- sort according to the position
		table.sort(astNodes, compare)

		-- add metrics
		for _, node in pairs(astNodes) do
			node.linesCount = countLines(node.text)
			node.charactersCount = countCharacters(node.text)
			node.line = getLineNumber(AST.text, node.position)
		end

		-- handle children situation in case of overlapping nodes
		for i = #astNodes, 2, -1 do

			local isAlreadyChildren = false

			for j = i - 1, 1, -1 do
				
				if (astNodes[i].position < (astNodes[j].position + astNodes[j].charactersCount) and isAlreadyChildren == false) then
					astNodes[j].childrenCount = astNodes[j].childrenCount + 1
					table.insert(astNodes[j].children, astNodes[i])
					isAlreadyChildren = true
					-- wasn't able to delete nicely the nodes which are used as children (well, copy of them is made)
					-- duplicate node is simply labeled as copy
					astNodes[i].key = "copy"
				end
			end
		end

		-- children are now not sorted so that needs to be dealt with
		for _, node in pairs(astNodes) do
			sortChildren(node)
		end

		-- create json 
		nodesCount = 0
		local ASTpath = astMan:findASTPathByID(moduleEdge.from[1].data.astID)
		local file = io.open("./data/"..repo.."/"..moduleEdge.from[1].data.astID..".json", "w+")
		file:write("{\n")
		file:write("\t\"repository\": \""..repo.."\",\n")
		moduleName = string.match(ASTpath, "^.+/(.+)$")
		file:write("\t\"module\": \""..moduleName.."\",\n")
		file:write("\t\"path\": \""..localDir.."/"..ASTpath.."\",\n")
		modifiedASTText = string.gsub(AST.text, "\n", "\\n")
		modifiedASTText = string.gsub(modifiedASTText, "\"", "\\\"")
		file:write("\t\"text\": \""..modifiedASTText.."\",\n")
		-- file:write("\t\"nodes_count\": ".. nodesCount .. ",\n")
		file:write("\t\"nodes\": [\n")

		index = 0
		for _, node in pairs(astNodes) do

			-- just make sure we don't include the child nodes multiple times
			if (node.key ~= "copy") then

				index = index + 1
				-- counting nodes
				nodesCount = nodesCount + 1

				if (index ~= 1) then file:write(",\n") end

				file:write("\t\t{\n")

				file:write("\t\t\t\"index\": ".. index .. ",\n")
				file:write("\t\t\t\"tag\": \"".. node.tag .. "\",\n")
				file:write("\t\t\t\"position\": ".. node.position .. ",\n")
				file:write("\t\t\t\"container\": \"".. node.container .. "\",\n")

				modifiedText = string.gsub(node.text, "\n", "\\n")
				modifiedText = string.gsub(modifiedText, "\"", "\\\"")

				file:write("\t\t\t\"text\": \"".. modifiedText .. "\",\n")
				file:write("\t\t\t\"line\": ".. node.line .. ",\n")	
				file:write("\t\t\t\"lines_count\": ".. node.linesCount .. ",\n")
				file:write("\t\t\t\"characters_count\": ".. node.charactersCount .. ",\n")

				-- I don't wanna ruin the nicely built tree, so just let's act like function nodes don't have any children
				if (node.container ~= "function") then
					file:write("\t\t\t\"children_count\": ".. node.childrenCount)
				else
					file:write("\t\t\t\"children_count\": 0")
				end
				
				if (node.childrenCount > 0  and node.container ~= "function") then

					file:write(",\n")
					printChildrenTree(file, node, 1)

				else
					file:write("\n")

				end

				file:write("\t\t}")

			end
		end

		file:write("\n\t],\n\t\"nodes_count\": "..nodesCount .. "\n}")
		file:close()

	end
end
