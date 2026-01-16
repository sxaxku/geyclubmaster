function string.startwith(str, s) 
    return #s > 0 and str:sub(1, #s) == s
end

function string.strip(s)
    if type(s) ~= "string" then
        error("string.strip() called on non-string: " .. type(s), 2)
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end