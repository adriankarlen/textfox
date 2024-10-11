# textfox

_a port of spotify tui to firefox_

> [!NOTE]
> This was written in a couple of hours and only tested using rose-pine moon
> theme, so it might not work as intended for every theme, PR's are welcome!

## preview

![image](https://github.com/adriankarlen/textfox/blob/main/misc/preview.png)

## Prequisites

- Sidebery

## Installation

- Download the repo as a zip, export it in to your chrome-folder
- Move the user.js file to your profile dir (the parent of the chrome dir)
- _*Optional*_ import the sidebery settings (do this at your own risk, this will
  overwrite your settings).

## Customization

The icon configuration utilizes code that is originally from ShyFox, therefore
the same settings are used (these can be set in about:config).
| Setting                                | true                                                                  | false (default)           |
| -------------------------------------- | --------------------------------------------------------------------- | ------------------------- |
| `shyfox.enable.ext.mono.toolbar.icons` | Supported\* extensions get monochrome icons as toolbar buttons        | Standard icons used       |
| `shyfox.enable.ext.mono.context.icons` | Supported\* extensions get monochrome icons as context menu items\*\* | Standard icons used       |
| `shyfox.enable.context.menu.icons`     | Many context menu items get icons\*\*                                 | No icons in context menus |

The variables.css file has some variables that can be tweaked, like border
radius for instace.

### Acknowledgements

[Naezr](https://github.com/Naezr) - Icon logic and some sideberry logic.

изз - starting working on a similar project in the glazewm discord, prompted me
to get started on the work.
