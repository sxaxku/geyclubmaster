WARN = 1;
ERROR = 2;
DEBUG = 3;
FATAL = 4;

local function switch(level)
    local l;
    if (level == WARN) then
        l = "WARN"
    elseif (level == ERROR) then
        l = "ERROR"
    elseif (level == DEBUG) then
        l = "DEBUG"
    elseif (level == FATAL) then
        l = "FATAL"
    else
        l = "DEBUG"
    end

    return l
end

local function logger(message, level)
    local s = os.date("%Y-%m-%d %H:%M:%S") ..
              " " .. switch(level) .. 
              "\t" .. message .. "\n"

    PARSER_ENV.log_handle:write(s)
end


local function init()
    io.open(PARSER_ENV.log_path, "w"):write("------- log of " .. os.date("%Y-%m-%d %H:%M:%S") .. " -------\n\n")
    io.open(PARSER_ENV.dump_path, "w"):write("");
    local log_handle = io.open(PARSER_ENV.log_path, "a");
    local dump_handle = io.open(PARSER_ENV.dump_path, "a");

    PARSER_ENV.func_stack = {}
    PARSER_ENV.log_handle = log_handle;
    PARSER_ENV.logger = logger;

    PARSER_ENV.dump_handle = dump_handle;
    

    local f = io.open(PARSER_ENV.lasm_path, "r");
    require("tools/strings")
    require("tools/tables")

    local lines = {};
    local funcparser = require("parser/func_parser");
    local deobfuscator = require("reverse/func_deobfuscator");
    local dumper = require("dumper/dumper");

    if not f then
        print(tostring(f))
        print("Is not file")
        os.exit()
    end

    logger("Prepare lasm file")
    while true do
        local l = f:read("l");
        table.insert(lines, l);
        if (l == nil) then break end
    end

    f:close()

    local parsed_lasm = funcparser(lines, 0);
    parsed_lasm.name = "main"

    -- local function fullDeobf(func)
    --     local deobfed = deobfuscator(func)
    --     for index, f in pairs(func.funcs) do
    --         -- print(f, 1)
    --         -- print(f.name, 2)
    --         deobfed[index] = fullDeobf(f);
    --     end

    --     return deobfed;
    -- end

    -- local deobfuscated_lasm = fullDeobf(parsed_lasm)

    -- dumper(deobfuscated_lasm)
    
    dumper(deobfuscator(parsed_lasm.funcs[1].funcs[4]))
    --print(parsed_lasm.funcs[1].funcs[4].funcs[11].name)

    PARSER_ENV.log_handle:close()
    PARSER_ENV.dump_handle:close()
end

init();