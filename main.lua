#!/usr/bin/env lua
--[[
# TODO:
- get token from environment variable
- token argparse parameter
--]]
local TOKEN = ""
local http = require("socket.http")
local url = require("socket.url")
local api = require("telegram-bot-lua.core").configure(TOKEN)
local mfr = require("mfr")
local utils = {}
local logic = {}
local raw_api_calls = {}

function utils.send_silent_reply(chat_id, text, reply_to_message_id,
		reply_markup)
	return api.send_message(chat_id, text, "Markdown", true, true,
		reply_to_message_id, reply_markup)
end
		--[[api.send_message(message.chat.id,  -- chat id
			"pong",  -- text
			nil,  -- parse_mode
			true,  -- disable_web_page_preview
			false,  -- disable_notification
			message.id,  -- reply_to_message_id
			keyboard)  -- reply_markup
		--]]

function utils.parse_command(text)
	local text = mfr.space_split(text)
	return {text[1], table.unpack(text, 2)}
end

function utils.check_admin(member_data)
	local text
	local can_restrict = member_data.result.can_restrict_members or false
	local is_creator = member_data.result.status == "creator"
	if not can_restrict and not is_creator then
		return false
	else
		return true
	end
end

function raw_api_calls.get_user_info(message)
	local target_message = message.reply_to_message
	local chat_id = message.chat.id
	if not target_message then
		return utils.send_silent_reply(chat_id,
			"pls answer to message",
			message.message_id)
	end
	local data = api.get_chat_member(target_message.chat.id,
		target_message.from.id)
	data = data.result
	data = "``` " .. mfr.prettify_table(data) .. " ```"
	return api.send_message(chat_id, data, "Markdown",
		true,  -- disable_web_page_preview
		true,  -- disable_notification
		message.message_id)
end

function raw_api_calls.get_chat_administrators(message)
	local chat_id = message.chat.id
	local data = api.get_chat_administrators(chat_id).result
	data = "``` " .. mfr.prettify_table(data) .. " ```"
	return api.send_message(chat_id, data, "Markdown", true, true,
		message.message_id)
end

function raw_api_calls.get_chat_members_count(message)
	local chat_id = message.chat.id
	local data = api.get_chat_members_count(chat_id).result
	return utils.send_silent_reply(chat_id, data, message.message_id)
end

function utils.ban(message, kick)
	local kick = kick == true or false
	local chat_id, user_id = message.chat.id, message.from.id
	local sender = api.get_chat_member(message.chat.id, message.from.id)
	local bad_message = message.reply_to_message
	local text, username, ban_suspect
	if not utils.check_admin(sender) then
		return
	end
	if not bad_message then
		return utils.send_silent_reply(chat_id,
			"pls answer to message of one you want to remove",
			message.message_id)
	end
	ban_suspect = api.get_chat_member(bad_message.chat.id, bad_message.from.id)
	if utils.check_admin(ban_suspect) then
		return utils.send_silent_reply(chat_id,
			"ban suspect is an admin. remove admin rights first",
			message.message_id)
	end
	if kick then
		api.kick_chat_member(bad_message.chat.id, bad_message.from.id)
		return utils.send_silent_reply(chat_id,
			"kicked: " .. bad_message.from.username, message.message_id)
	end
	api.ban_chat_member(bad_message.chat.id, bad_message.from.id)
	return utils.send_silent_reply(chat_id,
		"banned: " .. bad_message.from.username, message.message_id)
end

function utils.cowsay(message)
	local chat_id, user_id = message.chat.id, message.from.id
	local sender = api.get_chat_member(message.chat.id, message.from.id)
	mfr.pprint(message)
	local bad_message_text = message.reply_to_message.text
	local address = "http://cowsay.morecode.org/say?message="
	address = address .. url.escape(bad_message_text) .. "&format=text"
	print(address)
	local body, code, headers, status = http.request(address)
	body = url.unescape(body):sub(2)
	return utils.send_silent_reply(chat_id, "``` " .. body .. " ```",
		message.message_id)
end

function utils.send_ping(message)
	local keyboard = api.inline_keyboard()
		:row(api.row()
		:callback_data_button("pong", "pong")
		:callback_data_button("pong", "pong"))
		return utils.send_silent_reply(message.chat.id, "pong",
			message.message_id, keyboard)
end

function logic.perform_command(message)
	local command = utils.parse_command(message.text)
	if command[1] == "/ban" then
		return utils.ban(message)
	elseif command[1] == "/kick" then
		return utils.ban(message, true)
	elseif command[1] == "/ping" then
		return utils.send_ping(message)
	elseif command[1] == "/cowsay" then
		return utils.cowsay(message)
	elseif command[1] == "/raw_api" then
		if command[2] == "get_user" then
			return raw_api_calls.get_user_info(message)
		elseif command[2] == "get_chat_administrators" then
			return raw_api_calls.get_chat_administrators(message)
		elseif command[2] == "get_chat_members_count" then
			return raw_api_calls.get_chat_members_count(message)
		end
	end
end

function logic.perform_plain_text(message)
	if message.text == "ping" then
		utils.send_ping(message)
	end
end

function api.on_message(message)
	if not message.text then  -- currently support only text messages
		return
	end
	mfr.pprint(message)
	if message.text:sub(1, 1) == "/" then
		return logic.perform_command(message)
	end
	return logic.perform_plain_text(message)
end


function api.on_channel_post(channel_post)
	if channel_post.text and channel_post.text:match("ping") then
		api.send_message(channel_post.chat.id, "pong")
	end
end

api.run()
