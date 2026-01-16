local index = 1

local function parse_func(lines, t)
    local fname
    local oldLine = lines[index - 1]
    if oldLine == nil then
        fname = "main"
    else
        fname = oldLine:match("%.func (F%d+)")
    end

    table.insert(PARSER_ENV.func_stack, fname)

    local path = table.concat(PARSER_ENV.func_stack, "/")

    PARSER_ENV.logger("Start parsing " .. path, DEBUG)

    local func = {
        headers = {},
        upvals = {},
        opcodes = {},
        marks = {},
        funcs = {},
    }

    func.headers.name = fname;

    local opcodeIndex = 0
    while index ~= #lines do
        local line = lines[index]:strip()

        if line:startwith(".func") then
            index = index + 1
            local child = parse_func(lines, t + 1)
            child.name = line:match("%.func ([^ ]+)")
            table.insert(func.funcs, child)
        end

        if line:startwith(".end") then
            break
        end

        --print(line)
        if line:startwith(".source") then
            func.headers.source = (line .. "\n\255"):match('%.source "(.-)"\n\255')
            --print(func.headers.source or 85648345846)
        elseif line:startwith(".linedefined") then
            func.headers.linedefined = line:match("%.linedefined (%d+)")
        elseif line:startwith(".lastlinedefined") then
            func.headers.lastlinedefined = line:match("%.lastlinedefined (%d+)")
        elseif line:startwith(".numparams") then
            func.headers.numparams = line:match("%.numparams (%d+)")
        elseif line:startwith(".is_vararg") then
            func.headers.is_vararg = line:match("%.is_vararg (%d+)")
        elseif line:startwith(".maxstacksize") then
            func.headers.maxstacksize = line:match("%.maxstacksize (%d+)")
        end

        if line:startwith(".upval") then
            table.insert(func.upvals, line:match("%.upval ([uv]%d+) "))
        end

        if line:sub(1, 1):match("[A-Z]") then
            opcodeIndex = opcodeIndex + 1
            table.insert(func.opcodes, line)
        end

        if line:sub(1, 1) == ":" then
            table.insert(func.marks, {
                pos = opcodeIndex + 1,
                mark = line:sub(2)
            })
        end

        index = index + 1
    end


    table.remove(PARSER_ENV.func_stack) -- pop
    return func
end

return parse_func