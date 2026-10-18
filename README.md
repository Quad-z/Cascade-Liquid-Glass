# Cascade Liquid Glass (macOS Edition)

[![Roblox](https://img.shields.io/badge/Roblox-Engine-00A2FF?logo=roblox&logoColor=white)](https://roblox.com)
[![Language](https://img.shields.io/badge/Language-Luau-00A2FF.svg)](https://luau-lang.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-181717?logo=github&logoColor=white)](https://github.com/Quad-z/Cascade-Liquid-Glass)
[![Design](https://img.shields.io/badge/Design-macOS%20Sequoia%20Vibrancy-grey.svg)]()

> Исходный код и репозиторий: **[https://github.com/Quad-z/Cascade-Liquid-Glass](https://github.com/Quad-z/Cascade-Liquid-Glass)**

Аутентичная реализация **macOS Liquid Glass** (жидкое стекло с 3D-рефракцией) и **локального матового блюра** (Frosted Glass) для интерфейсов Roblox Luau. Разработано для бесшовной интеграции с **Cascade UI** или любым другим кастомным `GuiObject`.

---

## 📖 Как использовать (Руководство)

Все исходные файлы проекта доступны в официальном репозитории:  
🔗 **[https://github.com/Quad-z/Cascade-Liquid-Glass](https://github.com/Quad-z/Cascade-Liquid-Glass)**

### Вариант 1: Быстрый запуск чита с Ключ-системой (Key System)
Запускает стильную ключ-систему (две капли с кнопкой копирования Linkify и полем ввода ключа):

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/Quad-z/Cascade-Liquid-Glass/main/examples/KeySystem.lua"))()
```
* При клике на иконку копирования копируется ссылка Linkify (`https://go.linkify.ru/2K8S`).
* Валидный ключ: `QUADD-JKOS2LD36-2026-2S`.
* После ввода ключа автоматически открывается главное окно чита.

---

### Вариант 2: Прямой запуск Cascade Liquid Glass UI (Без ключа)

#### Английская версия:
```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/Quad-z/Cascade-Liquid-Glass/main/examples/CascadeExample.luau"))()
```

#### Русская версия:
```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/Quad-z/Cascade-Liquid-Glass/main/examples/CascadeExample_RU.luau"))()
```

---

### Вариант 3: Подключение модуля `LiquidGlass` к любому своему окну

Вы можете наложить эффект настоящего жидкого стекла с блюром на **любой** `Frame` или `CanvasGroup`:

```luau
local LiquidGlass = loadstring(game:HttpGet("https://raw.githubusercontent.com/Quad-z/Cascade-Liquid-Glass/main/src/LiquidGlass.luau"))()

-- Ваше окно интерфейса:
local myWindow = script.Parent.MyWindowFrame

-- Накладываем жидкое стекло и локальный блюр:
local glass = LiquidGlass.attach(myWindow, {
    CornerRadius        = 26,   -- Радиус скругления углов (px)
    FrostBlur           = 0.85, -- Сила локального размытия под окном
    CornerRefraction    = 3.5,  -- Оптическое преломление линз по углам
    EdgeRefraction      = 2.9,  -- Преломление вдоль граней окна
    BlurKernelInset     = 36,   -- Компенсация ореола размытия
    WindowTransparency  = 0.38, -- Базовая прозрачность окна
})

-- Управление:
glass:SetEnabled(true)  -- включить / выключить эффект
glass:Destroy()         -- полное удаление и очистка ресурсов
```

---

## ✨ Особенности библиотеки

- ** Аутентичный стиль macOS Vibrancy**: Глубокое полупрозрачное обсидиановое стекло (`Color3.fromRGB(14, 17, 24)`), точно повторяющее тёмную тему Apple macOS Sequoia.
- **🔍 9-Slice оптическое преломление**: Угловые и краевые меши стекла создают эффект линзы и преломления мира, не выходя за пределы границ окна.
- **🌫️ Локальный экранный блюр**: Размывается **только область под окном интерфейса**. Мир вокруг окна и остальной экран игрока остаются на 100% чёткими и резкими (`FarIntensity = 0`).
- **🪟 Тонкий спекулярный кант**: 1px светоотражающая кайма окна.
- **⚡ Плавные анимации**: Пружинные переходы macOS при переключении вкладок и перетаскивании окна.
- **🛡️ Защита от смерти персонажа**: `ResetOnSpawn = false` гарантирует сохранность окна при респавне игрока.

---

## 📦 Структура репозитория

```
Cascade-Liquid-Glass/
├── LICENSE                         # MIT License
├── README.md                       # Документация и инструкция
├── dist/
│   └── bundle.luau                 # Полный автономный бандл библиотеки
├── examples/
│   ├── KeySystem.lua               # Минималистичная ключ-система с Linkify
│   ├── CascadeExample.luau         # Главный демонстрационный интерфейс (EN)
│   ├── CascadeExample_RU.luau      # Демонстрационный интерфейс на русском (RU)
│   └── WindUI_LiquidGlass.luau     # Пример интеграции с WindUI
└── src/
    └── LiquidGlass.luau            # Модуль для наложения стекла на любой GuiObject
```

---

## 🛠️ Настройки параметров стекла

| Параметр | По умолчанию | Описание |
| :--- | :--- | :--- |
| `CornerRadius` | `26` px | Радиус скругления угловых линз преломления |
| `CornerRefraction` | `3.5` | Сила оптического искажения по углам |
| `EdgeRefraction` | `2.9` | Сила рефракции вдоль прямых граней окна |
| `FrostBlur` | `0.85` | Интенсивность размытия под окном |
| `WindowTransparency` | `0.38` | Прозрачность фона для отображения размытого мира |
| `BlurKernelInset` | `36` px | Защита от ореола DepthOfField вокруг окна |

---

## 💖 Благодарности

- **Cascade UI**: [@cascadeui](https://github.com/cascadeui/Cascade)
- **LiquidGlassHandler**: [@7eoeb](https://devforum.roblox.com) & [@UNIVERSECORNUCOPIA](https://devforum.roblox.com)
- **Apple macOS Design**: Дизайн-система macOS Sequoia & visionOS

---

## 📄 Лицензия

Проект распространяется под лицензией [MIT License](LICENSE).
