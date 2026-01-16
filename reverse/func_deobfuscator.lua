

local function deobfuscator(func)
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

    local markBase = {}
    for _, mark in ipairs(func.marks) do
        markBase[mark.mark] = mark.pos
    end

    local function reverse(endMark)
        while index <= #lines do
            if (full_stopped) then break end
            local save_line = true;
            local skip = false;

            local line = lines[index]:strip()
            --print(line)
            if (endMark ~= nil) then
                --table.insert(deobf_func.opcodes, lines[index - 1]:strip())
            
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


            if (line:startwith("TEST") and (not line:startwith("TESTSET"))) then
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

            if (line:startwith("EQ") or line:startwith("LT") or (line:startwith("LE") and line:sub(1,3) ~= "LEN")) then
                logger(line:sub(1, 2) .. " Detected")
                index = index + 1;
                table.insert(deobf_func.opcodes, line)
                local endMark = lines[index]:strip():match(":(goto_%d+)");
                
                save_line = false;
                table.insert(deobf_func.opcodes, lines[index]:strip())
                index = index + 1;

                reverse(endMark)

                table.insert(deobf_func.marks, {
                    pos = #deobf_func.opcodes + 1,
                    mark = endMark
                })
            end

        
            if (line:startwith("JMP")) then
                local gotoMark = line:match(":(goto_%d+)")
                index = markBase[gotoMark]
                save_line = false;
                skip = true;
                if (PARSER_ENV.logging_jumps) then  
                    logger("Jump to " .. gotoMark)
                end
            end
            
            if (save_line) then
                table.insert(deobf_func.opcodes, line)
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
    end

    reverse();

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
