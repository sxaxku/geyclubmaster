function table.inject(tab1, tab2, injectPos)
    -- Проверка входных данных
    if not tab1 or not tab2 then return tab1 end
    if injectPos < 1 then injectPos = 1 end
    local len1 = #tab1
    if injectPos > len1 + 1 then injectPos = len1 + 1 end

    -- Вставка элементов из tab2 в tab1, начиная с injectPos
    for i = #tab2, 1, -1 do
        table.insert(tab1, injectPos, tab2[i])
    end

    return tab1
end

local tab = { "a", "b", "c" }
local toInsert = { "AAA", "BBB", "CCC" }

table.inject(tab, toInsert, 2)

for i, a in ipairs(tab) do
    print(i, a)
end