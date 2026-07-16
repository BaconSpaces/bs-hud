local isOpen = false
local lastPayload = nil

local indicatorState = {
    left = false,
    right = false,
    hazard = false,
}

local function setVisible(show)
    if isOpen == show then
        return
    end
    isOpen = show
    SendNUIMessage({ action = 'visible', show = show })
end

local function sendHud(data)
    local key = string.format(
        '%d|%.2f|%s|%d|%d|%d|%d',
        data.speed,
        data.rpm,
        data.gear,
        data.engine and 1 or 0,
        data.left and 1 or 0,
        data.right and 1 or 0,
        data.hazard and 1 or 0
    )
    if key == lastPayload then
        return
    end
    lastPayload = key
    SendNUIMessage({
        action = 'update',
        speed = data.speed,
        rpm = data.rpm,
        gear = data.gear,
        engine = data.engine,
        left = data.left,
        right = data.right,
        hazard = data.hazard,
    })
end

local function getDisplayGear(vehicle, speedMph)
    if not GetIsVehicleEngineRunning(vehicle) then
        return 'P'
    end

    local speedVec = GetEntitySpeedVector(vehicle, true)
    if speedVec.y < -1.0 and speedMph > 0 then
        return 'R'
    end

    local gear = GetVehicleCurrentGear(vehicle)
    if gear == 0 then
        return 'N'
    end

    return tostring(gear)
end

local function readIndicators(vehicle)
    local ok, exported = pcall(function()
        return exports['indicators']:GetIndicatorState()
    end)

    if ok and type(exported) == 'table' then
        return {
            left = exported.left and true or false,
            right = exported.right and true or false,
            hazard = exported.hazard and true or false,
        }
    end

    if indicatorState.left or indicatorState.right or indicatorState.hazard then
        return {
            left = indicatorState.left,
            right = indicatorState.right,
            hazard = indicatorState.hazard,
        }
    end

    local lights = GetVehicleIndicatorLights(vehicle) or 0
    return {
        left = lights == 1 or lights == 3,
        right = lights == 2 or lights == 3,
        hazard = lights == 3,
    }
end

AddEventHandler('indicators:state', function(payload)
    if type(payload) ~= 'table' then
        return
    end
    indicatorState.left = payload.left and true or false
    indicatorState.right = payload.right and true or false
    indicatorState.hazard = payload.hazard and true or false
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 then
            setVisible(true)

            local speedMph = math.floor(GetEntitySpeed(vehicle) * 2.236936 + 0.5)
            local rpm = GetVehicleCurrentRpm(vehicle)
            local ind = readIndicators(vehicle)

            sendHud({
                speed = speedMph,
                rpm = rpm,
                gear = getDisplayGear(vehicle, speedMph),
                engine = GetIsVehicleEngineRunning(vehicle),
                left = ind.left or ind.hazard,
                right = ind.right or ind.hazard,
                hazard = ind.hazard,
            })

            Wait(50)
        else
            setVisible(false)
            lastPayload = nil
            indicatorState.left = false
            indicatorState.right = false
            indicatorState.hazard = false
            Wait(350)
        end
    end
end)
