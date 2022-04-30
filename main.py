from threading import Thread
import telebot
from copy import copy
from time import sleep
from datetime import datetime as dt
from os import environ, system
from requests import request

_search = {'yandex.ru': 'https://yandex.ru/?q=',
           'www.google.com': 'https://www.google.com/search?q=',
           'www.duckduckgo.com': 'https://duckduckgo.com/?q=',
           'm.wikipedia.org': 'https://m.wikipedia.org/w/index.php?search=',
           'm.youtube.com': 'https://m.youtube.com/results?search_query='}
__search = {'yandex.ru': _search['yandex.ru'], 'www.google.com': _search['www.google.com']}


class MessageInterpretation:
    @staticmethod
    def prepare_for_request(text: str) -> str:
        return "+".join(text.split()[1:])

    @staticmethod
    def get_message_contents(message):
        return " ".join(message.text.split()[1:])


get_message_contents = MessageInterpretation.get_message_contents
prepare_for_request = MessageInterpretation.prepare_for_request
token = str(environ.get('token'))
good = "✅ "
bad = "❌ "
bullet_points = {'shield': '🔰 ', 'red': '🔴 ', 'orange': '🟧 '}
bullet = bullet_points['orange']
ex = f"{bad}Some error appeared"
bot = telebot.TeleBot(token)
answer = bot.reply_to
send = bot.send_message


@bot.message_handler(commands=['ping'])
def ping(message):
    answer(message, f"{good}pong")


@bot.message_handler(commands=['datatime'])
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
    link_contents = prepare_for_request(message.text)
    content = get_message_contents(message)
    output = []
    for name, engine in __search.items():
        output += [f'<a href="{engine}{link_contents}">{bullet} {name}: {content}</a>\n']
    bot.send_message(message.chat.id,
                     "".join(output),
                     disable_web_page_preview=True,
                     parse_mode='HTML')


@bot.message_handler(commands=['full'])
def full_search(message):
    body = prepare_for_request(message.text)
    target = message.text[message.text.find(' '):]
    output = []
    for name, engine in _search.items():
        output += [f'<a href="{engine}{body}">{bullet} {name}: {target}</a>\n']
    bot.send_message(message.chat.id, "".join(output),
                     disable_web_page_preview=True,
                     parse_mode='HTML')


@bot.message_handler(commands=['translate'])
def translate(message):
    got = get_message_contents(message)
    payload = copy(got)
    payload.replace(',', '%2C')
    payload.replace(' ', '%20')
    payload = 'q=' + got + '&target=ru&source=en'
    url = "https://google-translate1.p.rapidapi.com/language/translate/v2"
    headers = {"content-type": "application/x-www-form-urlencoded",
               "Accept-Encoding": "application/gzip",
               "X-RapidAPI-Host": "google-translate1.p.rapidapi.com",
               "X-RapidAPI-Key": "f540c0abcamsh836715aadf0b8eap144ccajsn4f2f3c37c548"}
    response = request("POST", url, data=payload, headers=headers)
    answer(message, response.json()['data']['translations'][0]['translatedText'])



def auto_fetch():
    while True:
        system('git pull')
        sleep(3600)


if __name__ == '__main__':
    Thread(target=bot.infinity_polling).start()

    # Comment this function when testing!
    Thread(target=auto_fetch).start()
