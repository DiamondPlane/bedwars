bedwars = {}
bedwars.team_colors = {red="#e32727",blue="#0000FF",green="#64f20b",yellow="#FFFF00"}
bedwars.teams = {red = {},blue = {},green = {},yellow = {}}
bedwars.hud = {}
bedwars.hud.players = {}

bedwars.storage = minetest.get_mod_storage()

bedwars.max_players_per_team = 8 -- total of 32 players
bedwars.min_players_for_round = 4
bedwars.round_started = false

bedwars.countdown_time = 5

function bedwars.log(msg)
	if not msg then return end
	minetest.log("action", "[bedwars] " .. msg)
end

function bedwars.assign_team(pname)
	local team_count = bedwars.max_players_per_team
	local smallest_team = "red"
	for t_name,p_table in pairs(bedwars.teams) do
		if #p_table < team_count then
			team_count = #p_table
			smallest_team = t_name
		end
	end
	table.insert(bedwars.teams[smallest_team], pname)
	minetest.get_player_by_name(pname):set_nametag_attributes({color=bedwars.team_colors[smallest_team], text = pname})

	-- TODO teleport the player to spawn point
	return smallest_team
end

function bedwars.get_player_team(pname)
	for t_name, t_table in pairs(bedwars.teams) do
		if table.indexof(t_table, pname) >= 1 then
			return t_name
		end
	end
	return nil
end

function bedwars.init_teams()
	-- TODO add random selection
	for _,player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local team = bedwars.assign_team(pname)
		minetest.chat_send_player(pname, "You have joined "..minetest.colorize(bedwars.team_colors[team], team).." team!")
	end
	bedwars.log("Teams Initialized!")
end

function bedwars.clear_teams()
	for i in pairs(bedwars.teams) do
		bedwars.teams[i] = {}
	end
	for _,player in pairs(minetest.get_connected_players()) do
		player:set_nametag_attributes({color="#ffffff", text = player:get_player_name()})
	end
	bedwars.log("Teams Cleared!")
end

function bedwars.init_countdown()
	bedwars.log("Countdown Started!")
	bedwars.countdown = bedwars.countdown_time

	for _, p in pairs(minetest.get_connected_players()) do
		bedwars.hud.players[p:get_player_name()]["countdown_"..tostring(bedwars.countdown)] = p:hud_add({
			hud_elem_type = "image",
			position = {x=0.5, y=0.5},
			name = "countdown_timer",
			scale = {x = 2, y = 2},
			text = "countdown_"..tostring(bedwars.countdown)..".png",
			number = 0x00FF00,
			alignment = {x=0, y=0},
			size = {x = 20, y = 20},
			z_index = 100
		})
		p:hud_set_flags({crosshair=false})
	end
	minetest.after(1, bedwars.countdown_tick)
end

function bedwars.countdown_tick()
	bedwars.countdown = bedwars.countdown - 1

	for _, p in pairs(minetest.get_connected_players()) do
		local hud_ids = bedwars.hud.players[p:get_player_name()]
		if hud_ids["countdown_"..bedwars.countdown+1] then
			p:hud_remove(hud_ids["countdown_"..bedwars.countdown+1])
		end
		if bedwars.countdown == 0 then
			p:hud_set_flags({crosshair=true})
		else
			hud_ids["countdown_"..bedwars.countdown] = p:hud_add({
				hud_elem_type = "image",
				position = {x=0.5, y=0.5},
				name = "countdown_timer",
				scale = {x = 2, y = 2},
				text = "countdown_"..tostring(bedwars.countdown)..".png",
				number = 0x00FF00,
				alignment = {x=0, y=0},
				size = {x = 20, y = 20},
				z_index = 100,
			})
		end
	end
	if bedwars.countdown == 0 then
		return
	end
	minetest.after(1, bedwars.countdown_tick)
end

local function init_round()
	bedwars.round_started = true
	bedwars.init_world()
	bedwars.init_countdown()
	bedwars.init_teams()

	minetest.after(6, function ()
		bedwars.clear_teams()
	end)
end

minetest.register_on_joinplayer(function(player)
	-- TODO send to lobby
	bedwars.hud.players[player:get_player_name()] = {}
	if bedwars.round_started then
		return
	end
	if not bedwars.countdown and #minetest.get_connected_players() >= bedwars.min_players_for_round then
		init_round()
	end
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	bedwars.hud.players[pname] = {}
	bedwars.teams[bedwars.get_player_team(pname)] = nil
end)
