--[[
    COMPLEX TEST SCRIPT FOR LASM OBFUSCATION/DEOBFUSCATION
    Target: Lua 5.1 / LuaJIT
]]

-- 1. Глобальные и Локальные переменные разных типов
local _localString = "Local String"
globalVar = "I am Global" -- Глобальная переменная (SETGLOBAL)
local _int, _float = 100, 3.14159
local _boolTrue, _boolFalse = true, false
local _nilVal = nil

-- 2. Таблицы (Смешанный тип: массив + хеш-таблица)
local mixedTable = {
    [1] = "Index One",
    ["key"] = "Value Key",
    nested = {
        val = 42
    },
    funcInTable = function() return "Anonymous" end
}

-- 3. Арифметика и Логика (Проверка регистров и констант)
local function calculateComplex(a, b, c)
    -- Сложное выражение для проверки порядка операций
    local result = (a * b) + (c / 2) - (a % 3) ^ 2
    
    -- Логические операторы (TEST/TESTSET)
    if (a > b and c ~= 0) or (not _boolFalse) then
        result = result + 1
    end
    
    return result
end

-- 4. Вложенные функции и Замыкания (Upvalues)
-- Это критично для проверки деобфускатора (GETUPVAL/SETUPVAL)
local function closureFactory(startValue)
    local counter = startValue -- Upvalue для внутренней функции
    
    return function(step)
        counter = counter + step
        local innerFunction = function() -- Функция в функции в функции
            return "Current: " .. tostring(counter)
        end
        return innerFunction()
    end
end

-- 5. Вариативные функции (VARARG)
local function varargTest(...)
    local args = {...} -- Создание таблицы из varargs
    local sum = 0
    
    -- Цикл Generic For (TFORLOOP)
    for i, v in ipairs(args) do
        if type(v) == "number" then
            sum = sum + v
        end
    end
    return sum
end

-- 6. Рекурсия (Проверка стека)
local function factorial(n)
    if n == 0 then return 1 end
    return n * factorial(n - 1)
end

-- 7. Циклы и Условия (JMP, FORLOOP, FORPREP, EQ, LT, LE)
local function loopTester()
    local i = 0
    
    -- While Loop
    while i < 3 do
        i = i + 1
    end
    
    -- Repeat Until
    repeat
        i = i - 1
    until i == 0
    
    -- Numeric For Loop
    local res = ""
    for j = 1, 5, 2 do
        if j == 3 then
            res = res .. "Three"
        elseif j > 3 then
            res = res .. "More"
        else
            res = res .. j
        end
    end
end

-- 8. Метатаблицы и ООП (GETTABLE, SETTABLE, SELF)
local Vector = {}
Vector.__index = Vector

function Vector.new(x, y)
    local self = setmetatable({}, Vector)
    self.x = x
    self.y = y
    return self
end

-- Перегрузка оператора сложения
function Vector.__add(v1, v2)
    return Vector.new(v1.x + v2.x, v1.y + v2.y)
end

-- Метод класса (использование : синтаксиса, opcode SELF)
function Vector:magnitude()
    return (self.x^2 + self.y^2)^0.5
end

function Vector:__tostring()
    return "Vector(" .. self.x .. ", " .. self.y .. ")"
end

-----------------------------------------------------
-- MAIN EXECUTION BLOCK (Точка входа)
-----------------------------------------------------

print("--- STARTING TEST ---")

-- Проверка условий и арифметики
local mathRes = calculateComplex(10, 5, 20)
print("Math Result:", mathRes)

-- Проверка замыканий
local counterFunc = closureFactory(10)
print("Closure 1:", counterFunc(5)) -- Должно быть 15
print("Closure 2:", counterFunc(5)) -- Должно быть 20

-- Проверка Vararg
local vSum = varargTest(1, 2, 3, "ignore", 4)
print("Vararg Sum:", vSum)

-- Проверка рекурсии
print("Factorial 5:", factorial(5))

-- Проверка циклов
loopTester()
print("Loops passed")

-- Проверка ООП
local v1 = Vector.new(2, 3)
local v2 = Vector.new(4, 5)
local v3 = v1 + v2 -- Вызов __add
print("Vector Add:", tostring(v3))
print("Vector Mag:", v3:magnitude())

-- Проверка pcall (обработка ошибок)
local status, err = pcall(function() 
    error("Test Error") 
end)
if not status then
    print("Error caught successfully")
end

print("--- TEST FINISHED ---")
