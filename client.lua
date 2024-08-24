local IsDead = false
local CanRespawn = false
local CanRevive = false

local DeathMessageSent = false
local ReviveMessageSent = false
local RespawnMessageSent = false

local CurrentCount = 0

function Revive(Location)
    local LocalPed = PlayerPedId()

    if Location then
        NetworkResurrectLocalPlayer(vector3(Location))
    else
        NetworkResurrectLocalPlayer(GetEntityCoords(LocalPed, true)) 
    end
end

function GetClosestHospital()
    local ClosestCoord = nil
    local ClosestDistance = math.huge

    local LocalPed = GetPlayerPed(-1)
    local LocalCoords = GetEntityCoords(LocalPed)

    for _, Coord in pairs(Config.Hospitals) do
        local Distance = #(LocalCoords - Coord)

        if Distance < ClosestDistance then
            ClosestDistance = Distance
            ClosestCoord = Coord
        end
    end

    return ClosestCoord
end

function DisplayChatMessage(Title, Message)
    TriggerEvent('chat:addMessage', {
        color = {230, 17, 17},
        multiline = true,
        args = {Title, Message}
    })
end

function GetRandomSpawn()
    return Config.Spawns[math.random(#Config.Spawns)]
end

function GetRandomPed()
    return Config.Peds[math.random(#Config.Peds)]
end

AddEventHandler('onClientMapStart', function()
    local SpawnCoords = GetRandomSpawn()
    local RandomPed = GetRandomPed()

    exports.spawnmanager:spawnPlayer({x = SpawnCoords.x, y = SpawnCoords.y, z = SpawnCoords.z, model = GetRandomPed()})
    exports.spawnmanager:setAutoSpawn(false)
    exports.spawnmanager:forceRespawn()
end)

RegisterCommand('revive', function(Source, Args)
    if not IsDead then return end

    if CurrentCount > Config.Durations.Revive then
        Revive()
        DisplayChatMessage('Spawn System', 'You have been successfully revived!')
    else
        DisplayChatMessage('Spawn System', 'You have ' .. Config.Durations.Revive - CurrentCount .. ' seconds remaining!')
    end
end, false)

RegisterCommand('respawn', function(Source, Args)
    if not IsDead then return end

    if CurrentCount > Config.Durations.Respawn then
        Revive(GetClosestHospital())
        DisplayChatMessage('Spawn System', 'You have been successfully respawned!')
    else
        DisplayChatMessage('Spawn System', 'You have ' .. Config.Durations.Respawn - CurrentCount .. ' seconds remaining!')
    end
end, false)

Citizen.CreateThread(function()
    while true do
        if IsEntityDead(PlayerPedId()) then
            IsDead = true
            CurrentCount = CurrentCount + 1

            if not DeathMessageSent then
                DeathMessageSent = true
                DisplayChatMessage('Spawn System', 'You have died. Respawn in ' .. Config.Durations.Respawn .. ' seconds or revive in ' .. Config.Durations.Revive .. ' seconds.')
            end

            if not ReviveMessageSent and CurrentCount > Config.Durations.Revive then
                ReviveMessageSent = true
                DisplayChatMessage('Spawn System', 'You are now able to revive. Type /revive to revive yourself.')
            end

            if not RespawnMessageSent and CurrentCount > Config.Durations.Respawn then
                RespawnMessageSent = true
                DisplayChatMessage('Spawn System', 'You are now able to respawn. Type /respawn to respawn yourself.')
            end
        else
            IsDead = false
            ReviveMessageSent = false
            RespawnMessageSent = false
            CurrentCount = 0
        end

        Citizen.Wait(1000)
    end
end)