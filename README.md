# Emacs Kanata KBD Mode

Major mode for editing Kanata .kbd configuration files in Emacs.

## Features

* Syntax highlighting for Kanata directives, keywords, actions, and keys.
* Basic indentation for .kbd files.
* Commenting and uncommenting lines or regions with `M-;`.
* Align keys within a `deflayer` block using `kanata-kbd-align-deflayer` (`C-c C-a`).

## Screenshot

<img width="1744" height="1091" alt="image" src="https://github.com/user-attachments/assets/a4dd90be-71c6-4051-b604-edb0628ebe70" />

## Installation

1. Place `kanata-kbd-mode.el` in your Emacs load-path.
2. Add the following to your `init.el` or `.emacs` file:

```elisp
(load-file "/path/to/your/kanata-kbd-mode.el")
```

Or using `use-package`:

```elisp
(use-package kanata-kbd-mode
  :load-path "/path/to/your/kanata-kbd-mode"
  :mode ("\\.kbd\\'" . kanata-kbd-mode))
```

For Emacs 29+ you can use `use-package-vc` or for Emacs 30:
```elisp
(use-package kanata-kbd-mode
  :vc (:url "https://github.com/chmouel/kanata-kbd-mode/" :rev :newest)
  )
```

## What is Kanata?

Kanata is a versatile software keyboard remapper that works on Windows, macOS,
and Linux. For more information, see the [official Kanata
repository](https://github.com/jtroo/kanata).

## 👥 Authors

### Chmouel Boudjnah

* 🐘 **Fediverse**: [@chmouel@chmouel.com](https://fosstodon.org/@chmouel) (preferred)
* 🐦 **Twitter**: [@chmouel](https://twitter.com/chmouel)
* 📝 **Blog**: [https://blog.chmouel.com](https://blog.chmouel.com)

## 📃 License

This project is licensed under the [GPL-3.0](./LICENSE).
