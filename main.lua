#!/usr/bin/env lua
--[[
# TODO:
- get token from environment variable
- token argparse parameter
--]]
local TOKEN = ""
local api = require("telegram-bot-lua.core").configure(TOKEN)
local mfr = require("mfr")
local utils = {}
local logic = {}

function utils.is_command(text)
	if text:sub(1, 1) == "/" then
		return true
	end
	return false
end

function utils.send_silent_reply(chat_id, text, reply_to_message_id,
		reply_markup)
	return api.send_message(chat_id, text, nil, true, true,
		reply_to_message_id, reply_markup)
end

function utils.parse_command(text)
	local text = mfr.space_split(text)
	return text[1], {table.unpack(text, 2)}
end

function utils.ban(message)
	local chat_id, user_id = message.chat.id, message.from.id
	local sender = api.get_chat_member(message.chat.id, message.from.id)
	local bad_message = message.reply_to_message
	local text, username
	if not sender.can_restrict_members and not sender.status == "creator" then
		text = "not enough rights to ban & kick"
		return utils.send_silent_reply(chat_id, text, message.message_id)
	end
	bad_message = message.reply_to_message
	if bad_message then
		api.ban_chat_member(bad_message.chat.id, bad_message.from.id)
		text = "banned: " .. bad_message.from.username
		return utils.send_silent_reply(chat_id, text, message.message_id)
	end
	return utils.send_silent_reply(chat_id,
		"pls answer to message of one you want to ban", message.message_id)
end

function logic.perform_command(message)
	mfr.pprint(message)
	if message.text:sub(1, 4) == "/ban" then
		return utils.ban(message)
	end
end

function logic.perform_plain_text(message)
	if message.text:match("ping") then
		local keyboard = api.inline_keyboard()
		:row(api.row()
		:callback_data_button("pong", "pong"))
		mfr.pprint(message)
		--print(message.chat.id, message.from.id)
		--mfr.pprint(api.get_chat_member(message.chat.id, message.from.id))
		--mfr.pprint(api.get_chat_administrators(message.chat.id))
		api.send_message(message.chat.id,  -- chat id
			"pong",  -- text
			nil,  -- parse_mode
			true,  -- disable_web_page_preview
			false,  -- disable_notification
			message.id,  -- reply_to_message_id
			keyboard)  -- reply_markup
	end
end

function api.on_message(message)
	if not message.text then return end
	if utils.is_command(message.text) then
		logic.perform_command(message)
	else
		logic.perform_plain_text(message)
	end
	--[[
	elseif message.text:sub(1, 1) == "/" then
		command, args = utils.parse_command(message.text)
		if not command then return end
		if message.chat.type == 'private' then ; end
		api.send_message(
			message.chat.id,
			"abobadjkfbkdasbf"
		)
	end
	--]]
end


function api.on_channel_post(channel_post)
	if channel_post.text and channel_post.text:match("ping") then
		api.send_message(channel_post.chat.id, "pong")
	end
end

api.run()
