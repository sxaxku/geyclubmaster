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
    local log_handle = io.open(PARSER_ENV.log_path, "a");

    PARSER_ENV.func_stack = {}
    PARSER_ENV.log_handle = log_handle;
    PARSER_ENV.logger = logger;
    

    local f = io.open(PARSER_ENV.lasm_path, "r");
    string = require("tools/strings")

    local lines = {};
    local funcparser = require("parser/func_parser");

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

    local parsed_lasm = funcparser(lines, 0);

    --PARSER_ENV.log_path = "logs/log_" .. os.date("%Y_%m_%d_%H_%M_%S") .. ".log"

    --os.rename("logs/latest.log", PARSER_ENV.log_path)

    PARSER_ENV.log_handle:close()
end

init();