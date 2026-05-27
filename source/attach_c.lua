local attachedVehicle = nil
local towVehicle = nil
local ghostVehicle = nil
local clonedVehicle = nil
local storedVehicleData = {}

local function dbg(msg)
  if Config and Config.debugMode then
    print('[RachetStraps DEBUG] ' .. tostring(msg))
  end
end


local function notify(desc, type_)
  type_ = type_ or 'inform'
  if Config.Notify.useOx and lib and lib.notify then
    lib.notify({ title = Config.Notify.title or 'Rachet Straps', description = desc, type = type_ })
  else
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(desc)
    EndTextCommandThefeedPostTicker(false, false)
  end
end

local function showTextUI(text)
  if not Config.TextUI.enabled or not lib or not lib.showTextUI then return end
  lib.showTextUI(text or (Config.TextUI.instructions or ''), {
    position = Config.TextUI.position or 'top-center',
    icon = Config.TextUI.icon or 'hook',
    style = Config.TextUI.style or {}
  })
end

local function hideTextUI()
  if lib and lib.hideTextUI then lib.hideTextUI() end
end


local function getClosestVehicleFromConfig(playerCoords)
  local closestVehicle, closestDistance = nil, 9999999.0
  local radius = (Config.Select and Config.Select.radius) or 5.0
  local includeSelf = (Config.Select and Config.Select.includePlayerVehicle) or false

  local nearbyVehicles = lib.getNearbyVehicles(playerCoords, radius, includeSelf)
  for _, vehicleData in ipairs(nearbyVehicles) do
    local vehicle = vehicleData.vehicle
    local distance = #(playerCoords - vehicleData.coords)
    if distance < closestDistance then
      closestVehicle = vehicle
      closestDistance = distance
    end
  end
  return closestVehicle
end

local function isWhitelistedTowingVehicle(vehicle)
  if not (Config.Select and Config.Select.whitelistEnabled) then return true end
  local model = GetEntityModel(vehicle)
  for _, whitelistedModel in ipairs(Config.WhitelistedTowingVehicles or {}) do
    if model == whitelistedModel then return true end
  end
  return false
end


local function storeVehicleData(vehicle)
  local d = { model = GetEntityModel(vehicle), mods = {} }
  for i = 0, 49 do d.mods[i] = GetVehicleMod(vehicle, i) end
  d.colors = { GetVehicleColours(vehicle) }
  d.extraColors = { GetVehicleExtraColours(vehicle) }
  d.livery = GetVehicleLivery(vehicle)
  d.wheelType = GetVehicleWheelType(vehicle)
  d.neonColor = { GetVehicleNeonLightsColour(vehicle) }
  d.neonState = {
    IsVehicleNeonLightEnabled(vehicle, 0),
    IsVehicleNeonLightEnabled(vehicle, 1),
    IsVehicleNeonLightEnabled(vehicle, 2),
    IsVehicleNeonLightEnabled(vehicle, 3)
  }
  return d
end

local function restoreVehicleData(vehicle, d)
  if not d then return end
  SetVehicleModKit(vehicle, 0)
  for i = 0, 49 do
    if d.mods[i] then SetVehicleMod(vehicle, i, d.mods[i], false) end
  end
  if d.colors then SetVehicleColours(vehicle, d.colors[1], d.colors[2]) end
  if d.extraColors then SetVehicleExtraColours(vehicle, d.extraColors[1], d.extraColors[2]) end
  if d.livery then SetVehicleLivery(vehicle, d.livery) end
  if d.wheelType then SetVehicleWheelType(vehicle, d.wheelType) end
  if d.neonColor then SetVehicleNeonLightsColour(vehicle, d.neonColor[1], d.neonColor[2], d.neonColor[3]) end
  if d.neonState then for i = 0, 3 do SetVehicleNeonLightEnabled(vehicle, i, d.neonState[i+1]) end end
end


local function enablePlacementMode(entity, tower)
  if not DoesEntityExist(entity) then return end
  local P = Config.Placement or {}
  SetEntityAlpha(entity, P.ghostAlpha or 150, false)
  FreezeEntityPosition(entity, P.freeze ~= false)
  SetEntityHasGravity(entity, P.gravity == true)
  SetEntityDynamic(entity, P.gravity == true) 
  SetEntityCollision(entity, P.collision == true, P.collision == true)
  if DoesEntityExist(tower) then
    SetEntityNoCollisionEntity(entity, tower, true)
    SetEntityNoCollisionEntity(tower, entity, true)
  end
  SetEntityVelocity(entity, 0.0, 0.0, 0.0)
  SetEntityAngularVelocity(entity, 0.0, 0.0, 0.0)
end

local function disablePlacementMode(entity, tower)
  if not DoesEntityExist(entity) then return end
  SetEntityAlpha(entity, 255, false)
  FreezeEntityPosition(entity, false)
  SetEntityHasGravity(entity, true)
  SetEntityDynamic(entity, true)
  SetEntityCollision(entity, true, true)
  if DoesEntityExist(tower) then
    SetEntityNoCollisionEntity(entity, tower, false)
    SetEntityNoCollisionEntity(tower, entity, false)
  end
end


local function applyAttachCollisionMode(attached, tower)
  local A = Config.Attach or {}
  local mode = (A.collisionMode or 'none')
  if mode == 'none' then
    SetEntityCollision(attached, false, false)
    if DoesEntityExist(tower) then
      SetEntityNoCollisionEntity(attached, tower, true)
      SetEntityNoCollisionEntity(tower, attached, true)
    end
    return false 
  elseif mode == 'noTowOnly' then
    SetEntityCollision(attached, true, true)
    if DoesEntityExist(tower) then
      SetEntityNoCollisionEntity(attached, tower, true)
      SetEntityNoCollisionEntity(tower, attached, true)
    end
    return true
  else 
    SetEntityCollision(attached, true, true)
    if DoesEntityExist(tower) then
      SetEntityNoCollisionEntity(attached, tower, false)
      SetEntityNoCollisionEntity(tower, attached, false)
    end
    return true
  end
end


local function clearGhost(entity)
    if not DoesEntityExist(entity) then return end
    ResetEntityAlpha(entity)                 
    SetEntityAlpha(entity, 255, false)       
    SetEntityVisible(entity, true, false)    
end



local startTowing, selectVehicle, detachVehicle


startTowing = function(towerVehicle, towedVehicle)
  storedVehicleData = storeVehicleData(towedVehicle)
  attachedVehicle = towedVehicle
  towVehicle = towerVehicle

  SetEntityAsMissionEntity(attachedVehicle, true, true)
  NetworkRequestControlOfEntity(attachedVehicle)
  while not NetworkHasControlOfEntity(attachedVehicle) do Wait(0) end

  local netId = NetworkGetNetworkIdFromEntity(attachedVehicle)
  SetNetworkIdCanMigrate(netId, true)
  SetNetworkIdExistsOnAllMachines(netId, true)

  enablePlacementMode(attachedVehicle, towVehicle)
  notify(Config.Messages.vehicleLockedIn, 'success')
  showTextUI(Config.TextUI.instructions)

  local step = (Config.Placement and Config.Placement.step) or 0.03
  local rotStep = (Config.Placement and Config.Placement.rotationStep) or 1.0
  local allowRot = (Config.Placement and Config.Placement.allowRotation) ~= false

  local keys = Config.Keys or {}
  local xOffset, yOffset, zOffset, headingOffset = 0.0, 0.0, 0.0, 0.0

  CreateThread(function()
    while true do
      Wait(0)

      if (Config.Placement and Config.Placement.zeroVelEachFrame) ~= false then
        SetEntityVelocity(attachedVehicle, 0.0, 0.0, 0.0)
        SetEntityAngularVelocity(attachedVehicle, 0.0, 0.0, 0.0)
      end

      xOffset, yOffset, zOffset, headingOffset = 0.0, 0.0, 0.0, 0.0

      if IsControlPressed(0, keys.forward or 172) then xOffset = step end
      if IsControlPressed(0, keys.back    or 173) then xOffset = -step end
      if IsControlPressed(0, keys.left    or 174) then yOffset = -step end
      if IsControlPressed(0, keys.right   or 175) then yOffset =  step end
      if IsControlPressed(0, keys.up      or 10 ) then zOffset =  step end
      if IsControlPressed(0, keys.down    or 11 ) then zOffset = -step end
      if allowRot and IsControlPressed(0, keys.rotateLeft  or 117) then headingOffset = -rotStep end
      if allowRot and IsControlPressed(0, keys.rotateRight or 118) then headingOffset =  rotStep end

      local pos = GetEntityCoords(attachedVehicle)
      local hdg = GetEntityHeading(attachedVehicle)
      local newPos = vector4(pos.x + xOffset, pos.y + yOffset, pos.z + zOffset, hdg + headingOffset)

      SetEntityCoordsNoOffset(attachedVehicle, newPos.x, newPos.y, newPos.z, false, false, false)
      SetEntityHeading(attachedVehicle, newPos.w)

      if IsControlJustReleased(0, keys.finalize or 18) then
        local ok = true
        if lib and lib.skillCheck and Config.SkillCheck and Config.SkillCheck.enabled then
          ok = lib.skillCheck(
            Config.SkillCheck.sequence or { 'easy', { areaSize = 70, speedMultiplier = 1.2 }, 'easy' },
            Config.SkillCheck.keys or { 'w', 'a', 's', 'd' }
          )
        end

        if ok then
          local towPos = GetEntityCoords(towerVehicle)
          local towHdg = GetEntityHeading(towerVehicle)
          local relX = newPos.x - towPos.x
          local relY = newPos.y - towPos.y
          local relZ = newPos.z - towPos.z
          local rad = math.rad(-towHdg)
          local relXLocal = relX * math.cos(rad) - relY * math.sin(rad)
          local relYLocal = relX * math.sin(rad) + relY * math.cos(rad)

          local attachX, attachY, attachZ = relXLocal, relYLocal, relZ
          local attachHeading = newPos.w - towHdg

          
          FreezeEntityPosition(attachedVehicle, false)
          SetEntityHasGravity(attachedVehicle, false)

          local attachCollisionParam = applyAttachCollisionMode(attachedVehicle, towerVehicle)
          local A = Config.Attach or {}
            AttachEntityToEntity(
                attachedVehicle,
                towerVehicle,
                0,
                attachX, attachY, attachZ,
                0.0, 0.0, attachHeading,
                false,
                A.useSoftPinning or false,
                attachCollisionParam,
                A.isPed or false,
                A.vertexIndex or 2,
                (A.fixedRot ~= false)
            )

            clearGhost(attachedVehicle)  


          if Config.Target and Config.Target.enabled and exports and exports.ox_target then
            local netId2 = NetworkGetNetworkIdFromEntity(attachedVehicle)
            exports.ox_target:addEntity(netId2, {
              {
                label = Config.Target.detachLabel or 'Detach Vehicle',
                icon = Config.Target.detachIcon or 'fa-solid fa-chain-broken',
                distance = Config.Target.detachDistance or 2.5,
                onSelect = function(data) detachVehicle(data.entity, towerVehicle) end
              }
            })
          end

          notify(Config.Messages.attachedSuccess, 'success')
          hideTextUI()

          if Config.Safety and Config.Safety.enabled then
            CreateThread(function()
              while DoesEntityExist(towerVehicle) and DoesEntityExist(attachedVehicle) do
                local base = Config.Safety.checkIntervalMin or 15000
                local var  = Config.Safety.checkIntervalVar or 5000
                Wait(base + math.random(0, var))
                local bodyHealth = GetVehicleBodyHealth(towerVehicle)
                if (bodyHealth or 1000.0) <= (Config.Safety.minBodyHealth or 500.0) then
                  DetachEntity(attachedVehicle, true, true)
                  notify(Config.Messages.healthAutoDetach, 'error')
                  break
                end
              end
            end)
          end
        else
          disablePlacementMode(attachedVehicle, towerVehicle)
          notify(Config.Messages.attachedFail, 'error')
          hideTextUI()
        end
        break
      end
    end
  end)
end


detachVehicle = function(vehicle, towerVehicle)
  if not DoesEntityExist(vehicle) then return end

  DetachEntity(vehicle, true, true)
  enablePlacementMode(vehicle, towerVehicle)
  showTextUI(Config.TextUI.instructions)

  local step = (Config.Placement and Config.Placement.step) or 0.03
  local rotStep = (Config.Placement and Config.Placement.rotationStep) or 1.0
  local allowRot = (Config.Placement and Config.Placement.allowRotation) ~= false
  local keys = Config.Keys or {}

  CreateThread(function()
    while true do
      Wait(0)

      if (Config.Placement and Config.Placement.zeroVelEachFrame) ~= false then
        SetEntityVelocity(vehicle, 0.0, 0.0, 0.0)
        SetEntityAngularVelocity(vehicle, 0.0, 0.0, 0.0)
      end

      local xOffset, yOffset, zOffset, headingOffset = 0.0, 0.0, 0.0, 0.0
      if IsControlPressed(0, keys.forward or 172) then xOffset = step end
      if IsControlPressed(0, keys.back    or 173) then xOffset = -step end
      if IsControlPressed(0, keys.left    or 174) then yOffset = -step end
      if IsControlPressed(0, keys.right   or 175) then yOffset =  step end
      if IsControlPressed(0, keys.up      or 10 ) then zOffset =  step end
      if IsControlPressed(0, keys.down    or 11 ) then zOffset = -step end
      if allowRot and IsControlPressed(0, keys.rotateLeft  or 117) then headingOffset = -rotStep end
      if allowRot and IsControlPressed(0, keys.rotateRight or 118) then headingOffset =  rotStep end

      local pos = GetEntityCoords(vehicle)
      local hdg = GetEntityHeading(vehicle)
      local newPos = vector4(pos.x + xOffset, pos.y + yOffset, pos.z + zOffset, hdg + headingOffset)

      SetEntityCoordsNoOffset(vehicle, newPos.x, newPos.y, newPos.z, false, false, false)
      SetEntityHeading(vehicle, newPos.w)

      if IsControlJustReleased(0, (Config.Keys and Config.Keys.finalize) or 18) then
        disablePlacementMode(vehicle, towerVehicle)
        if Config.Detach and Config.Detach.setOnGroundProperly then
          SetVehicleOnGroundProperly(vehicle)
        end

        if Config.Target and Config.Target.enabled and exports and exports.ox_target then
          local netId = NetworkGetNetworkIdFromEntity(vehicle)
          exports.ox_target:removeEntity(netId, Config.Target.detachLabel or 'Detach Vehicle')
        end

        notify(Config.Messages.detachedSuccess, 'success')
        attachedVehicle, towVehicle = nil, nil
        hideTextUI()
        break
      end
    end
  end)
end


local function detachAndRespawnOriginalVehicle()
  if clonedVehicle then
    local coords, heading = GetEntityCoords(clonedVehicle), GetEntityHeading(clonedVehicle)
    DeleteEntity(clonedVehicle)
    if storedVehicleData and storedVehicleData.model then
      local originalVehicle = CreateVehicle(storedVehicleData.model, coords.x, coords.y, coords.z, heading, true, false)
      restoreVehicleData(originalVehicle, storedVehicleData)
    end
    clonedVehicle, storedVehicleData = nil, {}
  end
end


selectVehicle = function(selectionType, towerVeh)
  local playerPed = PlayerPedId()
  CreateThread(function()
    while true do
      Wait(0)
      if IsControlJustReleased(0, (Config.Keys and Config.Keys.finalize) or 18) then
        local playerCoords = GetEntityCoords(playerPed)
        local vehicle = getClosestVehicleFromConfig(playerCoords)
        if vehicle and vehicle ~= 0 then
          if selectionType == 'tower' then
            if not isWhitelistedTowingVehicle(vehicle) then
              notify(Config.Messages.selectTowNotAllowed, 'error')
              break
            end
            towVehicle = vehicle
            notify(Config.Messages.towSelected, 'inform')
            selectVehicle('towed', vehicle)
          else 
            if vehicle == towerVeh then
              notify(Config.Messages.cannotTowSelf, 'error')
              break
            end
            attachedVehicle = vehicle
            startTowing(towerVeh, attachedVehicle)
          end
          break
        else
          notify(Config.Messages.noVehicleNearby, 'error')
        end
      end
    end
  end)
end


local function useTowingTool()
  notify(Config.Messages.selectTowEnter, 'inform')
  selectVehicle('tower')
end

exports('useTowingTool', useTowingTool)
exports('detachAndRespawnOriginalVehicle', detachAndRespawnOriginalVehicle)


RegisterCommand(Config.Commands.attach or 'attach', function()
  if attachedVehicle ~= nil then
    notify(Config.Messages.alreadyAttached, 'error')
    return
  end
  useTowingTool()
end, false)

RegisterCommand(Config.Commands.detach or 'detach', function()
  if not attachedVehicle or not DoesEntityExist(attachedVehicle) then
    notify(Config.Messages.noneAttached, 'error')
    return
  end
  detachVehicle(attachedVehicle, towVehicle)
end, false)
