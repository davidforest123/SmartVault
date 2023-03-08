# TextVault

Encrypted text editor that protects privacy.

## Build

```
flutter pub get // Install dependencies
flutter build macos // `flutter build windows` etc
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

