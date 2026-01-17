function table.copy(orig, seen)
    seen = seen or {}
    if seen[orig] then
        return seen[orig]
    end

    local copy
    if type(orig) == "table" then
        copy = {}
        seen[orig] = copy
        for k, v in next, orig, nil do
            copy[table.copy(k, seen)] = table.copy(v, seen)
        end
        setmetatable(copy, table.copy(getmetatable(orig), seen))
    else
        copy = orig
    end
    return copy
end


function table.inject(tab1, tab2, injectPos)
    if not tab1 or not tab2 then return tab1 end
    if injectPos < 1 then injectPos = 1 end
    local len1 = #tab1
    if injectPos > len1 + 1 then injectPos = len1 + 1 end
    
    for i = #tab2, 1, -1 do
        table.insert(tab1, injectPos, tab2[i])
    end

    return tab1
end