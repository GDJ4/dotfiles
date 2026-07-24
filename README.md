# macOS dotfiles

Набор конфигураций для macOS: тайлинговый оконный менеджер, горячие клавиши,
верхняя панель, терминал и несколько удобных CLI-инструментов.

Это не готовый установщик «в одну команду», а набор настроек. Программы,
сервисы и системные разрешения устанавливаются отдельно, а этот каталог
подключается к стандартным путям macOS.

> Важно: конфигурация рассчитана на macOS и клавиатуру с английской раскладкой
> для буквенных хоткеев. Перед установкой прочитайте раздел
> [«Что здесь запущено»](#что-здесь-запущено) и выберите только один оконный
> менеджер.

## Содержание

- [Что здесь запущено](#что-здесь-запущено)
- [Быстрый старт](#быстрый-старт)
- [Зависимости](#зависимости)
- [Установка модулей](#установка-модулей)
- [Горячие клавиши](#горячие-клавиши)
- [Что умеет SketchyBar](#что-умеет-sketchybar)
- [Приватность и личные данные](#приватность-и-личные-данные)
- [Проверка и перезапуск](#проверка-и-перезапуск)
- [Частые проблемы](#частые-проблемы)
- [Структура каталога](#структура-каталога)

## Что здесь запущено

### Основной вариант: yabai + skhd + SketchyBar

Это наиболее связная часть набора:

- **yabai** раскладывает окна плиткой, управляет рабочими столами и умеет
  переключать окна с клавиатуры;
- **skhd** перехватывает глобальные хоткеи и передаёт команды yabai;
- **SketchyBar** заменяет стандартную строку меню и показывает рабочие столы,
  активное приложение, дату, Wi‑Fi/VPN, батарею, громкость, CPU и обновления
  Homebrew;
- **Alacritty** — быстрый терминал, который открывается отдельной клавишей.

### Альтернативный вариант: AeroSpace

`aerospace/aerospace.toml` — отдельный i3-подобный оконный менеджер. Он уже
содержит собственные хоткеи и может работать без yabai и skhd.

Не запускайте одновременно `yabai` и AeroSpace: оба будут пытаться управлять
одними и теми же окнами. Если выбираете AeroSpace, остановите yabai/skhd и
учтите, что текущий `SketchyBar` использует команды yabai для рабочих столов.

### Что пока не является активной конфигурацией

- `aerospace/aerospace2.toml` — альтернативный пример раскладки AeroSpace,
  не основной файл;
- `sketchybar1/` — экспериментальная Lua-версия панели;
- `sketchybar/items/github.sh` и `sketchybar/items/spotify.sh` — готовые
  необязательные элементы, но они не подключаются текущим
  `sketchybar/sketchybarrc`;
- `aerospace/skdf` — пустой файл;
- `workspaces_backup.txt` — сохранённый черновик старой Lua-конфигурации.

Для первого запуска их можно не трогать.

## Быстрый старт

### 1. Подготовить систему

Установите Xcode Command Line Tools: они нужны для сборки маленького C-helper,
который запускается SketchyBar.

```sh
xcode-select --install
```

Установите [Homebrew](https://brew.sh), если его ещё нет:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

После установки выполните команды, которые напечатает Homebrew. Обычно для
Apple Silicon это:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Для Intel Mac путь обычно `/usr/local/bin/brew`.

### 2. Разместить репозиторий

Самый простой вариант — держать этот репозиторий в `~/.config`, потому что
большинство скриптов уже ожидает именно этот путь.

Если репозиторий уже находится в `~/.config`, задайте:

```sh
DOTFILES="$HOME/.config"
```

Если он лежит в другом месте, например `~/Projects/dotfiles`, задайте:

```sh
DOTFILES="$HOME/Projects/dotfiles"
```

При внешнем расположении подключите нужные каталоги симлинками. Сначала
сделайте резервную копию существующих настроек: приведённая функция перемещает
старый каталог в файл с суффиксом `.backup-...`, а не удаляет его.

```sh
mkdir -p "$HOME/.config"

link_module() {
  module="$1"
  source_dir="$DOTFILES/$module"
  target_dir="$HOME/.config/$module"

  if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
    mv "$target_dir" "$target_dir.backup-$(date +%Y%m%d-%H%M%S)"
  fi

  ln -s "$source_dir" "$target_dir"
}

for module in aerospace alacritty btop lsd micro neofetch sketchybar skhd yabai
do
  link_module "$module"
done
```

`LS_COLORS`, `sketchybar1`, `configstore`, `flutter` и `iterm2` не нужно
подключать для базового запуска.

### 3. Установить базовые программы

```sh
brew install jq btop lsd micro switchaudio-osx gh
brew install --cask alacritty font-space-mono-nerd-font font-sf-pro
```

### 4. Выбрать оконный менеджер

Для основного варианта установите:

```sh
brew tap asmvik/formulae
brew install asmvik/formulae/yabai asmvik/formulae/skhd
```

Для AeroSpace вместо yabai/skhd установите:

```sh
brew install --cask nikitabobko/tap/aerospace
```

### 5. Установить панель

```sh
brew tap FelixKratz/formulae
brew install sketchybar borders
```

Запустите только выбранный стек, выдайте разрешения и перезапустите сервисы.
Подробные шаги находятся ниже.

## Зависимости

| Компонент | Для чего нужен | Обязателен | Установка |
| --- | --- | :---: | --- |
| Homebrew | Установка программ и сервисов | Да | [brew.sh](https://brew.sh) |
| Xcode Command Line Tools | `clang` и `make` для helper SketchyBar | Да для SketchyBar | `xcode-select --install` |
| Alacritty | Терминал | Для терминала | `brew install --cask alacritty` |
| SpaceMono Nerd Font | Шрифт Alacritty и значки | Для внешнего вида | `brew install --cask font-space-mono-nerd-font` |
| SF Pro | Шрифт SketchyBar | Желательно | `brew install --cask font-sf-pro` |
| `jq` | Разбор JSON в yabai/SketchyBar | Да для оконного стека | `brew install jq` |
| `switchaudio-osx` | Выбор аудиоустройства из панели | Опционально | `brew install switchaudio-osx` |
| `gh` | GitHub-уведомления в панели | Только для GitHub item | `brew install gh` |
| `btop` | Мониторинг ресурсов в терминале | Опционально | `brew install btop` |
| `lsd` | Более удобный `ls` | Опционально | `brew install lsd` |
| `micro` | Терминальный редактор | Опционально | `brew install micro` |

`awk`, `sed`, `grep`, `osascript`, `pmset`, `networksetup`, `ipconfig`,
`netstat`, `scutil` и `bc` используются как системные macOS-инструменты.

## Установка модулей

Ниже перечислены все каталоги, которые содержат рабочие настройки.

### Alacritty — терминал

Файл: `alacritty/alacritty.toml`

Что меняется:

- прозрачное окно с blur;
- отступы и цветовая схема City Lights-подобного вида;
- `SpaceMono Nerd Font`, размер 12;
- оконные кнопки macOS скрыты.

Установка:

```sh
brew install --cask alacritty font-space-mono-nerd-font
```

Откройте Alacritty и проверьте, что шрифт называется именно `SpaceMono Nerd
Font`. Если терминал ругается на шрифт, временно замените
`normal.family = "SpaceMono Nerd Font"` на имя установленного шрифта.

Горячая клавиша `Right Option + Return` открывает Alacritty через skhd.

### yabai — тайлинг окон

Файлы:

- `yabai/yabairc` — основная конфигурация;
- `yabai/create_spaces.sh` — оставляет по четыре рабочих стола на каждом
  мониторе;
- `yabai/auto_focus.sh` — возвращает фокус после закрытия окна;
- `yabai/yabai_apply_arc_rules.sh` — необязательное правило для Arc.

Установка:

```sh
brew tap asmvik/formulae
brew install asmvik/formulae/yabai jq
yabai --start-service
```

Разрешите `yabai` в **System Settings → Privacy & Security → Accessibility**.
Если в списке нет нужного процесса, добавьте бинарник из вывода:

```sh
which yabai
```

#### Важное предупреждение про scripting addition

В текущем `yabai/yabairc` есть команда `sudo yabai --load-sa`. Это расширенный
режим yabai: ему нужны дополнительные системные настройки, а иногда и
изменение System Integrity Protection. Не отключайте SIP и не добавляйте
строку в sudoers, если не понимаете последствия.

Репозиторий намеренно не содержит автоматического изменения `/etc/sudoers`.
Для безопасного базового запуска можно временно закомментировать строку
`sudo yabai --load-sa`; для полного режима используйте официальную инструкцию
[Installing yabai](https://github.com/koekeishiya/yabai/wiki/Installing-yabai-%28latest-release%29)
и внимательно проверьте путь и SHA-256 бинарника.

После изменения конфигурации:

```sh
yabai --restart-service
```

Если используете Arc, проверьте строку с `yabai_apply_arc_rules.sh` в
`yabai/yabairc`: в исходной конфигурации она указывает на старый путь
`~/.scripts/...`. Для этого репозитория путь должен быть
`$HOME/.config/yabai/yabai_apply_arc_rules.sh`. Сам скрипт также предполагает,
что у yabai существует Space с меткой `web`; это правило можно отключить, если
Arc вам не нужен.

### skhd — глобальные клавиши

Файл: `skhd/skhdrc`

`skhd` ничего не рисует на экране. Он слушает сочетания клавиш и запускает
команды yabai, Alacritty, Safari, VS Code и macOS.

Установка и запуск:

```sh
brew tap asmvik/formulae
brew install asmvik/formulae/skhd
skhd --start-service
```

Выдайте `skhd` разрешение в **System Settings → Privacy & Security →
Accessibility**, затем перезапустите:

```sh
skhd --restart-service
```

Если хоткеи работают из Terminal, но не работают из сервиса, проверьте, что
разрешение выдано именно бинарнику из `which skhd`, а не только Terminal.

### SketchyBar — верхняя панель

Файлы:

- `sketchybar/sketchybarrc` — точка входа;
- `sketchybar/items/` — описание элементов панели;
- `sketchybar/plugins/` — скрипты, обновляющие элементы;
- `sketchybar/colors.sh`, `sketchybar/icons.sh` — цвета и символы;
- `sketchybar/helper/` — C-helper для CPU и сетевой статистики.

Установка:

```sh
brew tap FelixKratz/formulae
brew install sketchybar borders
brew services start sketchybar
```

При первом запуске `sketchybarrc` сам собирает `sketchybar/helper/helper`.
Поэтому до запуска должны быть установлены Xcode Command Line Tools.

Текущая панель содержит:

- слева: меню Apple, рабочие столы, значок активного приложения;
- справа: дата/время, количество устаревших пакетов Homebrew, Wi‑Fi/VPN,
  батарея, громкость и загрузка CPU;
- по клику на логотип Apple: Preferences, Activity Monitor и блокировка экрана;
- по клику на дату: компактный «zen mode», скрывающий часть элементов;
- по клику на значок громкости: слайдер; правый клик или Shift-клик — выбор
  аудиовыхода.

Проверьте панель вручную, чтобы увидеть ошибки скриптов:

```sh
brew services stop sketchybar
sketchybar
```

После проверки остановите процесс `Ctrl+C` и верните сервис:

```sh
brew services start sketchybar
```

Если не отображаются иконки приложений, установите
[sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font) или
замените `sketchybar-app-font` в настройках на установленный Nerd Font.

### AeroSpace — альтернативный оконный менеджер

Файлы:

- `aerospace/aerospace.toml` — основной вариант;
- `aerospace/aerospace2.toml` — альтернативный i3-подобный пример;
- `aerospace/presentation.sh` — экспериментальный режим для презентаций.

Установка:

```sh
brew install --cask nikitabobko/tap/aerospace
brew install borders
```

Основной файл должен находиться по адресу
`~/.config/aerospace/aerospace.toml`. AeroSpace можно включить в автозапуск
через его меню. Разрешите приложению Accessibility, если macOS попросит это.

В конфигурации используется `borders`, поэтому он должен быть доступен в
`PATH`. После изменения файла выполните:

```sh
aerospace reload-config
```

Скрипт `presentation.sh` меняет отступы AeroSpace, размер шрифта Alacritty и
обои. Теперь он использует безопасные значения по умолчанию
`~/Pictures/Wallpapers/presentation.png` и
`~/Pictures/Wallpapers/default.png`; отсутствующие обои не ломают переключение.
Свои пути можно передать через `PRESENTATION_WALLPAPER` и `NORMAL_WALLPAPER`.

### btop — мониторинг ресурсов

Файл: `btop/btop.conf`

Установка:

```sh
brew install btop
```

Настройки включают CPU, память, диски, сеть, температуры, частоту CPU и
графики. Запуск:

```sh
btop
```

`btop/btop.log` — журнал запуска, а не часть настроек. Его не стоит публиковать
вместе с конфигурацией без проверки.

### lsd — современный `ls`

Файл: `lsd/config.yaml`

Установка:

```sh
brew install lsd
```

Конфиг включает иконки, сортировку по имени, дату, права, пользователя,
группу и размер. Запуск:

```sh
lsd
lsd -la
```

Чтобы использовать `lsd` вместо `ls`, добавьте алиасы в `~/.zshrc` вручную:

```sh
alias ls='lsd'
alias ll='lsd -la'
```

### micro — редактор в терминале

Файл: `micro/bindings.json`

Установка:

```sh
brew install micro
```

Настройка добавляет комментарий кода через `Alt-/` и `Ctrl+_`. Запуск:

```sh
micro файл.txt
```

`micro/buffers/history` — личная история редактора. Перед публикацией её нужно
проверить или исключить из репозитория.

### neofetch — информация о системе

Файл: `neofetch/config.conf`.

Это старый конфиг Neofetch. Сам Neofetch больше не развивается, поэтому
Homebrew или другой пакетный менеджер может его уже не предоставлять. Если
команда `brew install neofetch` недоступна, используйте современную замену:

```sh
brew install fastfetch
fastfetch
```

`fastfetch` не читает `neofetch/config.conf` автоматически. Сам файл оставлен
для тех, кому нужен именно Neofetch.

### LS_COLORS — цвета для GNU-инструментов

Каталог `LS_COLORS/` — отдельный проект с таблицей цветов файлов. На обычном
macOS `lsd` использует собственную цветовую схему, поэтому этот модуль не
нужен для `lsd`.

Для GNU `ls` установите coreutils и добавьте источник в `~/.zshrc`.
Если репозиторий лежит не в `~/.config`, укажите вместо этого абсолютный путь
к своему checkout:

```sh
brew install coreutils
```

```sh
source "$HOME/.config/LS_COLORS/lscolors.sh"
```

После изменения `~/.zshrc` откройте новый терминал или выполните `source
~/.zshrc`. Программа из этого каталога ожидает GNU `dircolors` и совместимый
инструмент вывода.

### Дополнительные элементы SketchyBar

#### GitHub

`sketchybar/items/github.sh` и `sketchybar/plugins/github.sh` используют GitHub
CLI:

```sh
brew install gh jq
gh auth login
```

Чтобы включить элемент, добавьте в правую секцию `sketchybar/sketchybarrc`:

```sh
source "$ITEM_DIR/github.sh"
```

Скрипт обращается к GitHub API от имени вашей учётной записи и показывает
количество уведомлений. Не включайте его на машине, где не хотите давать
панели доступ к GitHub-сессии.

#### Spotify

```sh
brew install --cask spotify
```

Раскомментируйте строку `source "$ITEM_DIR/spotify.sh"` в центральной секции
`sketchybar/sketchybarrc`. Скрипт управляет Spotify через AppleScript и при
воспроизведении скачивает обложку трека во временный файл `/tmp/cover.jpg`.

## Горячие клавиши

### Обозначения

- **RAlt / Right Option** — правая клавиша Option/Alt;
- **⌥ Option/Alt**, **⌃ Ctrl**, **⇧ Shift**, **⌘ Cmd** — стандартные модификаторы
  macOS;
- `resize` — отдельный режим skhd. Войти и выйти из него можно
  `RAlt + Shift + R`.

Ниже перечислены сочетания из текущего `skhd/skhdrc`. Если вы выбрали
AeroSpace, используйте таблицу AeroSpace: сочетания yabai и AeroSpace не
совпадают полностью.

### skhd + yabai

#### Система и запуск приложений

| Сочетание | Действие |
| --- | --- |
| `RAlt + Y` | Перезапустить сервис yabai |
| `RAlt + Esc` | Заблокировать экран |
| `RAlt + Return` | Открыть Alacritty |
| `RAlt + B` | Открыть Safari (комментарий в конфиге ошибочно говорит Firefox) |
| `RAlt + Ctrl + Return` | Открыть Visual Studio Code |
| `Alt + Q` | Закрыть активное окно |

#### Фокус окон

| Сочетание | Действие |
| --- | --- |
| `RAlt + A / S / W / D` | Фокус влево / вниз / вверх / вправо |
| `RAlt + ← / ↓ / ↑ / →` | То же самое стрелками |
| `RAlt + Tab` | Следующий рабочий стол |
| `RAlt + Shift + Tab` | Предыдущий рабочий стол |
| `RAlt + X` | Последний использованный рабочий стол |
| `RAlt + 1 ... 9` | Перейти на рабочий стол 1 ... 9 |

#### Перемещение окон и рабочие столы

| Сочетание | Действие |
| --- | --- |
| `RAlt + Shift + A / S / W / D` | Переместить окно влево / вниз / вверх / вправо |
| `RAlt + Shift + стрелка` | Переместить окно в направлении стрелки |
| `RAlt + Shift + 1 ... 8` | Отправить окно на рабочий стол 1 ... 8 |
| `RAlt + Shift + X` | Отправить окно на последний рабочий стол |
| `RAlt + Ctrl + M` | Отправить окно на последний рабочий стол и перейти туда |
| `RAlt + Ctrl + P` | Отправить окно на предыдущий рабочий стол и перейти туда |
| `RAlt + Ctrl + N` | Отправить окно на следующий рабочий стол и перейти туда |
| `RAlt + Ctrl + 1 ... 4` | Отправить окно на рабочий стол 1 ... 4 и перейти туда |
| `RAlt + C` | Создать рабочий стол и перейти на него |
| `RAlt + Shift + C` | Удалить текущий рабочий стол |

`RAlt + Shift + C` потенциально опасен: он удаляет текущий Space, поэтому
используйте его осознанно.

#### Размер, раскладка и внешний вид

| Сочетание | Действие |
| --- | --- |
| `RAlt + E` | Выровнять размеры окон на текущем рабочем столе |
| `RAlt + I` | Включить/выключить отступы и зазор между окнами |
| `Alt + R` | Повернуть раскладку на 270° |
| `Shift + Alt + R` | Повернуть раскладку на 90° |
| `Shift + Alt + X` | Отразить раскладку по оси X |
| `Shift + Alt + Y` | Отразить раскладку по оси Y |
| `RAlt + V` | Установить точку вставки окна вниз |
| `RAlt + H` | Установить точку вставки окна вправо |
| `Shift + Alt + Space` | Переключить плавающий режим окна |
| `Alt + F` | Переключить zoom-fullscreen yabai |
| `Shift + Alt + F` | Переключить native fullscreen macOS |

В режиме `resize`:

| Клавиша | Действие |
| --- | --- |
| `←` | Уменьшить ширину |
| `→` | Увеличить ширину |
| `↑` | Уменьшить высоту |
| `↓` | Увеличить высоту |
| `RAlt + Shift + R` | Вернуться в обычный режим |

### AeroSpace

Эти сочетания берутся из `aerospace/aerospace.toml`:

| Сочетание | Действие |
| --- | --- |
| `⌥ + /` | Переключить горизонтальное/вертикальное деление |
| `⌥ + ,` | Переключить accordion-раскладку |
| `⌥ + H / J / K / L` | Фокус влево / вниз / вверх / вправо |
| `⌥ + Shift + H / J / K / L` | Переместить окно влево / вниз / вверх / вправо |
| `⌥ + - / =` | Уменьшить / увеличить размер окна |
| `⌘ + Q` | Закрыть окно; если оно последнее, закрыть приложение |
| `⌥ + 1 ... 9` | Перейти на рабочий стол 1 ... 9 |
| `⌥ + Shift + 1 ... 9` | Переместить окно на рабочий стол 1 ... 9 |
| `⌥ + Tab` | Переключиться на предыдущий рабочий стол |
| `⌥ + Shift + Tab` | Перенести текущий рабочий стол на следующий монитор |
| `⌥ + Shift + ;` | Войти в сервисный режим |

Сервисный режим AeroSpace действует до выхода из него:

| Клавиша | Действие |
| --- | --- |
| `Esc` | Перезагрузить конфигурацию и выйти |
| `R` | Сбросить дерево раскладки и выйти |
| `F` | Переключить floating/tiling и выйти |
| `Backspace` | Закрыть все окна, кроме текущего, и выйти |
| `⌥ + Shift + H / J / K / L` | Объединить текущий контейнер с соседним и выйти |
| `↑ / ↓` | Увеличить/уменьшить громкость |
| `Shift + ↓` | Установить громкость 0 и выйти |

### Mouse-кнопки панели

| Действие | Результат |
| --- | --- |
| Клик по логотипу Apple | Открыть popup с Preferences, Activity Monitor и Lock Screen |
| Клик по дате | Переключить zen mode |
| Клик по значку громкости | Показать/скрыть слайдер громкости |
| Shift-клик или правый клик по громкости | Открыть список аудиоустройств |
| Клик по номеру Space | Перейти на него |
| Правый клик по Space | Удалить его |
| Клик по разделителю рядом с Space | Создать новый Space |

## Что умеет SketchyBar

Текущий `sketchybar/sketchybarrc` подключает следующие элементы:

| Элемент | Что показывает |
| --- | --- |
| Apple | Popup системных действий |
| Spaces | Рабочие столы yabai и иконки приложений в них |
| Active app | Иконка активного приложения |
| Calendar | День, дата и время |
| Brew | Число устаревших пакетов Homebrew |
| Wi‑Fi | Скорость входящего/исходящего трафика и VPN-иконка |
| Battery | Процент, зарядка и предупреждение о низком заряде |
| Volume | Громкость и выбор аудиоустройства |
| CPU | Текущая загрузка и графики |

GitHub и Spotify лежат в каталоге, но по умолчанию не подключены. Это
намеренно: GitHub требует авторизации, а Spotify — установленное приложение и
доступ AppleScript.

## Приватность и личные данные

Конфиги сами по себе не отправляют данные в интернет, но отдельные скрипты
читают локальное состояние компьютера:

- `sketchybar/plugins/wifi.sh` читает имя Wi‑Fi, локальный IP, состояние VPN и
  счётчики трафика, чтобы показать их в панели;
- `sketchybar/plugins/wifi_status.sh` делает то же в более старой/отдельной
  реализации;
- `sketchybar/plugins/github.sh` при включении обращается к GitHub API через
  сохранённую сессию `gh`;
- `sketchybar/plugins/spotify.sh` при включении управляет Spotify через
  AppleScript и скачивает обложку текущего трека во временный каталог;
- `aerospace/presentation.sh` запускает `osascript` для смены обоев и требует
  путей к файлам на конкретном компьютере.

Эти runtime-файлы уже перечислены в `.gitignore` и выведены из индекса Git,
поэтому в новых коммитах они не появятся:

- `configstore/*firebase-tools.json` — локальное состояние Firebase с OAuth- и
  пользовательскими данными;
- `sketchybar/plugins/wifi.log`, `wifi_cache.txt`, `wifi_debug.txt` и
  `wifi_stats.txt` — сетевая статистика; может содержать локальный IP, SSID и
  время активности;
- `btop/btop.log`, `micro/buffers/history` и `workspaces_backup.txt` — журналы,
  история или старые рабочие данные;
- `iterm2/AppSupport` — симлинк на персональный путь `~/Library/...`;
- `mole/` — служебное состояние scripting addition для yabai.

Перед публикацией или передачей каталога другому человеку дополнительно
проверьте:

- любые абсолютные пути `/Users/<имя>/...` в конфигурациях;
- `aerospace/presentation.sh`: при запуске с чужим checkout проверьте значения
  `PRESENTATION_WALLPAPER` и `NORMAL_WALLPAPER`, если используете смену обоев.

Важно: `.gitignore` и `git rm --cached` убирают файлы только из будущих
коммитов — данные остаются в **истории** Git. Если каталог уже публиковался,
проверьте `git log -- <файл>` и при необходимости перепишите историю
(`git filter-repo`) перед выкладыванием.

## Проверка и перезапуск

### После установки основного стека

```sh
brew services list
which yabai skhd sketchybar jq
yabai --restart-service
skhd --restart-service
brew services restart sketchybar
```

Если сервисы установлены через Homebrew, вместо команд `--restart-service` можно
использовать:

```sh
brew services restart yabai
brew services restart skhd
```

### После установки AeroSpace

```sh
aerospace reload-config
```

### Проверить синтаксис shell-скриптов

```sh
for file in aerospace/presentation.sh sketchybar/sketchybarrc \
  sketchybar/items/*.sh sketchybar/plugins/*.sh yabai/*.sh yabai/yabairc
do
  bash -n "$file" 2>/dev/null || sh -n "$file"
done
```

Некоторые скрипты используют `bash`-конструкции и системные команды macOS, так
что синтаксическая проверка не заменяет запуск конкретного сервиса.

## Частые проблемы

### Хоткеи не работают

1. Проверьте, что запущен `skhd --start-service`.
2. Добавьте именно бинарник из `which skhd` в Accessibility.
3. Перезапустите `skhd` после выдачи разрешения.
4. Закройте приложения, включившие Secure Keyboard Entry, если они временно
   блокируют глобальные события клавиатуры.

### Окна не раскладываются

Проверьте `yabai --restart-service`, Accessibility и вывод `yabai`. Если
ошибка относится к `sudo yabai --load-sa`, сначала закомментируйте эту строку
для базового запуска, а scripting addition настраивайте отдельно по официальной
документации.

### SketchyBar не появляется

Остановите сервис и запустите панель в терминале:

```sh
brew services stop sketchybar
sketchybar
```

Чаще всего причина — отсутствуют `make`/`clang`, не собрался helper, нет
`sketchybar-app-font` или не найден `borders`. После исправления верните
`brew services start sketchybar`.

### На панели нет скорости Wi‑Fi

Скрипт ищет Wi‑Fi-интерфейс через `networksetup`. Для нестандартного интерфейса
его можно запустить так:

```sh
IFACE=en1 sketchybar --update
```

В обычном случае используется `en0`. Файлы `wifi_*` рядом с плагинами — это
кэш/отладочный вывод, их можно удалить после остановки SketchyBar, если они не
нужны; при следующем запуске нужный кэш создастся снова.

### Пропали значки

Проверьте шрифты `SpaceMono Nerd Font`, `SF Pro` и
`sketchybar-app-font`. Также убедитесь, что конфиг запускается из
`$HOME/.config/sketchybar`, а не из случайного рабочего каталога.

### Не работает переключение аудиоустройств

Установите `switchaudio-osx` и проверьте команду:

```sh
SwitchAudioSource -a -t output
```

Без этого пакета основная панель всё равно работает, просто popup аудиовыходов
будет недоступен.

## Структура каталога

```text
.
├── aerospace/       AeroSpace и скрипт режима презентации
├── alacritty/       Конфигурация терминала
├── btop/            Мониторинг ресурсов
├── lsd/             Конфигурация lsd
├── micro/           Привязки клавиш micro
├── neofetch/        Старый конфиг Neofetch
├── LS_COLORS/       Цвета для GNU ls и совместимых инструментов
├── sketchybar/      Активная shell-конфигурация верхней панели
├── sketchybar1/     Экспериментальная Lua-конфигурация панели
├── skhd/             Глобальные хоткеи
└── yabai/            Оконный менеджер и его скрипты
```

Для изменения настроек редактируйте файлы в этом репозитории, затем
перезапускайте соответствующий сервис. Если конфигурация подключена
симлинками, изменения применяются прямо из репозитория.

## Полезные официальные ссылки

- [Homebrew](https://brew.sh)
- [AeroSpace Guide](https://nikitabobko.github.io/AeroSpace/guide)
- [yabai: installation](https://github.com/koekeishiya/yabai/wiki/Installing-yabai-%28latest-release%29)
- [skhd](https://github.com/koekeishiya/skhd)
- [SketchyBar: setup](https://felixkratz.github.io/SketchyBar/setup)
- [JankyBorders](https://github.com/FelixKratz/JankyBorders)
- [btop](https://github.com/aristocratos/btop)
- [lsd](https://github.com/lsd-rs/lsd)
- [micro](https://github.com/zyedidia/micro)
- [fastfetch](https://github.com/fastfetch-cli/fastfetch)
