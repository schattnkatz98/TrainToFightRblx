-- Parameter
local THREADS = 200

local RS   = game:GetService("ReplicatedStorage")
local Reqs = RS.TrainEquipment.Remote
local Sys  = RS.TrainSystem.Remote

local EquipStation = Reqs.ApplyTakeUpStationaryTrainEquipment  
local Stationary   = Reqs.ApplyStationaryTrain                  
local Mobile       = Reqs.ApplyMobileTrain                      
local Speed        = Sys.TrainSpeedHasChanged  

local config = {
    TrainSpeed = 9e999,
    bdelay = 0,
    threads = {}
}

-- einmalige Ausrüstung (prüfen: Typ!)
do
    local ok, err = pcall(function()
        EquipStation:InvokeServer("2008") -- wenn Zahl erwartet
    end)
    if not ok then warn("EquipStation failed:", err) end
end

local function tickPack()
    local ok, err = pcall(function()
        local r1 = Stationary:InvokeServer()
        print("Stationary OK", r1)
        local r2 = Mobile:InvokeServer()
        print("Mobile OK", r2)
        Speed:FireServer(config.TrainSpeed) -- Zahl testen!
        print("Speed fired")
    end)
    if not ok then
        warn("tickPack error:", err)
    end
end

local function stopAllThreads()
    running = false
    for _, thread in pairs(config.threads) do
        coroutine.close(thread)
    end
    config.threads = {}
end


local function startAll()
    stopAllThreads()
    if running then return end
    running = true

    for i = 1, THREADS do
        local thread = coroutine.create(function()
            while running do
                tickPack()
                task.wait(config.bdelay)
            end
        end)
        table.insert(config.threads, thread)
        coroutine.resume(thread)
    end
end



-- Hotkey F
game:GetService("UserInputService").InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.F then
        if running then
            stopAllThreads()
        end

    end
end)

-- auto-start (wenn gewünscht)
startAll()
