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
