import telebot
import datetime
import time
from config import *

bot = telebot.TeleBot(token)
# Shorten some code
answer = bot.reply_to
send = bot.send_message


@bot.message_handler(commands=['ping'])
def ping(message):
    answer(message, f"{good}pong")


@bot.message_handler(commands=['tm'])
def tm(message):
    answer(message, f"{good}{time.time()}")


@bot.message_handler(content_types=['new_chat_members'])
def new_member(message):
    answer(message, f"{good}What's up!")


@bot.message_handler(commands=['timer'])
def timer(message):
    try:
        delta = int(message.text.split()[1])
    except IndexError:
        answer(message, f"{bad}No time value provided")
        return
    start = datetime.datetime.now()
    answer(message, f"{good}Count {delta} secs since {start}")
    time.sleep(delta)
    send(message.chat.id, f"{good}Your timer is ringing\n{delta} secs have passed since {start}")


@bot.message_handler(commands=['time'])
def show_time(message):
    send(message.chat.id, f"{good}{datetime.datetime.now()}")


if __name__ == '__main__':
    bot.infinity_polling()
