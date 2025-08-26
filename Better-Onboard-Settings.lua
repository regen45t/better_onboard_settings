local repeatButton = true
local configFile = ac.getFolder(ac.FolderID.ACApps) .. "/lua/Better-Onboard-Settings/config.ini"

-- Simple hash function to create consistent section names from car names
function hashCarName(carName)
    local hash = 0
    for i = 1, #carName do
        hash = ((hash * 31) + string.byte(carName, i)) % 1000000
    end
    return "CAR_" .. hash
end

-- Function to save current settings to a global preset
function saveGlobalPreset(presetNumber)
    local onboardCameraParams = ac.getOnboardCameraParams(0)
    local cameraFov = ac.getSim().cameraFOV
    
    local config = ac.INIConfig.load(configFile)
    local sectionName = "GLOBAL_PRESET_" .. presetNumber
    
    config:set(sectionName, "FOV", cameraFov)
    config:set(sectionName, "POSITION_X", onboardCameraParams.position.x)
    config:set(sectionName, "POSITION_Y", onboardCameraParams.position.y)
    config:set(sectionName, "POSITION_Z", onboardCameraParams.position.z)
    config:set(sectionName, "PITCH", onboardCameraParams.pitch)
    config:set(sectionName, "YAW", onboardCameraParams.yaw)
    config:set(sectionName, "NAME", "Global " .. presetNumber)
    
    config:save()
end

-- Function to save current settings to a car-specific preset
function saveCarPreset(presetNumber)
    local onboardCameraParams = ac.getOnboardCameraParams(0)
    local cameraFov = ac.getSim().cameraFOV
    local carName = ac.getCarName(0)
    
    local config = ac.INIConfig.load(configFile)
    local carHash = hashCarName(carName)
    local sectionName = carHash .. "_PRESET_" .. presetNumber
    
    config:set(sectionName, "FOV", cameraFov)
    config:set(sectionName, "POSITION_X", onboardCameraParams.position.x)
    config:set(sectionName, "POSITION_Y", onboardCameraParams.position.y)
    config:set(sectionName, "POSITION_Z", onboardCameraParams.position.z)
    config:set(sectionName, "PITCH", onboardCameraParams.pitch)
    config:set(sectionName, "YAW", onboardCameraParams.yaw)
    config:set(sectionName, "CAR_NAME", carName)
    
    config:save()
end

-- Function to load settings from a global preset
function loadGlobalPreset(presetNumber)
    local config = ac.INIConfig.load(configFile)
    local sectionName = "GLOBAL_PRESET_" .. presetNumber
    
    local fov = config:get(sectionName, "FOV", 30)
    local posX = config:get(sectionName, "POSITION_X", 0.0)
    local posY = config:get(sectionName, "POSITION_Y", 2.5)
    local posZ = config:get(sectionName, "POSITION_Z", -5)
    local pitch = config:get(sectionName, "PITCH", -7.5)
    local yaw = config:get(sectionName, "YAW", 0.0)

    local newOnboardCameraParams = ac.getOnboardCameraParams(0)
    newOnboardCameraParams.position.x = posX
    newOnboardCameraParams.position.y = posY
    newOnboardCameraParams.position.z = posZ
    newOnboardCameraParams.pitch = pitch
    newOnboardCameraParams.yaw = yaw
    
    -- Apply the loaded settings
    ac.setFirstPersonCameraFOV(fov)
    ac.setOnboardCameraParams(0, newOnboardCameraParams, true)
end

-- Function to load settings from a car-specific preset
function loadCarPreset(presetNumber)
    local carName = ac.getCarName(0)
    local config = ac.INIConfig.load(configFile)
    local carHash = hashCarName(carName)
    local sectionName = carHash .. "_PRESET_" .. presetNumber
    
    local fov = config:get(sectionName, "FOV", 30)
    local posX = config:get(sectionName, "POSITION_X", 0.0)
    local posY = config:get(sectionName, "POSITION_Y", 2.5)
    local posZ = config:get(sectionName, "POSITION_Z", -5)
    local pitch = config:get(sectionName, "PITCH", -7.5)
    local yaw = config:get(sectionName, "YAW", 0.0)

    local newOnboardCameraParams = ac.getOnboardCameraParams(0)
    newOnboardCameraParams.position.x = posX
    newOnboardCameraParams.position.y = posY
    newOnboardCameraParams.position.z = posZ
    newOnboardCameraParams.pitch = pitch
    newOnboardCameraParams.yaw = yaw
    
    -- Apply the loaded settings
    ac.setFirstPersonCameraFOV(fov)
    ac.setOnboardCameraParams(0, newOnboardCameraParams, true)
end

-- Function to get global preset name
function getGlobalPresetName(presetNumber)
    local config = ac.INIConfig.load(configFile)
    local sectionName = "GLOBAL_PRESET_" .. presetNumber
    return config:get(sectionName, "NAME", "Global " .. presetNumber)
end

-- Function to reset global presets from defaults
function resetGlobalPresets()
    local globalDefaultsFile = ac.getFolder(ac.FolderID.ACApps) .. "/lua/Better-Onboard-Settings/global_defaults.ini"
    local globalDefaults = ac.INIConfig.load(globalDefaultsFile)
    local config = ac.INIConfig.load(configFile)
    
    for i = 1, 5 do
        local sectionName = "GLOBAL_PRESET_" .. i
        config:set(sectionName, "FOV", globalDefaults:get(sectionName, "FOV", 30))
        config:set(sectionName, "POSITION_X", globalDefaults:get(sectionName, "POSITION_X", 0))
        config:set(sectionName, "POSITION_Y", globalDefaults:get(sectionName, "POSITION_Y", 2.5))
        config:set(sectionName, "POSITION_Z", globalDefaults:get(sectionName, "POSITION_Z", -5))
        config:set(sectionName, "PITCH", globalDefaults:get(sectionName, "PITCH", -7.5))
        config:set(sectionName, "YAW", globalDefaults:get(sectionName, "YAW", 0))
        config:set(sectionName, "NAME", "Global " .. i)
    end
    
    config:save()
end

-- Reusable function to display adjustment button rows
function displayRow(updateFn, eMin, eMax, hasCenter, flipOrder, idSuffix)
    local precision = math.max(0, -eMin)  -- Number of decimal places for rounding
    
    -- Create array of increments from min to max
    local increments = {}
    for e = eMin, eMax do
        table.insert(increments, 10^e)
    end
    
    -- Center button (if hasCenter is true)
    if hasCenter then
        if ui.button("Center##" .. idSuffix) then
            updateFn(0.0)
        end
        ui.sameLine()
    end
    
    for i = #increments, 1, -1 do
        local increment = increments[i]
        local label = (flipOrder and "+" or "-") .. (increment >= 1 and string.format("%.0f", increment) or string.format("%g", increment))
        
        if ui.button(label .. "##" .. idSuffix, vec2(0, 0), repeatButton and ui.ButtonFlags.Repeat) then
            local newValue = math.round((updateFn(nil) + (flipOrder and increment or -increment)) * (10^precision)) / (10^precision)
            updateFn(newValue)
        end
        ui.sameLine()
    end

    for i = 1, #increments do
        local increment = increments[i]
        local label = (flipOrder and "-" or "+") .. (increment >= 1 and string.format("%.0f", increment) or string.format("%g", increment))
        
        if ui.button(label .. "##" .. idSuffix, vec2(0, 0), repeatButton and ui.ButtonFlags.Repeat) then
            local newValue = math.round((updateFn(nil) + (flipOrder and -increment or increment)) * (10^precision)) / (10^precision)
            updateFn(newValue)
        end
        
        if i < #increments then
            ui.sameLine()
        end
    end
end

local carPresetsExist = {}

function script.onShow()
    for i = 1, 5 do
        local carHash = hashCarName(ac.getCarName(0))
        local sectionName = carHash .. "_PRESET_" .. i
        if ac.INIConfig.load(configFile):get(sectionName, "FOV", 10000) ~= 10000 then
            carPresetsExist[i] = true
        end
    end
end

function script.betterOnboardSettings()
    local onboardCameraParams = ac.getOnboardCameraParams(0)
    local defaultOnboardCameraParams = ac.getOnboardCameraDefaultParams(0)
    local cameraFov = ac.getSim().cameraFOV

    ui.setCursor(vec2(10, 25))
    ui.beginGroup()
    if ui.button("Reset All") then
        onboardCameraParams = defaultOnboardCameraParams
        ac.setOnboardCameraParams(0, onboardCameraParams, true)
        ac.resetFirstPersonCameraFOV()
    end
    ui.sameLine()
    if ui.button("Reset All Except FOV") then
        onboardCameraParams = defaultOnboardCameraParams
        ac.setOnboardCameraParams(0, onboardCameraParams, true)
    end
    ui.sameLine()
    ui.setCursor(ui.getCursor() + vec2(155, 0))
    if ui.checkbox("Hold to repeat", repeatButton) then
        repeatButton = not repeatButton
    end
    
    ui.separator()
    
    ui.text("Camera FOV: " .. string.format("%.1f", cameraFov))
    -- FOV adjustment buttons in a row
    
    if ui.button("Reset##FOV") then
        ac.resetFirstPersonCameraFOV()
    end
    ui.sameLine()
    
    displayRow(function(newValue)
        if newValue == nil then
            return cameraFov
        else
            cameraFov = newValue
            ac.setFirstPersonCameraFOV(cameraFov)
        end
    end, -1, 1, false, false, "FOV")

    local leftRight = math.round(1000 * onboardCameraParams.position.x) == 0 and "(Center)" or (onboardCameraParams.position.x > 0 and "(Left)" or "(Right)")

    ui.text("Left/Right: " .. string.format("%.3f", onboardCameraParams.position.x) .. " " .. leftRight)

    if ui.button("Reset##L/R") then
        onboardCameraParams.position.x = defaultOnboardCameraParams.position.x
        ac.setOnboardCameraParams(0, onboardCameraParams, true)
    end
    ui.sameLine()
    
    displayRow(function(newValue)
        if newValue == nil then
            return onboardCameraParams.position.x
        else
            onboardCameraParams.position.x = newValue
            ac.setOnboardCameraParams(0, onboardCameraParams, true)
        end
    end, -3, -1, true, true, "L/R")

    local upDown = math.round(1000 * onboardCameraParams.position.y) == 0 and "(Center)" or (onboardCameraParams.position.y > 0 and "(Up)" or "(Down)")

    ui.text("Up/Down: " .. string.format("%.3f", onboardCameraParams.position.y) .. " " .. upDown)

    if ui.button("Reset##U/D") then
        onboardCameraParams.position.y = defaultOnboardCameraParams.position.y
        ac.setOnboardCameraParams(0, onboardCameraParams, true)
    end
    ui.sameLine()
    
    displayRow(function(newValue)
        if newValue == nil then
            return onboardCameraParams.position.y
        else
            onboardCameraParams.position.y = newValue
            ac.setOnboardCameraParams(0, onboardCameraParams, true)
        end
    end, -3, 0, false, false, "U/D")

    local forwardBackward = math.round(1000 * onboardCameraParams.position.z) == 0 and "(Center)" or (onboardCameraParams.position.z > 0 and "(Forward)" or "(Backward)")

    ui.text("Forward/Backward: " .. string.format("%.3f", onboardCameraParams.position.z) .. " " .. forwardBackward)

    if ui.button("Reset##B/F") then
        onboardCameraParams.position.z = defaultOnboardCameraParams.position.z
        ac.setOnboardCameraParams(0, onboardCameraParams, true)
    end
    ui.sameLine()
    
    displayRow(function(newValue)
        if newValue == nil then
            return onboardCameraParams.position.z
        else
            onboardCameraParams.position.z = newValue
            ac.setOnboardCameraParams(0, onboardCameraParams, true)
        end
    end, -3, 0, false, false, "B/F")

    local pitchUpDown = math.round(10 * onboardCameraParams.pitch) == 0 and "(Center)" or (onboardCameraParams.pitch > 0 and "(Up)" or "(Down)")

    ui.text("Pitch: " .. string.format("%.1f", math.round(10 * onboardCameraParams.pitch) / 10) .. " " .. pitchUpDown)

    if ui.button("Reset##Pitch") then
        onboardCameraParams.pitch = defaultOnboardCameraParams.pitch
        ac.setOnboardCameraParams(0, onboardCameraParams, true)
    end
    ui.sameLine()
    
    displayRow(function(newValue)
        if newValue == nil then
            return onboardCameraParams.pitch
        else
            ac.setOnboardCameraParams(0, ac.SeatParams(onboardCameraParams.position, newValue, onboardCameraParams.yaw), true)
        end
    end, -1, 1, false, false, "Pitch")

    local yawLeftRight = math.round(100 * onboardCameraParams.yaw) == 0 and "(Center)" or (onboardCameraParams.yaw > 0 and "(Left)" or "(Right)")

    ui.text("Yaw: " .. string.format("%.2f", onboardCameraParams.yaw) .. " " .. yawLeftRight)

    if ui.button("Reset##Yaw") then
        onboardCameraParams.yaw = defaultOnboardCameraParams.yaw
        ac.setOnboardCameraParams(0, onboardCameraParams, true)
    end
    ui.sameLine()
    
    displayRow(function(newValue)
        if newValue == nil then
            return onboardCameraParams.yaw
        else
            onboardCameraParams.yaw = newValue
            ac.setOnboardCameraParams(0, onboardCameraParams, true)
        end
    end, -2, 0, true, true, "Yaw")
    
    ui.separator()
    
    -- Global Presets Section
    ui.text("Global Presets:")
    
    if ui.button("Reset Global Presets") then
        resetGlobalPresets()
    end
    
    ui.columns(2)
    ui.setColumnWidth(0, 245)
    ui.setColumnWidth(1, 245)
    
    -- Global Load buttons
    ui.text("Load Global:")
    for i = 1, 5 do
        if i > 1 then ui.sameLine() end
        if ui.button("GL" .. i .. "##GlobalLoad") then
            loadGlobalPreset(i)
        end
    end

    ui.nextColumn()

    -- Global Save buttons
    ui.text("Save Global:")
    for i = 1, 5 do
        if i > 1 then ui.sameLine() end
        if ui.button("GS" .. i .. "##GlobalSave") then
            saveGlobalPreset(i)
        end
    end
    
    ui.columns(1)
    
    ui.separator()
    
    -- Car-Specific Presets Section
    local currentCarName = ac.getCarName(0)
    ui.text("Car-Specific Presets (" .. currentCarName .. "):")
    ui.columns(2)
    ui.setColumnWidth(0, 245)
    ui.setColumnWidth(1, 245)

    -- Car Load buttons
    ui.text("Load Car:")

    local carPresetExists = false
    for i = 1, 5 do
        if i > 1 then ui.sameLine() end
        if carPresetsExist[i] then
            if ui.button("CL" .. i .. "##CarLoad") then
                loadCarPreset(i)
            end
            carPresetExists = true
        end
    end

    if not carPresetExists then
        ui.newLine(8)
        ui.text("No car-specific presets found")
    end

    ui.nextColumn()
    
    -- Car Save buttons
    ui.text("Save Car:")
    for i = 1, 5 do
        if i > 1 then ui.sameLine() end
        if ui.button("CS" .. i .. "##CarSave") then
            saveCarPreset(i)
            carPresetsExist[i] = true
        end
    end

    ui.columns(1)

    ui.endGroup()
end