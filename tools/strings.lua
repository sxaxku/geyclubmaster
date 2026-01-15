function string.startwith(str, s) 
    local size = string.len(s);
    return str:sub(1, size) == s
end

function string.strip(s)
  return ((s:gsub("^%s+", "")):gsub("%s+$", ""))
end

return string;