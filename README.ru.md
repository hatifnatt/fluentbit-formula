<!-- omit in toc -->
# fluentbit formula

Формула для установки и настройки `Fluent Bit`.

* [Использование](#использование)
* [Доступные стейты](#доступные-стейты)
  * [fluentbit](#fluentbit)
  * [fluentbit.install](#fluentbitinstall)
  * [fluentbit.package](#fluentbitpackage)
  * [fluentbit.package.install](#fluentbitpackageinstall)
  * [fluentbit.package.clean](#fluentbitpackageclean)
  * [fluentbit.repo](#fluentbitrepo)
  * [fluentbit.repo.install](#fluentbitrepoinstall)
  * [fluentbit.repo.clean](#fluentbitrepoclean)
  * [fluentbit.clean](#fluentbitclean)
  * [fluentbit.prepare](#fluentbitprepare)
  * [fluentbit.config](#fluentbitconfig)
  * [fluentbit.config.lua\_scripts](#fluentbitconfiglua_scripts)
  * [fluentbit.config.sites](#fluentbitconfigsites)
  * [fluentbit.config.check](#fluentbitconfigcheck)
  * [fluentbit.service](#fluentbitservice)
  * [fluentbit.service.clean](#fluentbitserviceclean)

## Использование

* Создаем pillar с данными, см. [`pillar.example`](pillar.example) в качестве примера, привязываем его к хосту в pillar top.sls.
* Применяем стейт на целевой хост `salt 'server-01*' state.sls fluentbit saltenv=base pillarenv=base`.
* Применить формулу к хосту в state top.sls, для ее выполнения при запуске `state.highstate`.

## Доступные стейты

### fluentbit

Основной стейт выполнит все остальные стейты.

### fluentbit.install

Данный стейт отвечает за установку пакета `fluentbit` или пакетов из списка `fluentbit:package:pkgs`, фактически вызывает `fluentbit.package.install`.

### fluentbit.package

Вызывает [`fluentbit.package.install`](#fluentbitpackageinstall).

### fluentbit.package.install

Данный стейт отвечает за установку пакета `fluentbit` или пакетов из списка `fluentbit:package:pkgs`. Если `fluentbit:use_upstream` равно `repo` или `package`  и `fluentbit:use_official_repo` равно `true` перед установкой пакетов будет подключен официальный репозиторий fluentbit, будет вызван стейт [`fluentbit.repo.install`](#fluentbitrepoinstall).

### fluentbit.package.clean

Удаляет из системы пакет `fluentbit` или несколько пакетов из списка `fluentbit:package:pkgs`. Так же вызывает стейты [`fluentbit.service.clean`](#fluentbitserviceclean), [`fluentbit.repo.clean`](#fluentbitrepoclean).

### fluentbit.repo

В зависимости от параметра `fluentbit:use_official_repo`:

* `true` (значение по умолчанию) подключит официальный репозиторий, вызывает [fluentbit.repo.install](#fluentbitrepoinstall)
* `false` официальный репозиторий не будет настроен, установить пакеты скорее всего не удастся, их нет в репозиториях большинства ОС

### fluentbit.repo.install

Стейт для настройки официального репозитория <https://docs.fluentbit.io/manual/installation/downloads/linux>

### fluentbit.repo.clean

Стейт для удаления файлов конфигурации репозитория.

### fluentbit.clean

Вызывает `fluentbit.package.clean`

Удаляет пакеты fluentbit из системы, отключает запуск сервиса `fluentbit` при загрузке ОС и останавливает его, удаляет из системы конфигурацию репозитория.

### fluentbit.prepare

Вспомогательные стейт для настройки рабочего окружения

### fluentbit.config

Стейт для управления основным файлом конфигурации (обычно `fluent-bit.conf` или `fluent-bit.yaml`) и дополнительными конфигурациями вроде `parsers/custom_parser.conf`, `inputs/*.conf` или `filters/*.yaml`

### fluentbit.config.lua_scripts

Стейт для управления Lua скриптами. Lua скрипты позволяют выполнять продвинутую обработку данных.

### fluentbit.config.sites

Стейт управления "сайтами". Сайт обычно представляет собой конфигурационный файл из одного блока `server`, который сохраняется в `/etc/fluentbit/sites-available`, при этом сам конфигурационный файл не подключен в основном конфиге `fluentbit` для его подключения необходимо создать символическую ссылку в каталоге `/etc/fluentbit/sites-enabled`. Благодаря подобной структуре имеется возможность включать и отключать сайты не трогая сам файл конфигурации, а только создавая / удаляя символическую ссылку.

### fluentbit.config.check

Вспомогательный стейт для проверки валидности конфигурации. Не предусматривает ручного вызова, используется в других стейтах через `include`.

### fluentbit.service

Стейт для управления сервисом `fluentbit` запуск / остановка сервиса, включения / отключение сервиса при загрузке ОС

Поддерживает перезагрузку конфигурации без остановки сервиса (`systemctl reload fluent-bit`) при включенной опции `fluentbit:service:reload: true`.
Для корректной работы перезагрузки конфигурации необходимо, чтобы аргумент `--enable-hot-reload` был добавлен к команде запуска Fluent Bit.
Этот аргумент автоматически добавляется при включении `fluentbit:service:reload: true`, независимо от значений в `fluentbit:service:args`.
Аргумент `--enable-hot-reload` добавляется до аргументов из `fluentbit:service:args`, обеспечивая корректную работу функции перезагрузки.

### fluentbit.service.clean

Данный стейт отключает запуск сервиса `fluentbit` при загрузке ОС и останавливает его.
