-- Keybinds:
--   -          = left indicator
--   =          = right indicator
--   Backspace  = hazards
--   G          = engine on/off
--
-- Instant toggle — no cooldown / debounce.

local KEY_BACK = 0x08      -- Backspace
local KEY_G = 0x47         -- G
local KEY_MINUS = 0xBD     -- -
local KEY_EQUALS = 0xBB    -- =

local state = {
    left = false,
    right = false,
    hazard = false,
    engineForcedOff = false,
    vehicle = 0,
}

local wasDown = {}

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

local function keyJustPressed(key)
    local down = IsRawKeyPressed(key)
    if down and not wasDown[key] then
        wasDown[key] = true
        return true
    end
    if not down then
        wasDown[key] = false
    end
    return false
end

local function getDriverVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return 0
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return 0
    end

    return vehicle
end

local function broadcastState()
    local payload = {
        left = state.left,
        right = state.right,
        hazard = state.hazard,
        engineForcedOff = state.engineForcedOff,
    }
    TriggerEvent('indicators:state', payload)
    LocalPlayer.state:set('indicators', payload, false)
end

local function applyIndicators(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    SetVehicleIndicatorLights(vehicle, 0, state.left or state.hazard)
    SetVehicleIndicatorLights(vehicle, 1, state.right or state.hazard)
    broadcastState()
end

local function clearIndicators(vehicle)
    state.left = false
    state.right = false
    state.hazard = false

    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleIndicatorLights(vehicle, 0, false)
        SetVehicleIndicatorLights(vehicle, 1, false)
    end
    broadcastState()
end

local function toggleLeft(vehicle)
    state.hazard = false
    state.left = not state.left
    state.right = false
    applyIndicators(vehicle)
    notify(state.left and 'Left indicator ~g~ON' or 'Left indicator ~r~OFF')
end

local function toggleRight(vehicle)
    state.hazard = false
    state.right = not state.right
    state.left = false
    applyIndicators(vehicle)
    notify(state.right and 'Right indicator ~g~ON' or 'Right indicator ~r~OFF')
end

local function toggleHazard(vehicle)
    state.hazard = not state.hazard
    state.left = false
    state.right = false
    applyIndicators(vehicle)
    notify(state.hazard and 'Hazards ~g~ON' or 'Hazards ~r~OFF')
end

local function toggleEngine(vehicle)
    if state.engineForcedOff or not GetIsVehicleEngineRunning(vehicle) then
        state.engineForcedOff = false
        SetVehicleEngineOn(vehicle, true, true, false)
        notify('Engine ~g~ON')
    else
        state.engineForcedOff = true
        SetVehicleEngineOn(vehicle, false, true, true)
        notify('Engine ~r~OFF')
    end
    broadcastState()
end

exports('GetIndicatorState', function()
    return {
        left = state.left,
        right = state.right,
        hazard = state.hazard,
        engineForcedOff = state.engineForcedOff,
    }
end)

CreateThread(function()
    while true do
        local vehicle = getDriverVehicle()

        if vehicle ~= 0 then
            if state.vehicle ~= 0 and state.vehicle ~= vehicle then
                clearIndicators(state.vehicle)
                state.engineForcedOff = false
            end
            state.vehicle = vehicle

            -- Instant key edges — re-press anytime, no cooldown
            if keyJustPressed(KEY_MINUS) then
                toggleLeft(vehicle)
            elseif keyJustPressed(KEY_EQUALS) then
                toggleRight(vehicle)
            elseif keyJustPressed(KEY_BACK) then
                toggleHazard(vehicle)
            elseif keyJustPressed(KEY_G) then
                toggleEngine(vehicle)
            end

            if state.left or state.right or state.hazard then
                applyIndicators(vehicle)
            end

            if state.engineForcedOff then
                SetVehicleEngineOn(vehicle, false, true, true)
            end

            Wait(0)
        else
            if state.vehicle ~= 0 then
                clearIndicators(state.vehicle)
                state.vehicle = 0
                state.engineForcedOff = false
            end
            wasDown = {}
            Wait(200)
        end
    end
end)
