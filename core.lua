local _, DelCraft = ...

-- child > parent
local function customSort(array)
	local countSwap = 1
	while countSwap > 0 do
		countSwap = 0
		for i = 1, #array, 1 do
			for j = i + 1, #array, 1 do
				if not (DelCraft.adj[array[i][1]][array[j][1]] == nil) then
					array[i], array[j] = array[j], array[i]
					countSwap = countSwap + 1
				end
			end
		end
	end
	return array
end

local totalBuy = {}
local totalCraft = {}
local totalCraftI = {}
local totalCraftSort = {}
local function dfs(root, qty)
	if root == "dummy" then
		root = "masterwork target dummy"
	elseif root == "sapper" then
		root = "goblin sapper charge"
	elseif root == "dynamite" then
		root = "dense dynamite"
	elseif root == "launcher" then
		root = "cluster launcher"
	end

	if DelCraft.adj[root] == nil then
		return
	end

	local qtyOld = qty
	if DelCraft.out[root] then
		qty = math.ceil(qty / DelCraft.out[root])
	end

	local stack = { { root, qty } }
	local total = {}
	local i = 0

	local pop = table.remove(stack, #stack)

	total[pop[1]] = pop[2]

	for k, v in pairs(DelCraft.adj[pop[1]]) do
		table.insert(stack, { k, math.ceil(v * pop[2] / (DelCraft.out[k] or 1)) })
	end

	while #stack > 0 do
		i = i + 1

		pop = table.remove(stack, #stack)

		total[pop[1]] = (total[pop[1]] or 0) + pop[2]

		for k, v in pairs(DelCraft.adj[pop[1]]) do
			table.insert(stack, { k, math.ceil(v * pop[2] / (DelCraft.out[k] or 1)) })
		end
	end

	local toBuy = {}
	local toCraft = {}

	for k, v in pairs(total) do
		if next(DelCraft.adj[k]) == nil then
			toBuy[k] = v
		else
			table.insert(toCraft, { k, v })
		end
	end

	local toCraftSorted = customSort(toCraft)

	print("###############################################")
	print("crafting", qtyOld, root)
	print("###############################################")

	print("to buy")
	for k, v in pairs(toBuy) do
		print("", v .. "x ", k)
		totalBuy[k] = (totalBuy[k] or 0) + v
	end

	print("-----------------------------------------")
	print("to craft sorted")
	for _, v in ipairs(toCraftSorted) do
		print("", v[2] .. "x ", v[1])
		totalCraft[v[1]] = (totalCraft[v[1]] or 0) + v[2]
	end
end

local function MyAddonCommands(msg, _)
	if msg == "total" then
		for k, v in pairs(totalCraft) do
			table.insert(totalCraftI, { k, v })
		end
		totalCraftSort = customSort(totalCraftI)
		print("###############################################")
		print("Crafting Total")
		print("###############################################")

		print("totalBuy:")
		for k, v in pairs(totalBuy) do
			print("", v .. "x ", k)
		end

		print("-----------------------------------------")
		print("totalCraftSort:")

		for _, v in ipairs(totalCraftSort) do
			print("", v[2] .. "x ", v[1])
		end
		return
	end

	if msg == "clear" then
		totalBuy = {}
		totalCraft = {}
		totalCraftI = {}
		totalCraftSort = {}

		print("total list cleared")
		return
	end

	local root, qty = string.match(msg, "(%D+)%s(%d+)")

	if qty == nil then
		qty = 1
		root = string.match(msg, "%D+")
	end
	if root == nil then
		print(
			"wrong inputs, use '/craft <item> <quantity>' where <item> is the name of the item (string) and <quantity> the amount (number). if you do not specify a quantity, then quantity = 1 is assumed"
		)
		return
	end
	root = string.lower(root)
	dfs(root, qty)
end

SLASH_DELCRAFT1, SLASH_DELCRAFT2 = "/craft", "/delcraft"

SlashCmdList["DELCRAFT"] = MyAddonCommands
