local inTable = false
local playerCards = {}
local otherplayersCards = {}
local dealerCards = {}
local playerCount = 0
local dealerCount = 0
local textWinLosePush = ""
local gameFinished = false
local waiting = false
local alreadyPressed = false
local stopBet = false
local cardsGiven = false
local bet = 0
local maxbet = 0
local target_table
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
end)

function startPlay()
    resetGameVariables()
    inTable = true
    TriggerServerEvent('ak_blackjack:Request_Sit' , target_table)
    SendNUIMessage({type = 'show'})
end

function stopPlay()
    resetGameVariables()
    inTable = false
    TriggerServerEvent('ak_blackjack:Request_Leave', target_table)
    SendNUIMessage({type = 'hide'})
	target_table = nil
end

function resetGameVariables()
    playerCards = {}
    otherplayersCards = {}
    dealerCards = {}
    playerCount = 0
    dealerCount = 0
    textWinLosePush = ""
    gameFinished = false
    waiting = false
    alreadyPressed = false
    stopBet = false
    cardsGiven = false
    SendNUIMessage({type = 'clear'})
    maxbet = 0
    local str = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", " ", Citizen.ResultAsLong())
    Citizen.InvokeNative(0xFA233F8FE190514C, str)
    Citizen.InvokeNative(0xE9990552DEC71600)
end



-- PROMPT
local BlackJackGroup = GetRandomIntInRange(0, 0xffffff)

local StartBlackJackGroup = GetRandomIntInRange(0, 0xffffff)


local _StartPrompt
function StartPrompt()
    Citizen.CreateThread(function()
        local str = "Play BlackJack"
        _StartPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(_StartPrompt, 0xC7B5340A)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(_StartPrompt, str)
        PromptSetEnabled(_StartPrompt, true)
        PromptSetVisible(_StartPrompt, true)
        PromptSetStandardMode(_StartPrompt, true)
        PromptSetGroup(_StartPrompt, StartBlackJackGroup)
        PromptRegisterEnd(_StartPrompt)
        PromptSetPriority(_StartPrompt , true)
    end)
end





local _BetPrompt
function BetPrompt()
    Citizen.CreateThread(function()
        local str = "Bet"
        _BetPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(_BetPrompt, 0xC7B5340A)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(_BetPrompt, str)
        PromptSetEnabled(_BetPrompt, false)
        PromptSetVisible(_BetPrompt, false)
        PromptSetStandardMode(_BetPrompt, true)
        PromptSetGroup(_BetPrompt, BlackJackGroup)
        PromptRegisterEnd(_BetPrompt)
        PromptSetPriority(_BetPrompt , true)
    end)
end

local _BetPromptAmmount
function BetPromptAmmount()
    Citizen.CreateThread(function()
        local str = "Amount: " .. bet.."$"
        _BetPromptAmmount = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(_BetPromptAmmount, 0x6319DB71)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(_BetPromptAmmount, str)
        PromptSetEnabled(_BetPromptAmmount, false)
        PromptSetVisible(_BetPromptAmmount, false)
        PromptSetStandardMode(_BetPromptAmmount, true)
        PromptSetGroup(_BetPromptAmmount, BlackJackGroup)
        PromptRegisterEnd(_BetPromptAmmount)
        PromptSetPriority(_BetPromptAmmount , true)
    end)
end

local _CallPrompt
function CallPrompt()
    Citizen.CreateThread(function()
        local str = "Call"
        _CallPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(_CallPrompt, 0xC7B5340A)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(_CallPrompt, str)
        PromptSetEnabled(_CallPrompt, false)
        PromptSetVisible(_CallPrompt, false)
        PromptSetStandardMode(_CallPrompt, true)
        PromptSetGroup(_CallPrompt, BlackJackGroup)
        PromptRegisterEnd(_CallPrompt)
        PromptSetPriority(_CallPrompt , true)
    end)
end




CreateThread(function()
    Wait(1000)
    CallPrompt()
    BetPromptAmmount()
    BetPrompt()
    StartPrompt()


    while true do
        Wait(0)
        local ped = PlayerPedId()
		for i, v in ipairs(Config.Tables) do
		local distance = Vdist(GetEntityCoords(ped) , v ) < 2
        while distance do
            Wait(0)
			distance = Vdist(GetEntityCoords(ped) , v ) < 2
			target_table = i

            if not inTable then
                local BlackJackGroupName  = CreateVarString(10, 'LITERAL_STRING', "BlackJack")
                PromptSetActiveGroupThisFrame(StartBlackJackGroup, BlackJackGroupName)

                if PromptHasStandardModeCompleted(_StartPrompt) then
                    print("sdsds")
                    TriggerEvent('ak_notification:Tip', 'When playing BlackJack you must not exceed a total of 21. The picks count for 10 and the aces for 10 or 1. Whoever comes closest to 21 wins.' , 10000 )
                    PlaySoundFrontend("show_info", "Study_Sounds", true, 0)
                    startPlay()
                end

            elseif inTable then
                local BlackJackGroupName  = CreateVarString(10, 'LITERAL_STRING', "BlackJack")
                PromptSetActiveGroupThisFrame(BlackJackGroup, BlackJackGroupName)

            elseif inTable and not distance then
                inTable = false
                textWinLosePush = ""
                stopPlay()
            end

            if inTable and waiting and not alreadyPressed then
                PromptSetEnabled(_CallPrompt, true)
                PromptSetVisible(_CallPrompt, true)
                local str = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", " ", Citizen.ResultAsLong())
                Citizen.InvokeNative(0xFA233F8FE190514C, str)
                Citizen.InvokeNative(0xE9990552DEC71600)
                if PromptHasStandardModeCompleted(_CallPrompt) and waiting then
                    TriggerServerEvent('ak_blackjack:Choice', true , i)
                    alreadyPressed = true
                    PromptSetEnabled(_CallPrompt, false)
                    PromptSetVisible(_CallPrompt, false)
                end
            elseif (inTable and not alreadyPressed and cardsGiven) then
                PromptSetEnabled(_CallPrompt, false)
                PromptSetVisible(_CallPrompt, false)
                local str = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", "Wait for your turn", Citizen.ResultAsLong())
                Citizen.InvokeNative(0xFA233F8FE190514C, str)
                Citizen.InvokeNative(0xE9990552DEC71600)
            end
            if maxbet ~= 0 and not stopBet then
                PromptSetEnabled(_BetPromptAmmount, true)
                PromptSetVisible(_BetPromptAmmount, true)
                PromptSetEnabled(_BetPrompt, true)
                PromptSetVisible(_BetPrompt, true)
            end
            if PromptHasStandardModeCompleted(_BetPromptAmmount) and not stopBet  then
                bet = bet + 0.50
                if bet > maxbet then
                    bet = 0
                    PlaySoundFrontend("BET_MIN_MAX", "HUD_POKER", true, 0)
                end
                if bet ~= 0 then
                    PlaySoundFrontend("BET_AMOUNT", "HUD_POKER", true, 0)
                end
                PromptDelete(_BetPromptAmmount)
                BetPromptAmmount()
            end

            if PromptHasStandardModeCompleted(_BetPrompt) and not stopBet then
                if not stopBet then
                    TriggerServerEvent("ak_blackjack:Get_Bet", bet , i)
                    PlaySoundFrontend("menu_select_bet", "RDRO_Poker_Sounds", true, 0)
                    PromptSetEnabled(_BetPromptAmmount, false)
                    PromptSetVisible(_BetPromptAmmount, false)
                    PromptSetEnabled(_BetPrompt, false)
                    PromptSetVisible(_BetPrompt, false)
                end
                stopBet = true
            end



            if not distance then
                stopPlay()
            end
        end
		end
    end
end)







RegisterNetEvent('ak_blackjack:ReceiveCard')
AddEventHandler('ak_blackjack:ReceiveCard', function(card, type , target)
    cardsGiven = true
	if inTable then
		PlaySoundFrontend("enter", "RDRO_Winners_Screen_Sounds", true, 0)
	end
    if type == "player" then
        if Config.Prints then
            print(card)
		    print(target)
        end
        if target == GetPlayerServerId(PlayerId()) then
            table.insert(playerCards, card)
            SendNUIMessage({type = 'player' , cards = playerCards})
        else
            local test = false
            for k ,v in pairs (otherplayersCards) do
                if v.source == target then
                    if Config.Prints then
                        print("mam juz ")
                    end
                    test = true
                    table.insert(v.card , card)
                end
            end
            if not test then
                local test2 = {}
                table.insert(test2 , card)
                otherplayersCards[#otherplayersCards + 1] = {source = target,  card = test2}
            end
            if Config.Prints then
			    print(json.encode(otherplayersCards))
            end
            SendNUIMessage({type = 'other' , cards = otherplayersCards})
        end
    else
        table.insert(dealerCards, card)
        SendNUIMessage({type = 'dealer' , cards = dealerCards})

    end
end)



Citizen.CreateThread(function()
 for i, v in ipairs(Config.Tables) do
    local blip = N_0x554d9d53f696d002(1664425300, v)
    SetBlipSprite(blip, 595820042, 1)
    SetBlipScale(blip, 0.2)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Blackjack")
end
end)

RegisterNetEvent('ak_blackjack:ReceiveWin')
AddEventHandler('ak_blackjack:ReceiveWin', function(gameResolution)
    textWinLosePush = gameResolution
    PlaySoundFrontend("show_info", "Study_Sounds", true, 0)
    TriggerEvent( 'ak_notification:Tip', textWinLosePush..' !' , 3000 )
end)

RegisterNetEvent('ak_blackjack:ReceiveCountedCards')
AddEventHandler('ak_blackjack:ReceiveCountedCards', function(count,type)
    if type == "player" then
        playerCount=count
    else
        dealerCount=count
    end
end)



RegisterNetEvent('ak_blackjack:GameFinished')
AddEventHandler('ak_blackjack:GameFinished', function(status)
    gameFinished = status
end)

RegisterNetEvent('ak_blackjack:WaitingForResponse')
AddEventHandler('ak_blackjack:WaitingForResponse', function(status)
    alreadyPressed = false
    waiting = status
end)

RegisterNetEvent('ak_blackjack:Reset_Game_Var')
AddEventHandler('ak_blackjack:Reset_Game_Var', function()
    resetGameVariables()
end)

RegisterNetEvent('ak_blackjack:Bet')
AddEventHandler('ak_blackjack:Bet', function(max)
    maxbet = max


end)

RegisterNetEvent("ak_blackjack:Stop_Bet")
AddEventHandler("ak_blackjack:Stop_Bet", function()
    if not stopBet then
        stopBet = true
        PromptSetEnabled(_BetPromptAmmount, false)
        PromptSetVisible(_BetPromptAmmount, false)
        PromptSetEnabled(_BetPrompt, false)
        PromptSetVisible(_BetPrompt, false)
        TriggerServerEvent("ak_blackjack:Get_Bet", 0 , target_table)
    end
end)

