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
         dump_handle:write("\t.upval " .. upval .. " nil ; u" .. index - 1 .. "\n\n")
    end

    local marksByPos = {}
    local writedMarks = {}

    for _, mark in ipairs(func.marks) do
        if (not writedMarks[mark.mark] and mark.mark ~= nil) then
            local pos = mark.pos
            if not marksByPos[pos] then
                marksByPos[pos] = {}
            end
            --rint(mark.mark, mark.pos)
            writedMarks[mark.mark] = true
            table.insert(marksByPos[pos], mark.mark)
        end
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

return dumper;