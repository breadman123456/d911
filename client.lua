Citizen.CreateThread(function()
	TriggerServerEvent('d911:check-permissions')
end)

RegisterNetEvent("d911:set-waypoint")
AddEventHandler("d911:set-waypoint", function(x, y)
	SetNewWaypoint(x, y)
end)
