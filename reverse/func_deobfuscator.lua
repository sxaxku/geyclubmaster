local checks = 0;

local function deobfuscator(func)
    local types = {
        condition = 1,
        jump = 2,
        cycle = 3,
    }
    
    local function parseOpcode(line)
        local ret = {
            type = nil,
            opcode = nil,
        }

        if (line:startwith("TEST") and (not line:startwith("TESTSET"))) then
            ret.type = types.condition;
            ret.opcode = "TEST";
        elseif (line:startwith("EQ") or line:startwith("LT") or (line:startwith("LE") and line:sub(1,3) ~= "LEN")) then
            ret.type = types.condition;
            ret.opcode = line:sub(1,2);
        elseif (line:startwith("JMP")) then
            ret.type = types.jump;
            ret.opcode = "JMP";
        elseif (line:startwith("FORLOOP") or line:startwith("FORPREP")) then
            ret.type = types.cycle;
            ret.opcode = line:sub(1,7);
        elseif (line:startwith("TFORLOOP")) then
            ret.type = types.cycle;
            ret.opcode = line:sub(1,8);
        end

        return ret;
    end

    local function isTest(opcode) 
        return opcode == "TEST";
    end

    local function isOtherCondition(opcode)
        return opcode == "EQ" or opcode == "LT" or opcode == "LE";
    end

    local function isJump(opcode)
        return opcode == "JMP";
    end

    local function isCycle(opcode)
        return opcode == "FORPREP" or opcode == "FORLOOP";
    end

    local function istforCycle(opcode)
        return opcode == "TFORLOOP";
    end

    local logger = PARSER_ENV.logger;
    logger("Preparing for deobfuscation")
    local full_stopped = false;
    local index = 1;
    local vars = {}
    
    --dumper(func)
    local deobf_func = table.copy(func);
    local lines = deobf_func.opcodes;

    deobf_func.opcodes = {};
    deobf_func.marks = {};

    local tforcycle = {};
    local usableMarks = {};
    local markBase = {}
    for _, mark in ipairs(func.marks) do
        markBase[mark.mark] = mark.pos
        markBase[mark.pos] = mark.mark;
    end

    local function reverse(endMark, cycleInfo)

        local haveCycleInfo = false;
        if (cycleInfo ~= nil) then
            full_stopped = false;
            haveCycleInfo = true;
            index = cycleInfo.start_cycle_index;
        end

        while index <= #lines do
            if (full_stopped) then break end
            local save_line = true;
            local skip = false;

            local line = lines[index]:strip()
            local mark = markBase[index];

            if (mark ~= nil) then
                if (usableMarks[mark]) then
                    table.insert(deobf_func.marks, {
                        pos = #deobf_func.opcodes + 1,
                        mark = mark
                    })
                end
            end
            
            local opcode = line:match("%w+") or "none"

            if (endMark ~= nil) then
                if (index == markBase[endMark]) then
                    
                    index = index - 1
                    break
                end
            end
            
            if (line:startwith("LOADK")) then
                local v = line:match("LOADK v(%d+)");
                --if (line:match("LOADK v" .. v .. " \"xlet__\"") or line:match("LOADK v" .. v .. " \"__xlet\"") or line:match("LOADK v" .. v .. " \"error\"")) then
                    vars[tonumber(v)] = 1;
                --end
            end


            if (isTest(opcode)) then -- TEST
                local v, mode = line:match("TEST v(%d+) (%d+)")
                v = tonumber(v);
                mode = tonumber(mode);

                if (vars[v] == nil) then
                    logger("TEST Detected")
                    index = index + 1;
                    table.insert(deobf_func.opcodes, line)
                    local endMark = lines[index]:strip():match(":(goto_%d+)");
                    
                    save_line = false;
                    table.insert(deobf_func.opcodes, lines[index]:strip())
                    index = index + 1;

                    reverse(endMark)

                    --print(endMark == nil)

                    table.insert(deobf_func.marks, {
                        pos = #deobf_func.opcodes + 1,
                        mark = endMark
                    })
                else
                    if (vars[v]) then
                        save_line = false;
                    end
                    if (vars[v] and mode == 0) then
                        index = index + 1 -- next
                    else
                        index = index -- first
                    end
                end
            end

            if (isOtherCondition(opcode)) then -- EQ LT LE
                --print(checks)
                logger(line:sub(1, 2) .. " Detected")
                index = index + 1;
                table.insert(deobf_func.opcodes, line)
                local endMarkx = lines[index]:strip():match(":(goto_%d+)");
                
                save_line = false;
                table.insert(deobf_func.opcodes, lines[index]:strip())
                index = index + 1;


                reverse(endMarkx)

                table.insert(deobf_func.marks, {
                    pos = #deobf_func.opcodes + 1,
                    mark = endMark
                })
            end

        
            if (isJump(opcode)) then -- JMP
                local gotoMark = line:match(":(goto_%d+)")
                index = markBase[gotoMark]
                save_line = false;
                skip = true;
                if (PARSER_ENV.logging_jumps) then  
                    logger("Jump to " .. gotoMark)
                end
            end


            if (isCycle(opcode)) then -- FORLOOP FORPREP
                local markTo = line:match(":(goto_%d+)");
                usableMarks[markTo] = markTo;
            elseif (istforCycle(opcode)) then -- TFORLOOP
                --print(checks)
                checks = checks + 1;
                local startMark = line:match(":(goto_%d+)");

                tforcycle[#tforcycle].start_body_mark = startMark
                local x = nil
            end

            if (line:startwith("TFORCALL")) then
                

                if (mark == nil) then
                    error("unexpected error !")
                else
                    table.insert(tforcycle, {
                        end_body_mark = mark,
                        opcode_index = #deobf_func.opcodes + 1
                    })
                end
            local x = nil
            end
            
        
            if (save_line) then
                if (haveCycleInfo) then
                    table.insert(cycleInfo.opcodes, line)
                else
                    table.insert(deobf_func.opcodes, line)
                end
            end

            if (line:startwith("RETURN")) then
                full_stopped = true;
                break
            end
            
            ::continue::
            if (not skip) then
                index = index + 1;
            end
        end
        local x = nil
    end

    reverse();

    local offset = 0;
    for index, mark in pairs(tforcycle) do
        -- print(mark.start_body_mark, mark.end_body_mark)
        local cycleInfo = {
            start_body_mark = mark.start_body_mark,
            end_body_mark = mark.end_body_mark,
            opcode_index = mark.opcode_index,
            start_cycle_index = markBase[mark.start_body_mark],
            opcodes = {},
            marks = {}
        }

        local endMark = "end_cycle_body_" .. index;
        local startMark = "start_cycle_body_" .. index;

        table.insert(cycleInfo.opcodes, "JMP :" .. endMark)

        reverse(mark.end_body_mark, cycleInfo)

        
        local startMarkPos = cycleInfo.opcode_index + offset + 1;
        local endMarkPos = cycleInfo.opcode_index + offset + #cycleInfo.opcodes + 1;


        
        table.insert(deobf_func.marks, {
            pos = startMarkPos,
            mark = startMark
        })

        table.inject(deobf_func.opcodes, cycleInfo.opcodes, cycleInfo.opcode_index + offset)

        table.insert(deobf_func.marks, {
            pos = endMarkPos,
            mark = endMark
        })
        
        local line = deobf_func.opcodes[endMarkPos]
        deobf_func.opcodes[endMarkPos] = line:gsub(":goto_%d+", ":" .. startMark)

        

        offset = offset + #cycleInfo.opcodes;
        --os.exit();
    end

    return deobf_func;
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
