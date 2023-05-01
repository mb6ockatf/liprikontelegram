#!/usr/bin/env python3

from os import getenv
from logging import basicConfig, INFO
from aiogram import Bot, Dispatcher, executor, types

basicConfig(level=INFO)
api_token = getenv("API_TOKEN")
bot = Bot(token=api_token)
dispatcher = Dispatcher(bot)


@dispatcher.message_handler(commands=["start", "help"])
async def send_welcome(message: types.Message):
    text = """This is Python bot, powered by aiogram"""
    await message.reply(text)
    await message.delete()


@dispatcher.message_handler(commands=["cowsay"])
async def cowsay(message: types.Message):
    text = message.get_args()
    await message.reply(text)
    await message.delete()


@dispatcher.message_handler()
async def echo(message: types.Message):
    await message.answer_dice("🎲")


if __name__ == "__main__":
    executor.start_polling(dispatcher, skip_updates=True)
