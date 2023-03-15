# TextVault

Encrypted text editor that protects privacy.

## Build

```
flutter pub get // Install dependencies
flutter build macos // Compile on macOS
flutter build linux // Compile on linux
flutter build windows // Compile on windows
```
It is recommended that you download the source code and compile it yourself, this is the safest way to get TextVault.

## Download

https://github.com/davidforest123/TextVault/releases

## Supported Platforms

macOS, Windows, Linux for now.

## File Encoding

| Header   | Delimiter | Body                     |
|----------|-----------|--------------------------|
| $Version |    \n     | $CipherText              |

## TODO

Implement `Find Replace`.

Implement `Settings` page.

Implement save check when clicking 'Quit' menu.

Implement automatically move to the application directory and create a shortcut.

Fix `A RenderFlex overflowed by xx pixels on the right`.

Fix the cursor disappearing problem at the beginning of the line when scrollbar is displayed.

Fix file read error sometimes.

Fix config write error sometimes.

