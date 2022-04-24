from threading import Thread
import telebot
from time import sleep
from datetime import datetime as dt
from os import environ, system

token = str(environ.get('token'))
good = "✅ "
bad = "❌ "
ex = f"{bad}Some error appeared"
bot = telebot.TeleBot(token)
answer = bot.reply_to
send = bot.send_message


@bot.message_handler(commands=['ping'])
def ping(message):
    answer(message, f"{good}pong")


@bot.message_handler(commands=['tm'])
def tm(message):
    answer(message, f"{good}{dt.now()}")


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
    start = dt.now()
    answer(message, f"{good}Count {delta} secs since {start}")
    sleep(delta)
    send(message.chat.id, f"{good}Your timer is ringing\n{delta} secs have passed since {start}")


@bot.message_handler(commands=['search'])
def search(message):
    link_contents = " ".join(message.text.split()[1:])
    g = f'https://yandex.ru/?q={link_contents}' + '\n\n' + \
        f'https://www.google.com/search?q={link_contents}'
    bot.send_message(message.chat.id, g, disable_web_page_preview=True)
    # Send yourself: bot.send_message(message.from_user.id, f"https://yandex.ru/?q={link_contents}")


@bot.message_handler(commands=['anywhere', 'fsearch', 'full'])
def full_search(message):
    link_contents = " ".join(message.text.split()[1:])
    engines = ['https://yandex.ru/?q=',
               'https://www.google.com/search?q=',
               'https://duckduckgo.com/?q=',
               'https://m.wikipedia.org/w/index.php?search=',
               'https://m.youtube.com/results?search_query=',
               'https://discord.com/guild-discovery?query=']
    g = "\n\n".join(list(map(lambda x: x + link_contents, engines)))
    bot.send_message(message.chat.id, g, disable_web_page_preview=True)


"""@bot.message_handler(commands=['translate'])
def full_search(message):
    link_contents = " ".join(message.text.split()[1:])
    # TODO"""


def auto_fetch():
    while True:
        system('git pull')
        sleep(3600)


if __name__ == '__main__':
    Thread(target=bot.infinity_polling).start()

    # Comment this function when testing!
    Thread(target=auto_fetch).start()
