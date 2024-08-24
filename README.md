# Plain Text Typesetting System

A nice way to format text to be shown inside terminal / with monospace font.

Both more clasicall and vi-based keybindings are supported in the tui.
Metadata can be shown by pressing 'm'

[usage](doc/syntax.md)

## dependencies
- xelatex (optional, but needed for pdf)
- Visual Studio Build Tools (if compiling on Windows (should come with the compiler??))

## fonts
Fonts are a bit finicky, so when in doubt, copy fonts next to your document.

Font names should be as follows:
```
<fontname>-Regular.{otf|ttf}
<fontname>-Bold.{otf|ttf}
<fontname>-Italic.{otf|ttf}
<fontname>-BoldItalic.{otf|ttf}
```

## Windows problems
Tui doesn't work. Probably [crystal-term/reader](https://github.com/crystal-term/reader) issue.

Windows does not follow any naming conventions, so only the built-in Hack works
(and any fonts in same dir that follow the mentioned convention)

## attributions
ptts comes with the [HACK](https://sourcefoundry.org/hack/) font.
