function printParsed(x)
    for i, a in pairs(x) do
        if type(a) == "table" then
            parser(a)
        else
            print(tostring(i) .. " = " .. tostring(a))
        end
    end
end

local file_lasm = io.open("lasm.lasm", "r+")

