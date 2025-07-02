local _, DelCraft = ...

-- Initialize global tables
local totalBuy = {}
local totalCraft = {}
local totalCraftI = {}
local totalCraftSort = {}

-- Dependency-aware sort (child items before parents)
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

-- Fuzzy matching function (only called if exact match fails)
local function fuzzyMatch(input, items)
    local matches = {}
    input = string.lower(input)
    local inputWords = {}
    for word in input:gmatch("%S+") do
        table.insert(inputWords, word)
    end

    -- Score each item in DelCraft.adj
    for itemName, _ in pairs(items) do
        local score = 0
        local itemLower = string.lower(itemName)
        
        -- Check if input is a substring of the item name
        if string.find(itemLower, input, 1, true) then
            score = score + 50 -- High score for exact substring match
            score = score + (100 / string.len(itemName)) -- Bonus for shorter names
        end

        -- Check for individual word matches
        local wordMatches = 0
        for _, word in ipairs(inputWords) do
            if string.find(itemLower, word, 1, true) then
                wordMatches = wordMatches + 1
                score = score + 20 -- Bonus for each matching word
                if string.find(itemLower, "^" .. word, 1, true) then
                    score = score + 10 -- Extra bonus for prefix match
                end
            end
        end
        if wordMatches == #inputWords and #inputWords > 1 then
            score = score + 30 -- Bonus for matching all input words
        end

        if score > 0 then
            table.insert(matches, { name = itemName, score = score })
        end
    end

    -- Sort matches by score (descending)
    table.sort(matches, function(a, b) return a.score > b.score end)

    return matches
end

-- Depth-first search to calculate crafting dependencies
local function dfs(root, qty)
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
        totalCraftI = {}
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

    -- Parse input: item name (quoted or unquoted) followed by optional quantity
    local root, qty
    -- Try quoted item name first
    root, qty = string.match(msg, '"([^"]+)"%s*(%d*)')
    if root == nil then
        -- Fallback to unquoted input (item name is everything before the last number)
        root, qty = string.match(msg, '(.-)%s*(%d*)$')
        root = root and string.gsub(root, "%s+$", "") -- Trim trailing spaces
        if root == nil or root == "" then
            print(
                'Wrong input. Use \'/craft "<item>" <quantity>\' for exact matches (e.g., "enchant 2h weapon - major intellect 1"), \'/craft <item> <quantity>\' for single-word items or aliases (e.g., "dummy 10"), or \'/craft <partial name> <quantity>\' for fuzzy matching (e.g., "enchant intellect 1"). Quantity is optional (defaults to 1).'
            )
            return
        end
    end
    qty = tonumber(qty) or 1 -- Default to 1 if no quantity provided
    root = string.lower(root)

    -- Apply special case mappings
    local mappedRoot = root
    if root == "dummy" then
        mappedRoot = "masterwork target dummy"
    elseif root == "sapper" then
        mappedRoot = "goblin sapper charge"
    elseif root == "dynamite" then
        mappedRoot = "dense dynamite"
    elseif root == "launcher" then
        mappedRoot = "cluster launcher"
    end

    -- Try exact match in DelCraft.adj
    if DelCraft.adj[mappedRoot] then
        root = mappedRoot
        dfs(root, qty)
        return
    elseif DelCraft.adj[root] then
        -- Input is already an exact match
        dfs(root, qty)
        return
    end

    -- No exact match, try fuzzy matching
    local matches = fuzzyMatch(root, DelCraft.adj)
    if #matches == 0 then
        print("No items found matching '" .. root .. "'.")
        return
    elseif #matches == 1 then
        root = matches[1].name
    else
        -- Multiple matches: print suggestions
        print("Multiple items match '" .. root .. "'. Please specify one of:")
        for i, match in ipairs(matches) do
            if i > 5 then
                print("  ... (more matches available, please refine your input)")
                break
            end
            print("  " .. match.name)
        end
        return
    end
    
    if not DelCraft.adj[root] then
        print("Item '" .. root .. "' not found in crafting database.")
        return
    end

    dfs(root, qty)
end

SLASH_DELCRAFT1, SLASH_DELCRAFT2 = "/craft", "/delcraft"
SlashCmdList["DELCRAFT"] = MyAddonCommands
