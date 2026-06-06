--[[
    Veltrxy - Build A Ring Farm - Keyless
    NEVERLOSE UI LIBRARY (CludeHub) – FIXED
]]

-- Load Neverlose library
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/CludeHub/Can-You-Come-Back-To-Me/refs/heads/main/NEVERLOSE-CS2-SOURCE.lua"
))()
if not Library then return warn("Library failed to load") end

-- Services & remotes (same as before)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local function safeWait(p, n, t)
    local ok, o = pcall(function() return p:WaitForChild(n, t or 5) end)
    return ok and o or nil
end

-- All remotes (unchanged)
local Services = {
    GetPlot = safeWait(safeWait(Remotes,"Plot",10) or Remotes,"GetPlot",10),
    PlantSeed = safeWait(Remotes,"PlantSeed",10),
    UpgradePlant = safeWait(Remotes,"UpgradePlant",10),
    UnlockPlot = safeWait(Remotes,"UnlockPlot",10),
    SellCrates = safeWait(Remotes,"SellCrates",10),
    RollSeeds = safeWait(Remotes,"RollSeeds",10),
    BuySeed = safeWait(Remotes,"BuySeed",10),
    UpgradeFarm = safeWait(Remotes,"UpgradeFarm",10),
    UpgradeSeedLuck = safeWait(Remotes,"UpgradeSeedLuck",10),
    UpgradeSeedRolls = safeWait(Remotes,"UpgradeSeedRolls",10),
    PlotUpgradeTransaction = safeWait(Remotes,"PlotUpgradeTransaction",10),
    ClaimDailyReward = safeWait(Remotes,"ClaimDailyReward",10),
    GetPlaytimeRewardState = safeWait(Remotes,"GetPlaytimeRewardState",10),
    ClaimPlaytimeReward = safeWait(Remotes,"ClaimPlaytimeReward",10),
    RequestOpenSeedPack = safeWait(Remotes,"RequestOpenSeedPack",10),
    SeedPackOpenFinished = safeWait(Remotes,"SeedPackOpenFinished",10),
    OpenSeedPack = safeWait(Remotes,"OpenSeedPack",10),
    SellPet = safeWait(Remotes,"SellPet",10),
}
-- Pets / PlantRush / QueenBee / etc (same as before)
local PetRemotes = safeWait(Remotes, "Pets", 3)
if PetRemotes then Services.UpgradePet = safeWait(PetRemotes,"UpgradePet",3) end
local PlantRushRemotes = safeWait(Remotes, "PlantRush", 3)
if PlantRushRemotes then Services.PlantRushShoot = safeWait(PlantRushRemotes,"Shoot",3); Services.PlantRushDropClaim = safeWait(PlantRushRemotes,"DropClaim",3) end
Services.QueenBee = safeWait(Remotes,"QueenBee",3)
Services.SubmitCode = safeWait(Remotes,"SubmitCode",3)
Services.GroupReward = safeWait(Remotes,"GroupReward",3)
local GearRemotes = safeWait(Remotes,"Gear",3)
if GearRemotes then Services.GearTransaction = safeWait(GearRemotes,"Transaction",3) end
local EggShopRemotes = safeWait(Remotes,"EggShop",3)
if EggShopRemotes then Services.EggShopTransaction = safeWait(EggShopRemotes,"Transaction",3) end
Services.RollEgg = safeWait(Remotes,"RollEgg",3)

-- Data replicator
local Replicator
pcall(function()
    local DataReplicator = require(ReplicatedStorage.Packages.DataReplicator)
    Replicator = DataReplicator.GetReplicator()
end)

-- Config (same as before)
local Config = {
    AutoPlant = false, AutoPlantMode = "Best Value", SelectedSeed = "Carrot", PlantDelay = 0.25,
    AutoUpgradePlants = false, AutoUnlockPlots = false,
    AutoSellCrates = false, SellDelay = 2,
    AutoRollSeeds = false, RollDelay = 1, AutoBuyRolledSeed = false, AutoOpenSeedPacks = false,
    AutoUpgradeFarm = false, AutoUpgradeSeedLuck = false, AutoUpgradeSeedRolls = false,
    AutoPlotUpgrades = false, PlotUpgradeFloor = "All Floors", PlotUpgradePriority = "Yield > Soil > Power > Sprinkler > Saw",
    AutoDailyRewards = false, AutoPlaytimeRewards = false,
    AutoUpgradePets = false, AutoSellPets = false,
    AutoPlantRush = false, AutoClaimPlantRushDrops = false, PlantRushShootDelay = 0.15,
    AntiAFK = true, BlockRobuxPopups = true,
    AutoCollectHoneycombs = false, AutoInsertHoneyToken = false, HoneycombDelay = 1,
    AutoGroupReward = false, AutoRedeemCodes = false,
    AutoBuyGear = false, SelectedGear = "Super Fertilizer", GearBuyDelay = 5, BuyAllGear = false,
    AutoHatchEggs = false, SelectedEggPodium = 1, HatchAllPodiums = false, HatchDelay = 3,
    AutoCollectAlienDrops = false, AlienDelay = 1,
}

-- Global flag
if getgenv then
    local prev = getgenv().VeltrxyRingFarm
    if prev then prev.alive = false end
    getgenv().VeltrxyRingFarm = { alive = true, started = tick(), config = Config }
end

local function alive()
    return getgenv and getgenv().VeltrxyRingFarm and getgenv().VeltrxyRingFarm.alive
end

-- Helper functions
local function invoke(remote, ...)
    if not remote then return nil end
    local ok, a = pcall(function(...) return remote:InvokeServer(...) end, ...)
    return ok and a or nil
end
local function fire(remote, ...)
    if not remote then return false end
    return pcall(function(...) remote:FireServer(...) end, ...)
end
local function snapshot()
    if not Replicator then return nil end
    local ok, data = pcall(function() return Replicator:Snapshot() end)
    return ok and data or nil
end

-- ========== GAME LOGIC FUNCTIONS (unchanged) ==========
local cachedPlot, lastPlotFetch
local function getPlot(force)
    if cachedPlot and cachedPlot.Parent and not force and tick() - (lastPlotFetch or 0) < 10 then return cachedPlot end
    if Services.GetPlot then
        local p = invoke(Services.GetPlot)
        if typeof(p) == "Instance" then cachedPlot, lastPlotFetch = p, tick(); return p end
    end
    return cachedPlot
end
local function getCharacter() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function getRoot() return getCharacter():FindFirstChild("HumanoidRootPart") end
local function getDirtPlots(opts)
    opts = opts or {}
    local plot = getPlot()
    local list = {}
    if not plot then return list end
    for _, floor in ipairs(plot:GetChildren()) do
        if floor:IsA("Model") and floor.Name:match("^Floor%d+$") then
            local farmPlot = floor:FindFirstChild("FarmPlot") or floor
            for _, model in ipairs(farmPlot:GetChildren()) do
                if model:IsA("Model") and model.Name:match("^Plot%d+$") then
                    local dirt = model:FindFirstChild("Dirt")
                    if dirt and dirt:IsA("BasePart") then
                        local unlocked = model:GetAttribute("Unlocked")
                        local plantName = dirt:GetAttribute("PlantName")
                        if opts.empty and plantName then continue end
                        if opts.planted and not plantName then continue end
                        if opts.locked and unlocked ~= false then continue end
                        if not opts.locked and unlocked == false then continue end
                        table.insert(list, dirt)
                    end
                end
            end
        end
    end
    return list
end
local function nearest(list)
    local root = getRoot()
    if not root then return list[1] end
    table.sort(list, function(a, b) return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude end)
    return list[1]
end
local function getSeedTools()
    local list = {}
    local function scan(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local plant = tool:GetAttribute("Plant") or tool:GetAttribute("Seed") or tool.Name:gsub(" Seed","")
                if plant then table.insert(list, { tool = tool, plant = plant }) end
            end
        end
    end
    scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
    scan(LocalPlayer.Character)
    return list
end
local function chooseSeedTool()
    local tools = getSeedTools()
    if #tools == 0 then return nil end
    if Config.AutoPlantMode == "Selected Seed" then
        for _, e in ipairs(tools) do if e.plant == Config.SelectedSeed then return e.tool, e.plant end end
    end
    table.sort(tools, function(a, b)
        local pA = tonumber(a.tool:GetAttribute("Price") or 0)
        local pB = tonumber(b.tool:GetAttribute("Price") or 0)
        if Config.AutoPlantMode == "Fastest Grow" then
            return (tonumber(a.tool:GetAttribute("StageGrowTime") or 999)) < (tonumber(b.tool:GetAttribute("StageGrowTime") or 999))
        elseif Config.AutoPlantMode == "Best ROI" then
            local cA = tonumber(a.tool:GetAttribute("Cost") or 0)
            local cB = tonumber(b.tool:GetAttribute("Cost") or 0)
            return (pA / math.max(1,cA)) > (pB / math.max(1,cB))
        else return pA > pB end
    end)
    return tools[1].tool, tools[1].plant
end
local function plantOnce()
    local dirt = nearest(getDirtPlots({ empty = true }))
    if not dirt then return false end
    local tool, plant = chooseSeedTool()
    if not tool then return false end
    pcall(function() LocalPlayer.Character.Humanoid:EquipTool(tool) end)
    fire(Services.PlantSeed, dirt)
    return true
end
local function upgradePlantsOnce()
    for _, dirt in ipairs(getDirtPlots({ planted = true })) do invoke(Services.UpgradePlant, dirt) task.wait(0.05) end
end
local function unlockPlotsOnce()
    for _, dirt in ipairs(getDirtPlots({ locked = true })) do fire(Services.UnlockPlot, dirt) task.wait(0.08) end
end
local PlotUpgradeOrders = {
    ["Yield > Soil > Power > Sprinkler > Saw"] = {"ExtraYield","SoilQuality","ExtraPower","ExtraSprinklerRange","ExtraSawRange"},
    ["Soil > Yield > Power"] = {"SoilQuality","ExtraYield","ExtraPower","ExtraSprinklerRange","ExtraSawRange"},
    ["Sprinkler > Power > Yield"] = {"ExtraSprinklerRange","ExtraPower","ExtraYield","SoilQuality","ExtraSawRange"},
    ["Saw > Yield > Soil"] = {"ExtraSawRange","ExtraYield","SoilQuality","ExtraSprinklerRange","ExtraPower"},
}
local function plotUpgradeOnce()
    local floors = Config.PlotUpgradeFloor == "All Floors" and {"Floor1","Floor2","Floor3","Floor4","Floor5"} or {Config.PlotUpgradeFloor}
    local order = PlotUpgradeOrders[Config.PlotUpgradePriority] or PlotUpgradeOrders["Yield > Soil > Power > Sprinkler > Saw"]
    for _, floor in ipairs(floors) do
        for _, upgrade in ipairs(order) do invoke(Services.PlotUpgradeTransaction, upgrade, floor) task.wait(0.05) end
    end
end
local function claimPlaytimeRewards()
    local state = invoke(Services.GetPlaytimeRewardState)
    local claimed = type(state) == "table" and state.ClaimedMap or {}
    for i = 1, 20 do if not claimed[tostring(i)] then invoke(Services.ClaimPlaytimeReward, i) task.wait(0.05) end end
end
local function claimDailyRewards()
    for i = 1, 14 do invoke(Services.ClaimDailyReward, i) task.wait(0.05) end
end
local function openSeedPackOnce() fire(Services.RequestOpenSeedPack) task.wait(0.25) fire(Services.SeedPackOpenFinished) end
local function buyRolledSeedsOnce() for slot = 1, 6 do fire(Services.BuySeed, slot) task.wait(0.08) end end
local function autoUpgradePetsOnce()
    local data = snapshot()
    local inv = data and data.PetInventory
    if type(inv) ~= "table" then return end
    for key in pairs(inv) do invoke(Services.UpgradePet, key) task.wait(0.08) end
end
local function autoSellPetsOnce()
    local data = snapshot()
    local inv = data and data.PetInventory
    local equipped = data and data.EquippedPets or {}
    if type(inv) ~= "table" then return end
    local equippedMap = {}
    for _, key in ipairs(equipped) do equippedMap[key] = true end
    for key, pet in pairs(inv) do
        local name = type(pet) == "table" and pet.Name
        if not equippedMap[key] then invoke(Services.SellPet, key) task.wait(0.1) end
    end
end
local function plantRushShootOnce()
    local targets = {}
    local folder = workspace:FindFirstChild("InteractiveEvents") or workspace
    folder = folder:FindFirstChild("PlantRush") or folder
    for _, inst in ipairs(folder:GetDescendants()) do
        if inst:IsA("Model") and inst:GetAttribute("PlantRushId") then
            local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
            if part then table.insert(targets, {part=part, id=inst:GetAttribute("PlantRushId")}) end
        elseif inst:IsA("BasePart") and inst:GetAttribute("PlantRushId") then
            table.insert(targets, {part=inst, id=inst:GetAttribute("PlantRushId")})
        end
    end
    if #targets == 0 then return false end
    local root = getRoot()
    if root then table.sort(targets, function(a,b) return (a.part.Position-root.Position).Magnitude < (b.part.Position-root.Position).Magnitude end) end
    fire(Services.PlantRushShoot, targets[1].part.Position, targets[1].id, workspace:GetServerTimeNow())
    return true
end
local function claimPlantRushDrops()
    local folder = workspace:FindFirstChild("InteractiveEvents") or workspace
    folder = folder:FindFirstChild("PlantRush") or folder
    for _, inst in ipairs(folder:GetDescendants()) do
        local dropId = inst:GetAttribute("DropId") or inst:GetAttribute("PlantRushDropId")
        if dropId then fire(Services.PlantRushDropClaim, dropId) task.wait(0.05) end
    end
end
local function collectHoneycombsOnce()
    local root = getRoot() if not root then return 0 end
    local folder = workspace:FindFirstChild("QueenBee") or workspace:FindFirstChild("InteractiveEvents"):FindFirstChild("QueenBee")
    if not folder then return 0 end
    local combs = {}
    for _, inst in ipairs(folder:GetDescendants()) do
        if (inst:IsA("BasePart") or inst:IsA("Model")) and (inst:GetAttribute("HoneycombId") or inst.Name:lower():find("honeycomb")) then
            table.insert(combs, inst)
        end
    end
    if #combs == 0 then return 0 end
    local origin = root.CFrame
    for _, comb in ipairs(combs) do
        local pos = comb:IsA("Model") and comb:GetPivot().Position or comb.Position
        pcall(function() root.CFrame = CFrame.new(pos) end) task.wait(0.15)
    end
    pcall(function() root.CFrame = origin end)
    return #combs
end
local function insertHoneyTokenOnce()
    local root = getRoot() if not root then return false end
    local folder = workspace:FindFirstChild("QueenBee") or workspace:FindFirstChild("InteractiveEvents"):FindFirstChild("QueenBee")
    if not folder then return false end
    local machine = folder:FindFirstChild("HoneyJarMachine", true) or folder:FindFirstChild("Honey Jar Machine", true)
    if not machine then return false end
    local origin = root.CFrame
    pcall(function() root.CFrame = CFrame.new(machine:GetPivot().Position + Vector3.new(0,3,0)) end)
    task.wait(0.5)
    for _, d in ipairs(machine:GetDescendants()) do if d:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(d) end) end end
    task.wait(0.3)
    pcall(function() root.CFrame = origin end)
    return true
end
local function collectAlienDropsOnce()
    local root = getRoot() if not root then return 0 end
    local folder = workspace:FindFirstChild("AlienInvasion") or workspace:FindFirstChild("InteractiveEvents"):FindFirstChild("AlienInvasion")
    if not folder then return 0 end
    local drops = {}
    for _, inst in ipairs(folder:GetDescendants()) do
        if (inst:IsA("BasePart") or inst:IsA("Model")) and inst:GetAttribute("DropId") then table.insert(drops, inst) end
    end
    if #drops == 0 then return 0 end
    local origin = root.CFrame
    for _, drop in ipairs(drops) do
        local pos = drop:IsA("Model") and drop:GetPivot().Position or drop.Position
        pcall(function() root.CFrame = CFrame.new(pos) end) task.wait(0.15)
    end
    pcall(function() root.CFrame = origin end)
    return #drops
end
local function redeemCodesOnce()
    local codes = {"RELEASE","UPDATE","FREE","SORRY","SHUTDOWN","LIKES","RING","FARM"}
    for _, code in ipairs(codes) do invoke(Services.SubmitCode, code) task.wait(0.5) end
end
local function claimGroupRewardOnce() invoke(Services.GroupReward) end
local function hatchEggOnce(podium)
    if not Services.EggShopTransaction then return false end
    local success, _, eggName = invoke(Services.EggShopTransaction, "BuyEgg", podium)
    if success and Services.RollEgg and type(eggName)=="string" then fire(Services.RollEgg, eggName) end
    return success
end
local function autoHatchOnce()
    if Config.HatchAllPodiums then for p=1,5 do hatchEggOnce(p) task.wait(0.3) end
    else hatchEggOnce(Config.SelectedEggPodium) end
end
local GEAR_ITEMS = {"Normal Fertilizer","Strong Fertilizer","Super Fertilizer","Normal Pet Treat","Strong Pet Treat","Super Pet Treat","Radioactive Spray","Void Spray","Cosmic Spray","Rainbow Spray"}
local function buyGearOnce(name)
    if not Services.GearTransaction then return false end
    return invoke(Services.GearTransaction, name or Config.SelectedGear) ~= nil
end

-- ========== WINDOW ==========
local Window = Library:AddWindow("Veltrxy", "rbxassetid://120340008923813", "Build A Ring Farm")

-- We'll store all toggles here to support Master Auto
local allToggles = {}

-- Helper to create a button-like toggle
local function addActionButton(section, text, callback)
    local btn = section:AddToggle(text, false, function(v)
        if v then
            callback()
            btn:Set(false)  -- reset immediately
        end
    end)
    return btn
end

-- ========== TABS ==========
local FarmingTab = Window:AddTab("Farming", "farm")
local SeedsTab = Window:AddTab("Seeds", "egg")
local UpgradesTab = Window:AddTab("Upgrades", "gear")
local PetsTab = Window:AddTab("Pets", "user")
local EventsTab = Window:AddTab("Events", "sun")
local RewardsTab = Window:AddTab("Rewards", "shop")
local SettingsTab = Window:AddTab("Settings", "gear")  -- gear icon reused

-- ========== FARMING TAB ==========
local MasterSection = FarmingTab:AddSection("MASTER", "left")
local masterToggle = MasterSection:AddToggle("Auto Farm Everything", false, function(v)
    for _, t in pairs(allToggles) do
        pcall(function() t:Set(v) end)
    end
end)

local FarmSection = FarmingTab:AddSection("SMART FARM", "left")
allToggles.AutoPlant = FarmSection:AddToggle("Auto Plant", false, function(v) Config.AutoPlant = v end)
FarmSection:AddDropdown("Plant Mode", {"Best Value","Best ROI","Fastest Grow","Rarest Owned","Selected Seed"}, function(v) Config.AutoPlantMode = v end)
allToggles.AutoUpgradePlants = FarmSection:AddToggle("Auto Upgrade Plants", false, function(v) Config.AutoUpgradePlants = v end)
allToggles.AutoUnlockPlots = FarmSection:AddToggle("Auto Unlock Plots", false, function(v) Config.AutoUnlockPlots = v end)

local SellSection = FarmingTab:AddSection("CRATES / SELLING", "right")
allToggles.AutoSellCrates = SellSection:AddToggle("Auto Sell Crates", false, function(v) Config.AutoSellCrates = v end)
addActionButton(SellSection, "Sell Now", function() fire(Services.SellCrates) end)

-- ========== SEEDS TAB ==========
local RollSection = SeedsTab:AddSection("SEED ROLLER", "left")
allToggles.AutoRollSeeds = RollSection:AddToggle("Auto Roll Seeds", false, function(v) Config.AutoRollSeeds = v end)
RollSection:AddSlider("Roll Delay", 0.25, 10, 1, function(v) Config.RollDelay = v end, "s")
allToggles.AutoBuyRolledSeed = RollSection:AddToggle("Auto Buy Rolled Seeds", false, function(v) Config.AutoBuyRolledSeed = v end)
allToggles.AutoOpenSeedPacks = RollSection:AddToggle("Auto Open Seed Packs", false, function(v) Config.AutoOpenSeedPacks = v end)
addActionButton(RollSection, "Roll Now", function() fire(Services.RollSeeds) end)
addActionButton(RollSection, "Buy Rolled Now", function() buyRolledSeedsOnce() end)
addActionButton(RollSection, "Open Pack Now", function() openSeedPackOnce() end)

-- ========== UPGRADES TAB ==========
local CoreSection = UpgradesTab:AddSection("CORE UPGRADES", "left")
allToggles.AutoUpgradeFarm = CoreSection:AddToggle("Auto Upgrade Farm", false, function(v) Config.AutoUpgradeFarm = v end)
allToggles.AutoUpgradeSeedLuck = CoreSection:AddToggle("Auto Upgrade Seed Luck", false, function(v) Config.AutoUpgradeSeedLuck = v end)
allToggles.AutoUpgradeSeedRolls = CoreSection:AddToggle("Auto Upgrade Seed Rolls", false, function(v) Config.AutoUpgradeSeedRolls = v end)
addActionButton(CoreSection, "Upgrade All Now", function() invoke(Services.UpgradeFarm); invoke(Services.UpgradeSeedLuck); invoke(Services.UpgradeSeedRolls) end)

local PlotSection = UpgradesTab:AddSection("PLOT UPGRADES", "right")
allToggles.AutoPlotUpgrades = PlotSection:AddToggle("Auto Plot Upgrades", false, function(v) Config.AutoPlotUpgrades = v end)
PlotSection:AddDropdown("Floor", {"All Floors","Floor1","Floor2","Floor3","Floor4","Floor5"}, function(v) Config.PlotUpgradeFloor = v end)
PlotSection:AddDropdown("Priority", {"Yield > Soil > Power > Sprinkler > Saw","Soil > Yield > Power","Sprinkler > Power > Yield","Saw > Yield > Soil"}, function(v) Config.PlotUpgradePriority = v end)
addActionButton(PlotSection, "Upgrade Plots Now", function() plotUpgradeOnce() end)

-- ========== PETS TAB ==========
local PetSection = PetsTab:AddSection("PET AUTOMATION", "left")
allToggles.AutoUpgradePets = PetSection:AddToggle("Auto Upgrade Pets", false, function(v) Config.AutoUpgradePets = v end)
allToggles.AutoSellPets = PetSection:AddToggle("Auto Sell Common/Rare Pets", false, function(v) Config.AutoSellPets = v end)
addActionButton(PetSection, "Upgrade Pets Now", function() autoUpgradePetsOnce() end)
addActionButton(PetSection, "Sell Low Pets Now", function() autoSellPetsOnce() end)

local EggSection = PetsTab:AddSection("EGG HATCHING", "right")
allToggles.AutoHatchEggs = EggSection:AddToggle("Auto Hatch Eggs", false, function(v) Config.AutoHatchEggs = v end)
EggSection:AddDropdown("Egg Podium", {"1","2","3","4","5"}, function(v) Config.SelectedEggPodium = tonumber(v) or 1 end)
EggSection:AddToggle("Hatch All Podiums", false, function(v) Config.HatchAllPodiums = v end)
EggSection:AddSlider("Hatch Delay", 1, 30, 3, function(v) Config.HatchDelay = v end, "s")
addActionButton(EggSection, "Hatch Now", function() autoHatchOnce() end)

-- ========== EVENTS TAB ==========
local RushSection = EventsTab:AddSection("PLANT RUSH", "left")
allToggles.AutoPlantRush = RushSection:AddToggle("Auto Shoot", false, function(v) Config.AutoPlantRush = v end)
allToggles.AutoClaimPlantRushDrops = RushSection:AddToggle("Auto Claim Drops", false, function(v) Config.AutoClaimPlantRushDrops = v end)
RushSection:AddSlider("Shoot Delay", 0.05, 2, 0.15, function(v) Config.PlantRushShootDelay = v end, "s")
addActionButton(RushSection, "Shoot Now", function() plantRushShootOnce() end)
addActionButton(RushSection, "Claim Drops Now", function() claimPlantRushDrops() end)

local HoneySection = EventsTab:AddSection("QUEEN BEE", "right")
allToggles.AutoCollectHoneycombs = HoneySection:AddToggle("Auto Collect Honeycombs", false, function(v) Config.AutoCollectHoneycombs = v end)
allToggles.AutoInsertHoneyToken = HoneySection:AddToggle("Auto Insert Honey Token", false, function(v) Config.AutoInsertHoneyToken = v end)
HoneySection:AddSlider("Collect Delay", 0.25, 10, 1, function(v) Config.HoneycombDelay = v end, "s")
addActionButton(HoneySection, "Collect Now", function() collectHoneycombsOnce() end)
addActionButton(HoneySection, "Insert Token Now", function() insertHoneyTokenOnce() end)

local AlienSection = EventsTab:AddSection("ALIEN INVASION", "left")
allToggles.AutoCollectAlienDrops = AlienSection:AddToggle("Auto Collect Alien Drops", false, function(v) Config.AutoCollectAlienDrops = v end)
AlienSection:AddSlider("Alien Delay", 0.25, 10, 1, function(v) Config.AlienDelay = v end, "s")
addActionButton(AlienSection, "Collect Now", function() collectAlienDropsOnce() end)

-- ========== REWARDS TAB ==========
local RewardSection = RewardsTab:AddSection("REWARD CLAIMING", "left")
allToggles.AutoDailyRewards = RewardSection:AddToggle("Auto Daily Rewards", false, function(v) Config.AutoDailyRewards = v end)
allToggles.AutoPlaytimeRewards = RewardSection:AddToggle("Auto Playtime Rewards", false, function(v) Config.AutoPlaytimeRewards = v end)
addActionButton(RewardSection, "Claim Daily Now", function() claimDailyRewards() end)
addActionButton(RewardSection, "Claim Playtime Now", function() claimPlaytimeRewards() end)

-- ========== SETTINGS TAB ==========
local SettingsSection = SettingsTab:AddSection("GENERAL", "left")
allToggles.AntiAFK = SettingsSection:AddToggle("Anti-AFK", true, function(v) Config.AntiAFK = v end)
allToggles.BlockRobuxPopups = SettingsSection:AddToggle("Block Robux Popups", true, function(v) Config.BlockRobuxPopups = v end)
allToggles.AutoGroupReward = SettingsSection:AddToggle("Auto Group Reward", false, function(v) Config.AutoGroupReward = v end)
allToggles.AutoRedeemCodes = SettingsSection:AddToggle("Auto Redeem Codes", false, function(v) Config.AutoRedeemCodes = v end)
addActionButton(SettingsSection, "Claim Group Now", function() claimGroupRewardOnce() end)
addActionButton(SettingsSection, "Redeem Codes Now", function() redeemCodesOnce() end)

-- ========== AUTOMATION LOOPS ==========
task.spawn(function() while alive() do task.wait(Config.PlantDelay) if Config.AutoPlant then pcall(plantOnce) end end end)
task.spawn(function() while alive() do task.wait(1.5) if Config.AutoUpgradePlants then pcall(upgradePlantsOnce) end if Config.AutoUnlockPlots then pcall(unlockPlotsOnce) end end end)
task.spawn(function() while alive() do task.wait(Config.SellDelay) if Config.AutoSellCrates then fire(Services.SellCrates) end end end)
task.spawn(function() while alive() do task.wait(Config.RollDelay) if Config.AutoRollSeeds then fire(Services.RollSeeds); if Config.AutoBuyRolledSeed then task.wait(2) pcall(buyRolledSeedsOnce) end elseif Config.AutoBuyRolledSeed then pcall(buyRolledSeedsOnce) end if Config.AutoOpenSeedPacks then pcall(openSeedPackOnce) end end end)
task.spawn(function() while alive() do task.wait(2) if Config.AutoUpgradeFarm then invoke(Services.UpgradeFarm) end if Config.AutoUpgradeSeedLuck then invoke(Services.UpgradeSeedLuck) end if Config.AutoUpgradeSeedRolls then invoke(Services.UpgradeSeedRolls) end if Config.AutoPlotUpgrades then pcall(plotUpgradeOnce) end end end)
task.spawn(function() while alive() do task.wait(10) if Config.AutoDailyRewards then pcall(claimDailyRewards) end if Config.AutoPlaytimeRewards then pcall(claimPlaytimeRewards) end end end)
task.spawn(function() while alive() do task.wait(5) if Config.AutoUpgradePets then pcall(autoUpgradePetsOnce) end if Config.AutoSellPets then pcall(autoSellPetsOnce) end end end)
task.spawn(function() while alive() do task.wait(Config.PlantRushShootDelay) if Config.AutoPlantRush then pcall(plantRushShootOnce) end end end)
task.spawn(function() while alive() do task.wait(1) if Config.AutoClaimPlantRushDrops then pcall(claimPlantRushDrops) end end end)
task.spawn(function() while alive() do task.wait(Config.HoneycombDelay) if Config.AutoCollectHoneycombs then pcall(collectHoneycombsOnce) end if Config.AutoInsertHoneyToken then pcall(insertHoneyTokenOnce) end end end)
task.spawn(function() while alive() do if Config.AutoGroupReward then pcall(claimGroupRewardOnce) end if Config.AutoRedeemCodes then Config.AutoRedeemCodes = false; pcall(redeemCodesOnce) end task.wait(30) end end)
task.spawn(function() while alive() do task.wait(Config.HatchDelay) if Config.AutoHatchEggs then pcall(autoHatchOnce) end end end)
task.spawn(function() while alive() do task.wait(Config.AlienDelay) if Config.AutoCollectAlienDrops then pcall(collectAlienDropsOnce) end end end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
    end
end)

-- Robux popup blocker
if Config.BlockRobuxPopups then
    task.spawn(function()
        while alive() do
            pcall(function()
                for _, gui in ipairs(CoreGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui.Name:lower():find("purchase") then gui.Enabled = false end
                end
            end)
            task.wait(1)
        end
    end)
end

print("Veltrxy Hub loaded with Neverlose UI")
