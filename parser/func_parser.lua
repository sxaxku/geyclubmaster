local index = 0
local function parse_func(lines, t)  
    local fname
    local oldLine = lines[index - 1]
    if oldLine == nil then
        fname = "main"
    else
        fname = oldLine:match(".func (F%d+)")
    end

    print(string.rep("\t", t) .. "start parsing " .. fname)

    local func = {
        headers = {},
        upvals = {},

        opcodes = {},
        marks = {},

        funcs = {},
    };
    

    local opcodeIndex = 0;
    while index ~= #lines do
        index = index + 1;
        local line = lines[index]:strip();

        
        --print(line)

        if (line:startwith(".func")) then
            index = index + 1
            table.insert(func.funcs, parse_func(lines, t + 1))
            func.funcs[#func.funcs].name = line:match(".func ([^ ]+)")
            --break
        end

        if (line:startwith(".end")) then
            print(string.rep("\t", t) .. "end parsing " .. fname)
            break
        end


        if (line:startwith(".source")) then
            func.headers.source = (line .. "\255"):match("%.source \"(.-)\"\255")
        elseif (line:startwith(".linedefined")) then
            func.headers.linedefined = line:match(".linedefined (%d+)")
        elseif (line:startwith(".lastlinedefined")) then
            func.headers.linedefined = line:match(".lastlinedefined (%d+)")
        elseif (line:startwith(".numparams")) then
            func.headers.numparams = line:match(".numparams (%d+)")
        elseif (line:startwith(".is_vararg")) then
            func.headers.is_vararg = line:match(".is_vararg (%d+)")
        elseif (line:startwith(".maxstacksize")) then
            func.headers.maxstacksize = line:match(".maxstacksize (%d+)");
        end

        if (line:startwith(".upval")) then
            table.insert(func.upvals, line:match("%.upval ([uv]%d+) "))
        end
        
        if (line:sub(1, 1):match("[A-Z]")) then
            opcodeIndex = opcodeIndex + 1;
            table.insert(func.opcodes, line)
        end

        if (line:sub(1, 1) == ":") then
            table.insert(func.marks, {
                pos = opcodeIndex + 1,
                mark = line:sub(2)
            })
        end
    end

    
    return func;
end

return parse_func;