ESX = nil
local PlayerData = {}

Citizen.CreateThread(function()
    while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
end)

local garages = {
	{vector3(408.1, -1625.15, 29.29), vector3(410.19, -1640.51, 29.29), 217.46},
	{vector3(-174.9, -1273.35, 32.40), vector3(-169.62, -1303.82, 31.98), 87.77},
	{vector3(1508.39, 3768.63, 34.14), vector3(1507.43, 3759.28, 33.98), 199.08},
	{vector3(-234.91, 6199.07, 31.94), vector3(-232.59, 6193.18, 31.49), 138.18}
}


local enableField = false

function AddCar(plate, label)
	if label == "CARNOTFOUND" then
		label = "UNKOWN CAR"
	end
    SendNUIMessage({
	action = 'add',
	plate = plate,
		label = label
    }) 
end

function toggleField(enable)
    SetNuiFocus(enable, enable)
    enableField = enable

    if enable then
	SendNUIMessage({
		action = 'open'
	}) 
    else
	SendNUIMessage({
		action = 'close'
	}) 
    end
end

AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() ~= name then
		return
    end

    toggleField(false)
end)

RegisterNUICallback('escape', function(data, cb)
    toggleField(false)
    SetNuiFocus(false, false)

    cb('ok')
end)

RegisterNUICallback('enable-parkout', function(data, cb)

    ESX.TriggerServerCallback('fd_impound:loadVehicles', function(vehicles)
		for key, value in pairs(vehicles) do
			local props = json.decode(value.vehicle)
			AddCar(value.plate, GetDisplayNameFromVehicleModel(props.model))		
		end
    end)
    
    cb('ok')
end) 

RegisterNUICallback('enable-parking', function(data, cb)
    local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(GetPlayerPed()), 25.0)
    for key, value in pairs(vehicles) do
		ESX.TriggerServerCallback('fd_impound:isOwned', function(owned)
			if owned then
				AddCar(GetVehicleNumberPlateText(value))
			end
		end, GetVehicleNumberPlateText(value))
    end
    cb('ok')
end) 

local usedGarage

RegisterNUICallback('park-out', function(data, cb)
    ESX.TriggerServerCallback('fd_impound:loadVehicle', function(vehicle)
	local x,y,z = table.unpack(garages[usedGarage][2])
	local props = json.decode(vehicle[1].vehicle)
    local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(GetPlayerPed()), 25.0)

    for key, value in pairs(vehicles) do
		if GetVehicleNumberPlateText(value) == data.plate then
			ESX.Game.DeleteVehicle(value)
		end
    end

	ESX.Game.SpawnVehicle(props.model, {
	x = x,
	y = y,
	z = z + 1
	}, garages[usedGarage][3], function(callback_vehicle)
		ESX.Game.SetVehicleProperties(callback_vehicle, props)
		SetVehRadioStation(callback_vehicle, "OFF")
		TaskWarpPedIntoVehicle(GetPlayerPed(), callback_vehicle, -1)
	end)

    end, data.plate)

    TriggerServerEvent('fd_impound:changeState', data.plate, 1)
    
    cb('ok')
end)

RegisterNUICallback('park-in', function(data, cb)
    local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(GetPlayerPed()), 25.0)

    for key, value in pairs(vehicles) do
		if GetVehicleNumberPlateText(value) == data.plate then
			TriggerServerEvent('fd_impound:saveProps', data.plate, ESX.Game.GetVehicleProperties(value))
			TriggerServerEvent('fd_impound:changeState', data.plate, 1)
			ESX.Game.DeleteVehicle(value)
		end
    end

    cb('ok')
end)

Citizen.CreateThread(function()
    while true do
		Wait(0)
		local sleep = true
		for key, value in pairs(garages) do
			local dist = GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed()), value[1])
			if dist <= 2.0 then
				sleep = false
				ESX.ShowHelpNotification("Drücke ~INPUT_CONTEXT~ um auf dem Abschlepphof zuzugreifen")

				if IsControlJustReleased(0, 38) then
					toggleField(true)
					usedGarage = key
				end
			end
		end
		if sleep then Citizen.Wait(1000) end
	end
end)

local coordinate = {
    { 408.1, -1625.15, 29.29, nil, 225.00, nil, -1176698112}, 
    { -174.9, -1273.35, 32.57, nil, 445.00, nil, 68070371},
    { 1508.39, 3768.63, 34.14, nil, 286.16, nil, 68070371},
    { -234.91, 6199.07, 31.94, nil, 245.0, nil, 68070371}	
}

Citizen.CreateThread(function()
    for _, v in pairs(coordinate) do
		RequestModel(v[7])
	while not HasModelLoaded(v[7]) do
		Wait(1)
	end

	ped = CreatePed(4, v[7], v[1], v[2], v[3] - 1, 3374176, false, true)
	SetEntityHeading(ped, v[5])
	FreezeEntityPosition(ped, true)
	SetEntityInvincible(ped, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	end
end)

Citizen.CreateThread(function()
	for _, coords in pairs(garages) do
	local blip = AddBlipForCoord(coords[1])
	SetBlipSprite(blip, 67)
	SetBlipScale(blip, 0.9)
	SetBlipColour(blip, 0)
	SetBlipDisplay(blip, 4)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Garage - Abschlepphof")
	EndTextCommandSetBlipName(blip)
	end
end)