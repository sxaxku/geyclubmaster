
local cc = {}

cc.test = function (a, b, vars)
    a = tonumber(a);
    b = tonumber(b);
 
    if (a ~= nil and b ~= nil) then
        if b == 0 and vars[a] then
            return true
        end

        if b == 1 and not vars[a] then
            return false
        end
    end

    return nil
end

cc.eq = function (a, b, c)
    a = tonumber(a);
    b = tonumber(b);
    c = tonumber(c);

    local s = "=="
    if (a == 1) then
        s = "~="
    end

    if (a ~= nil and b ~= nil and c ~= nil) then
        return load("return " .. b .. s .. c)()
    end

    return nil
end

cc.lt = function (a, b, c)
    a = tonumber(a);
    b = tonumber(b);
    c = tonumber(c);

    local s = ">"
    if (a == 1) then
        s = "<"
    end

    if (a ~= nil and b ~= nil and c ~= nil) then
        return load("return " .. b .. s .. c)()
    end

    return nil
end

cc.le = function (a, b, c)
    a = tonumber(a);
    b = tonumber(b);
    c = tonumber(c);

    local s = ">="
    if (a == 1) then
        s = "<="
    end

    if (a ~= nil and b ~= nil and c ~= nil) then
        return load("return " .. b .. s .. c)()
    end

    return nil
end




local function dumper(func)
    local dump_handle = PARSER_ENV.dump_handle;
    dump_handle:write(".func " .. func.name .. "\n")

    dump_handle:write("\t.source \"" .. func.headers.source .. "\"\n")
    dump_handle:write("\t.linedefined " .. func.headers.linedefined .. "\n")
    dump_handle:write("\t.lastlinedefined " .. func.headers.lastlinedefined .. "\n")
    dump_handle:write("\t.numparams " .. func.headers.numparams .. "\n")
    dump_handle:write("\t.is_vararg " .. func.headers.is_vararg .. "\n")
    dump_handle:write("\t.maxstacksize " .. func.headers.maxstacksize .. "\n\n")

    for index, upval in ipairs(func.upvals) do
         dump_handle:write("\t.upval " .. upval .. " ; u" .. index .. "\n\n")
    end

    local marksByPos = {}

    for _, mark in ipairs(func.marks) do
        local pos = mark.pos
        if not marksByPos[pos] then
            marksByPos[pos] = {}
        end
        table.insert(marksByPos[pos], mark.mark)
    end

    for index, opcode in ipairs(func.opcodes) do
        local marks = marksByPos[index]
        if marks then
            for _, mark in ipairs(marks) do
                dump_handle:write("\t:" .. mark .. "\n")
            end
        end

        dump_handle:write("\t" .. opcode .. "\n\n")
    end


    dump_handle:write(".end " .. func.name .. "\n")
end

local function deobfuscator(func)
    local vars = {}
    
    --dumper(func)
    local deobf_func = table.copy(func);
    local lines = deobf_func.opcodes;

    deobf_func.opcodes = {};
    deobf_func.marks = {};

    local markBase = {}
    for _, mark in ipairs(func.marks) do
        markBase[mark.mark] = mark.pos
    end

    local index = 1;
    while index <= #lines do
        local line = lines[index]:strip()

        if (line:startwith("LOADK")) then
            local v = line:match("LOADK v(%d+)");
            if (line:match("LOADK v" .. tonumber(v) .. " \"xlet__\"") or line:match("LOADK v" .. tonumber(v) .. " \"__xlet\"")) then
                vars[tonumber(v)] = "xlet"
            end
            vars[tonumber(v)] = 0
        end

        if (line:startwith("EQ") or line:startwith("LT") or line:startwith("LE")) then
            local f = string.sub(line, 1, 2):lower();
            local a, b, c = line:match(".. ([01]*) ([v0987654321]*) ([v0987654321]*)")
            
            
            if (not cc[f](a, b, c)) then
                index = index + 1
            end
        end

        if (line:startwith("TEST")) then
            local v, l = line:match("TEST v(%d+) [01]")
            if (not cc.test(tonumber(v), tonumber(l), vars)) then
                index = index + 1
            end
        end

    
        if (line:startwith("JMP")) then
            local mm = line:match(" :(goto_%d+)")
            
            index = markBase[mm] - 1
        elseif (line:startwith("TEST") or line:startwith("EQ") or line:startwith("LT") or line:startwith("LE")) then
        else
            table.insert(deobf_func.opcodes, (line:gsub("%s*;[^\n]*", "")))
        end

        if (line == "RETURN") then
            break
        end
        --print(line)
        index = index + 1;
    end

    dumper(deobf_func)
end

return deobfuscator;

-- TEST A B
-- B == 0; A is true;
-- B == 1; A is false;

-- EQ A B C 
-- A = 1; B ~= C;
-- A = 0; B == C;

-- LT A B C 
-- A = 1; B < C
-- A = 0; B > C

-- LE A B C 
-- A == 1; B <= C
-- A == 0; B >= C
