--[[
    Location HUD — auto-starts for every player.
    No commands, no ACE permissions required.
]]

local isOpen = false
local nuiReady = false
local lastPayload = nil

local CARDINALS = {
    'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'
}

local function pushVisible(show)
    isOpen = show
    if nuiReady then
        SendNUIMessage({ action = 'visible', show = show })
    end
end

local function setVisible(show)
    if isOpen == show and nuiReady then
        return
    end
    pushVisible(show)
end

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    cb({ ok = true })
    SendNUIMessage({ action = 'visible', show = isOpen })
    lastPayload = nil
end)

local function headingToCardinal(heading)
    local idx = math.floor(((heading % 360) + 22.5) / 45) % 8
    return CARDINALS[idx + 1]
end

local function getStreetNames(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash) or ''
    local crossing = ''

    if crossingHash and crossingHash ~= 0 then
        crossing = GetStreetNameFromHashKey(crossingHash) or ''
    end

    if street == '' then
        street = 'Unknown Sector'
    end

    return street, crossing
end

local function sendLocation(data)
    if not nuiReady then
        return
    end

    local key = string.format(
        '%s|%s|%s|%d',
        data.street,
        data.crossing,
        data.cardinal,
        data.heading
    )

    if key == lastPayload then
        return
    end

    lastPayload = key
    SendNUIMessage({
        action = 'update',
        street = data.street,
        crossing = data.crossing,
        cardinal = data.cardinal,
        heading = data.heading,
    })
end

CreateThread(function()
    Wait(500)

    while true do
        local ped = PlayerPedId()

        if ped ~= 0 and DoesEntityExist(ped) and not IsPauseMenuActive() then
            setVisible(true)

            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local street, crossing = getStreetNames(coords)

            sendLocation({
                street = street,
                crossing = crossing,
                cardinal = headingToCardinal(heading),
                heading = math.floor(heading + 0.5) % 360,
            })

            Wait(200)
        else
            setVisible(false)
            lastPayload = nil
            Wait(400)
        end
    end
end)

CreateThread(function()
    while true do
        if isOpen then
            HideHudComponentThisFrame(7) -- Area Name
            HideHudComponentThisFrame(9) -- Street Name
            Wait(0)
        else
            Wait(250)
        end
    end
end)

CreateThread(function()
    Wait(3000)
    if not nuiReady then
        nuiReady = true
        SendNUIMessage({ action = 'visible', show = isOpen })
        lastPayload = nil
    end
end)
