-- function printParsed(x)
--     for i, a in pairs(x) do
--         if type(a) == "table" then
--             parser(a)
--         else
--             print(tostring(i) .. " = " .. tostring(a))
--         end
--     end
-- end


--printParsed(string)

PARSER_ENV = {};


local function main()
    PARSER_ENV.logging_jumps = true;
    -- PARSER_ENV.lasm_path = "scripts/dumps/dickpic.lasm"
    PARSER_ENV.lasm_path = "tests/enclasm.lasm"
    PARSER_ENV.log_path = "logs/latest.log"
    PARSER_ENV.dump_path = "tests/dump-reverse.lasm"
    -- PARSER_ENV.dump_path = "scripts/dumps/dump.lasm"

    require("init")
end

main(); 


print()
