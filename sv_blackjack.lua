QBCore = {}


local isBlackjackActivated = {}
local startedGame = {}
local dealerCards = {}
local dealerHasAce = {}
local dealerFakeBust = {}
local countDealerCards = {}
local playersData = {}
local waitingPlayers = {}

for i=1,10 do isBlackjackActivated[i] = false startedGame [i] = false  dealerCards[i] = {} dealerHasAce[i] = false dealerFakeBust[i] = false countDealerCards[i] = 0 playersData[i] = {} waitingPlayers[i] = {} end




function collectBet(index)
    for i, v in ipairs(playersData[index]) do
        TriggerClientEvent("ak_blackjack:Bet", v.playerId,25)
    end
    Citizen.Wait(15000)
    for i, v in ipairs(playersData[index]) do
        TriggerClientEvent("ak_blackjack:Stop_Bet", v.playerId)
    end
end
function ReciveForEveryoneFromSession(card , type , id , index)
	for i, v in ipairs(playersData[index]) do
		TriggerClientEvent('ak_blackjack:ReceiveCard', v.playerId, card, type ,id)
	end
end
function giveCards(index) -- Questi valori vanno passati al client
    startedGame[index] = true


    dealerCards[index][1]= peekCard("dealer" , "sdsd" , index)

    for i, v in ipairs(playersData[index]) do

        v.playerCards[1] = peekCard("player", v.playerId , index)
        v.playerCards[2]= peekCard("player", v.playerId , index)

        ReciveForEveryoneFromSession(v.playerCards[1], "player" ,v.playerId, index)
        Citizen.Wait(1000)
          ReciveForEveryoneFromSession(v.playerCards[2], "player" , v.playerId, index)
        Citizen.Wait(1000)
        TriggerClientEvent('ak_blackjack:ReceiveCard', v.playerId, dealerCards[index][1], "dealer")
        Citizen.Wait(1000)
        TriggerClientEvent('ak_blackjack:ReceiveCountedCards', v.playerId, v.countPlayerCards, "player")
        TriggerClientEvent('ak_blackjack:ReceiveCountedCards', v.playerId, countDealerCards[index], "dealer")
    end



    dealerCards[index][2]= peekCard("dealer" , "sdsd" , index)
end

function startGame(i)
Citizen.CreateThread(function()
	local index = i
    isBlackjackActivated[index] = true
    while #playersData[index] ~= 0 or #waitingPlayers[index] ~= 0 do
        if (#playersData[index] ~= 0) then
			Wait(4000)
			addPlayerInGame(index)
            collectBet(index)
            giveCards(index)
            local j = 3
            for i, v in ipairs(playersData[index]) do
                while v.countPlayerCards < 21 and not v.continue do
                    if (v.isInTable) then
                        TriggerClientEvent('ak_blackjack:WaitingForResponse', v.playerId, true)
                        Citizen.Wait(7000)
                        TriggerClientEvent('ak_blackjack:WaitingForResponse', v.playerId, false)
                    end
                    if v.continue == true then
                        v.continue = false
                        v.playerCards[j]=peekCard("player", v.playerId , index)
                        Citizen.Wait(1000)
                        ReciveForEveryoneFromSession( v.playerCards[j], "player" , v.playerId, index)
                        TriggerClientEvent('ak_blackjack:ReceiveCountedCards', v.playerId, v.countPlayerCards, "player")
                        if getNumber(v.playerCards[j],v.playerHasAce) == 1 then
                            v.playerHasAce = true
                        end
                        j = j+1
                    else
                        v.continue = true
                    end
                end
            end

            for i, v in ipairs(playersData[index]) do
                if (v.isInTable) then
                    TriggerClientEvent('ak_blackjack:ReceiveCard', v.playerId, dealerCards[index][2], "dealer")
                    Citizen.Wait(1000)
                    TriggerClientEvent('ak_blackjack:ReceiveCountedCards', v.playerId, countDealerCards[index], "dealer")
                end
            end

            Citizen.Wait(2000)

           local j = 3
            while countDealerCards[index] < 17 do

                dealerCards[index][j]=peekCard("dealer" , "sd" , index)
                for i, v in ipairs(playersData[index]) do
                    if (v.isInTable) then
                        TriggerClientEvent('ak_blackjack:ReceiveCard', v.playerId, dealerCards[index][j], "dealer")
                        TriggerClientEvent('ak_blackjack:ReceiveCountedCards', v.playerId, countDealerCards[index], "dealer")
                        Citizen.Wait(1000)
                    end
                end
                if getNumber(dealerCards[index][j],dealerHasAce[index]) == 1 then
                    dealerHasAce[index] = true
                end
                j = j+1

            end

            for i, v in ipairs(playersData[index]) do
                if (v.isInTable) then
                    if countDealerCards[index] > 21 and v.isInTable and v.countPlayerCards > 21 then
                        payBet(v.playerId, v.betAmount, "push")
                    elseif v.countPlayerCards > 21 and v.isInTable   then
                        payBet(v.playerId, v.betAmount, "lose")
					elseif countDealerCards[index] > 21 and v.isInTable   then
                        payBet(v.playerId, v.betAmount, "win")
                    elseif countDealerCards[index] > v.countPlayerCards and v.isInTable then
                        payBet(v.playerId, v.betAmount, "lose")
                    elseif countDealerCards[index] < v.countPlayerCards and v.isInTable then
                        payBet(v.playerId, v.betAmount, "win")
                    elseif countDealerCards[index] == v.countPlayerCards and v.isInTable then
						payBet(v.playerId, v.betAmount, "push")
                    end
                    TriggerClientEvent('ak_blackjack:GameFinished', v.playerId, true)
                else
                    payBet(v.playerId, v.betAmount, "")
                end
            end
            Citizen.Wait(3000)
            checkPlayers(index)
            addPlayerInGame(index)
        end
        addPlayerInGame(index)
        resetGame(index)
    end
    isBlackjackActivated[index] = false
	end)
end


function payBet(playerId, money, condition)
    local src = playerId
    local Player = exports['qbr-core']:GetPlayer(src)
    if Config.Prints then
        print(tostring(money) .. " " .. tostring(condition))
    end
    local money2 = money*2
    if condition == "lose" then
        TriggerClientEvent('QBCore:Notify', src, 8, 'Dealer Won!', 5000, 'Dealer won you lost $'..money, 'mp_lobby_textures', 'cross', 'COLOR_RED')
    elseif condition == "win" then
        TriggerClientEvent('QBCore:Notify', src, 8, 'Blackjack', 5000, 'You Won $'..money2, 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
        Player.Functions.AddMoney("cash", money2, "Blackjack")
    elseif condition == "push" then
        TriggerClientEvent('QBCore:Notify', src, 8, 'Blackjack', 5000, "Push! Take your Money Back", 'mp_lobby_textures', 'cross', 'COLOR_WHITE')
        Player.Functions.AddMoney("cash", money, "Blackjack")
    end
end






function getNumber(card,hasAce)
    local value = 0
    if string.len(card) == 3 then
        value = 10
    else
        if string.sub(card,1, 1) == "1" and not hasAce then
            value = 11
        else
            value = tonumber(string.sub(card, 1, 1))
        end
    end
    return value
end

function resetGame(index)
    startedGame[index] = false
    dealerCards[index] = {}
    dealerHasAce[index] = false
    dealerFakeBust[index] = false
    countDealerCards[index] = 0
    for i, v in ipairs(playersData[index]) do
        v.playerCards = {}
        v.continue = false
        v.playerHasAce = false
        v.playerFakeBust = false
        v.countPlayerCards = 0
        v.betAmount = 0
        TriggerClientEvent('ak_blackjack:Reset_Game_Var', v.playerId)
    end
end

Citizen.CreateThread(function()
    math.randomseed(os.clock()*100000000000)
end)

function randomCard()
    local n = math.random(4)
    local seed = ""
    if n == 1 then
        seed = "H"
    elseif n == 2 then
        seed = "S"
    elseif n == 3 then
        seed = "C"
    elseif n == 4 then
        seed = "D"
    end
    return tostring(math.random(13))..seed
end

function peekCard(type, playerId , index)
    card = randomCard()
    if Config.Prints then
	    print(card)
    end
    if (type == "player") then
        for i, v in ipairs(playersData[index]) do
            if (playerId == v.playerId) then
                v.countPlayerCards = v.countPlayerCards+getNumber(card,v.playerHasAce)
                if getNumber(card, v.playerHasAce) == 11 then
                    v.playerHasAce = true
                end
                if v.countPlayerCards > 21 and v.playerHasAce and not v.playerFakeBust then
                    v.countPlayerCards = v.countPlayerCards-10
                    v.playerFakeBust = true
                end
                break
            end
        end
    else
        countDealerCards[index] = countDealerCards[index]+getNumber(card,dealerHasAce[index])
        if getNumber(card, dealerHasAce[index]) == 11 then
            dealerHasAce[index] = true
        end
        if countDealerCards[index] > 21 and dealerHasAce[index] and not dealerFakeBust[index] then
            countDealerCards[index] = countDealerCards[index]-10
            dealerFakeBust[index] = true
        end
    end
    return card
end

function checkPlayers(index)
    for i, v in ipairs(playersData[index]) do
        if v.isInTable == false then
            table.remove(playersData[index], i)
        end
    end
end

function addPlayerInGame(index)
    for i, v in ipairs(waitingPlayers[index]) do
        table.insert(playersData[index], {playerId = v.playerId, playerCards={}, continue=false, playerHasAce=false, playerFakeBust=false, countPlayerCards=0, betAmount = 0, isInTable = true})
        table.remove(waitingPlayers[index], i)
    end
end


RegisterNetEvent('ak_blackjack:Choice')
AddEventHandler('ak_blackjack:Choice', function(choice , index)
    for i, v in ipairs(playersData[index]) do
        if v.playerId == source then
            v.continue = choice
            break
        end
    end
end)

RegisterNetEvent('ak_blackjack:Request_Sit')
AddEventHandler('ak_blackjack:Request_Sit', function(index)
    table.insert(waitingPlayers[index], {playerId = source})
    if not isBlackjackActivated[index] then
        startGame(index)
    end
end)

RegisterNetEvent('ak_blackjack:Request_Leave')
AddEventHandler('ak_blackjack:Request_Leave', function(index)
    for i, v in ipairs(playersData[index]) do
        if v.playerId == source then
            v.isInTable = false
        end
    end
    for i, v in ipairs(waitingPlayers[index]) do
        if v.playerId == source then
            table.remove(waitingPlayers[index], i)
        end
    end
end)

RegisterNetEvent('ak_blackjack:Get_Bet')
AddEventHandler('ak_blackjack:Get_Bet', function(bet , index)
if index ~= nil then
    for i, v in ipairs(playersData[index]) do
        if v.playerId == source then
            local Player = exports['qbr-core']:GetPlayer(source)

            local playercash = Player.PlayerData.money["cash"]
            if playercash >= bet then
                Player.Functions.RemoveMoney("cash", bet, "Blackjack")
                v.betAmount = bet
            else
                v.betAmount = 0
            end

        end
    end
end
end)

AddEventHandler('playerDropped', function(reason)
for index =1,10 do

    for i, v in ipairs(playersData[index]) do
        if v.playerId == source then
            v.isInTable = false
        end
    end
    for i, v in ipairs(waitingPlayers[index]) do
        if v.playerId == source then
            table.remove(waitingPlayers[index], i)
        end
    end
	end
end)
