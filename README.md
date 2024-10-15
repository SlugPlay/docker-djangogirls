<h3 align="center">Тестовое задание для Студенческого проекта "Цифровой Офис"</h3>
<h3 align="center">Проект доступен по адресу: <a href="http://185.128.106.162:80" target="_blank">http://185.128.106.162:80</a></h3>

<br></br>

### Шаг 0 - Анализ

Для начала нужно понять какими мощностями мы располагаем, чтобы понять какой проект разворачивать:
```bash
$ free -h # Смотрим сколько RAM у нас имеется
$ df -h # Смотрим сколько дискового пространства имеется
```
Спустя некоторое время поисков, я остановился на Django-приложении: `djangogirls`.
Оригинальный репозиторий располагается по [этому адресу](https://github.com/DjangoGirls/djangogirls/tree/main)

<br></br>

---
<p><strong>‼️ Важно!</strong></p>

Я форкнул репозиторий себе, вычистил оттуда уже готовые `Dockerfile` и `docker-compose.yml` и вставил свои. 
Также исправил один файл для транслировании порта `80`, а не `8000`, как это было указано в оригинальном репозитории.
[Вот ссылка на этот репозиторий ](https://github.com/SlugPlay/djangogirls-edited)

---
<br></br>


### Шаг 1 - Подготовка

#### Начальная настройка
Заходим на ВМ и выполним подготовительные мероприятия:
```bash
$ useradd workuser -d /home/workuser 
# Добавим нового пользователя, из-под которого будем выполнять все действия 

$ mkdir /home/workuser 
# Создадим ему домашнюю директорию

$ nano /etc/sudoers 
# Подправим права пользователю для удобства использования команды "sudo"

$ su - workuser
# Зайдём на пользователя
```

Обновим списки пакетов и установим git:
```bash
$ sudo apt update

$ sudo apt install git
```

#### docker и docker-compose

 Установим Docker на машину:
```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
# Установим нужные пакеты

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Добавим GPG ключ

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# Добавим репозиторий Docker-а

sudo apt update
# Обновим списки пакетов

sudo apt install docker-ce -y
# Установим Docker из добавленного репозитория

sudo systemctl status docker
# Проверим работоспособность

sudo usermod -aG docker ${USER}
# Добавим пользователя в группу "docker"

```

#### Финальная проверка 
```bash
git --version
git version 2.34.1

docker --version
Docker version 27.3.1, build ce12230
```

<br></br>
<br></br>

### Шаг 2 - Поднимаем приложение

Теперь дело за малым:
```bash
$ git clone https://github.com/SlugPlay/djangogirls-edited.git
# Качаем репозиторий с нашими Dockerfile и docker-compose.yml

$ cd djangogirls-edited/
# Заходим в проект

$ sudo docker compose up
# Поднимаем с помощью docker compose приложение и отсматриваем логи

$ sudo docker compose up -d
# Убедившись, что всё хорошо - запускаем в detouch режиме и идём отдыхать
```

### Разбор Dockerfile
```Dockerfile
# Берем версию питона, которая указана в документации к сайту. Плюсом берём версию поменьше, чтобы снизить вес образа
FROM python:3.10-slim

# Обновляем пакеты и устанавливаем нужные для комплияции и сборки проекта
RUN apt-get update &&\
    apt install -y libpq-dev \
         gcc \
         npm \
         gulp \
         gettext

# Копируем проект и задаём WORKDIR
COPY . ./app
WORKDIR /app

# Создаём виртуальное окружение, так как оно понадобится нам для "pip-sync"
RUN python3 -m venv /opt/venv 
ENV PATH="/opt/venv/bin:$PATH"

# Устанавливаем все необходимые зависимости
RUN pip install --upgrade pip &&\
    pip install pip-tools &&\
    pip-sync &&\
    npm install &&\
    gulp local

# Даём контейнеру на вход скрипт с парой нужных команд для иницилизации проекта
ENTRYPOINT ["/app/rootfs/entrypoint.sh"]
```


### Разбор docker-compose.yml
```yaml
services:
  web:
    build: . # Собираем наш Dockerfile
    ports:
      - "80:80" # Открываем порты 
    environment: # Задаём виртуальные переменные для рабочего пользователя
      - POSTGRES_HOST=db
      - POSTGRES_USER=appuser
      - POSTGRES_PASSWORD=appuser
      - POSTGRES_PORT=5432
      - POSTGRES_DB=djangogirls
    depends_on:
      db:
        condition: service_healthy # Приказываем приложению дождаться БД
  db:
    image: postgres:17 # Берем PostgreSQL
    ports:
      - "5432:5432" # Открываем порты
    environment: # Задаём переменные для иницилизации таблицы и пользователя
      - POSTGRES_DB=djangogirls
      - POSTGRES_USER=appuser
      - POSTGRES_PASSWORD=appuser
    healthcheck: # Проверяем когда поднимается БД, чтобы дать сигнал приложению
      test: ["CMD-SHELL", "sh -c 'pg_isready -U appuser -d djangogirls'"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    volumes:
      - postgres_data:/var/lib/postgresql/data # Сохраняем данные снаружи
volumes:
  postgres_data:
```

<br></br>

### Вывод
Для меня неожиданно, но образ весит **1.49ГБ** - это довольно много. Можно уменшить размер при углублении в эту тему.
На самом деле проблем хватало при подъеме этого приложения, но это только плюс. Теперь хочется поднять что-нибудь большое из opensource проектов.
