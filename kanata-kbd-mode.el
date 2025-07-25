;;; kanata-kbd-mode.el --- Major mode for editing Kanata .kbd configuration files

(require 'cl-lib)

;;; Commentary:
;; This package provides a major mode for editing Kanata .kbd files,
;; offering syntax highlighting, basic indentation, and comment support.
;; Kanata is a software keyboard remapper.

;;; Code:

(defvar kanata-kbd-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\; "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?# ". 14" table)
    (modify-syntax-entry ?| ". 23" table)
    (modify-syntax-entry ?\( "()" table)
    (modify-syntax-entry ?\) ")(" table)
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?- "w" table)
    (modify-syntax-entry ?@ "w" table)
    (modify-syntax-entry ?& "w" table)
    (modify-syntax-entry ?$ "w" table)
    (modify-syntax-entry ?! "w" table)
    table)
  "Syntax table for `kanata-kbd-mode`.")

(defun kanata-kbd-indent-line ()
  "Indent current line for kanata-kbd-mode."
  (let ((indent 0))
    (save-excursion
      (beginning-of-line)
      (let ((paren-depth 0))
        (save-excursion
          (goto-char (point-min))
          (while (< (point) (line-beginning-position))
            (cond
             ((looking-at "(") (setq paren-depth (1+ paren-depth)))
             ((looking-at ")") (setq paren-depth (1- paren-depth))))
            (forward-char)))
        (setq indent (* paren-depth 2))))
    (indent-line-to indent)))

(defun kanata-kbd-comment-dwim (arg)
  "Comment or uncomment region or line intelligently."
  (interactive "*P")
  (if (use-region-p)
      (comment-or-uncomment-region (region-beginning) (region-end))
    (comment-or-uncomment-region (line-beginning-position) (line-end-position))))

(defun kanata-kbd-align-deflayer ()
  "Align the keys within a deflayer block."
  (interactive)
  (save-excursion
    (let (start end)
      (unless (re-search-backward "(deflayer" nil t)
        (user-error "Not in a deflayer block"))
      (setq start (match-beginning 0))
      (goto-char start)
      (forward-sexp)
      (setq end (point))
      (let* ((block-text (buffer-substring-no-properties start end))
             (lines (split-string block-text "\n" t))
             (first-line (car lines))
             (layer-name (cadr (split-string first-line "[ \t()]+")))
             (body-lines (butlast (cdr lines) 1))
             ;; Parse rows, ignoring empty lines
             (rows (cl-loop for line in body-lines
                            for trimmed = (string-trim line)
                            when (not (string-empty-p trimmed))
                            collect (split-string trimmed "[ \t]+")))
             ;; Calculate max widths for each column
             (num-columns (if rows (apply #'max (mapcar #'length rows)) 0))
             (max-widths (make-list num-columns 0)))
        (dolist (row rows)
          (dotimes (i (length row))
            (setf (nth i max-widths)
                  (max (nth i max-widths) (length (nth i row))))))
        ;; Format the new text
        (let* ((formatted-rows
                (cl-loop for row in rows
                         collect
                         (string-join
                          (cl-loop for item in row
                                   for i from 0
                                   collect
                                   (let ((width (nth i max-widths)))
                                     (format (concat "%-" (number-to-string width) "s") item)))
                          " ")))
               (new-text
                (concat "(deflayer " layer-name "\n"
                        (mapconcat (lambda (line) (concat "  " (string-trim-right line)))
                                   formatted-rows
                                   "\n")
                        "\n)")))
          (delete-region start end)
          (insert new-text))))))


(defconst kanata-kbd-top-level-directives
  '("defcfg" "defsrc" "deflayer" "deflayermap" "defalias" "defvar"
    "defvirtualkeys" "deffakekeys" "defseq" "defoverrides" "defchords" "defchordsv2"
    "deftemplate" "template-expand" "t!" "include" "platform" "environment"
    "defzippy" "deflocalkeys-win" "deflocalkeys-winiov2" "deflocalkeys-wintercept"
    "deflocalkeys-linux" "deflocalkeys-macos" "defaliasenvcond")
  "Top-level directives in Kanata .kbd files.")

(defconst kanata-kbd-defcfg-keywords
  '("process-unmapped-keys" "concurrent-tap-hold" "delegate-to-first-layer"
    "block-unmapped-keys" "override-release-on-activation" "allow-hardware-repeat"
    "log-layer-changes" "alias-to-trigger-on-load" "rapid-event-delay"
    "sequence-timeout" "sequence-input-mode" "sequence-backtrack-modcancel"
    "dynamic-macro-max-presses" "chords-v2-min-idle"
    "movemouse-inherit-accel-state" "movemouse-smooth-diagonals"
    "linux-dev" "linux-dev-names-include" "linux-dev-names-exclude"
    "linux-continue-if-no-devs-found" "linux-device-detect-mode"
    "linux-unicode-u-code" "linux-unicode-termination" "linux-x11-repeat-delay-rate"
    "linux-use-trackpoint-property" "linux-output-device-name" "linux-output-device-bus-type"
    "mouse-movement-key" "windows-altgr" "windows-interception-mouse-hwid"
    "windows-interception-mouse-hwids" "windows-interception-keyboard-hwids"
    "windows-interception-keyboard-hwids-exclude" "windows-interception-mouse-hwids-exclude"
    "tray-icon" "icon-match-layer-name" "tooltip-layer-changes" "tooltip-show-blank"
    "tooltip-no-base" "tooltip-duration" "tooltip-size" "notify-cfg-reload"
    "notify-cfg-reload-silent" "notify-error" "macos-dev-names-include"
    "macos-dev-names-exclude" "danger-enable-cmd")
  "Keywords used within (defcfg ...).")

(defconst kanata-kbd-action-keywords
  '("layer-toggle" "layer-switch" "layer-while-held" "layer-clear"
    "layer-switch-when-held" "layer-tap-hold" "layer-tap-dance"
    "release-layer" "layer↑" "macro" "macro-release-cancel" "macro-cancel-on-press"
    "macro-release-cancel-and-cancel-on-press" "macro-repeat"
    "macro-repeat-release-cancel" "macro-repeat-cancel-on-press"
    "macro-repeat-release-cancel-and-cancel-on-press" "macro↑⤫"
    "multi" "release-key" "key↑" "oneshot" "one-shot" "one-shot-press"
    "one-shot-release" "one-shot-press-pcancel" "one-shot-release-pcancel"
    "one-shot↓" "one-shot↑" "one-shot↓⤫" "one-shot↑⤫" "one-shot-pause-processing"
    "sticky" "transparent" "_" "unmapped" "use-defsrc" "XX" "✗" "∅" "•"
    "nop0" "nop1" "nop2" "nop3" "nop4" "nop5" "nop6" "nop7" "nop8" "nop9"
    "tap-hold" "tap-hold-press" "tap-hold-release" "tap-hold-press-timeout"
    "tap-hold-release-timeout" "tap-hold-release-keys" "tap-hold-except-keys"
    "tap⬓↓" "tap⬓↑" "tap⬓↓timeout" "tap⬓↑timeout" "tap⬓↑keys" "tap-hold⤫keys"
    "tap-dance" "tap-dance-eager" "cmd" "cmd-log" "cmd-output-keys"
    "unicode" "🔣" "unicode-hex" "leader" "sldr" "sequence" "sequence-noerase"
    "compose" "toggle-unicode-mode" "reset-sticky-keys" "noexplicit" "rpt"
    "rpt-any" "unmod" "unshift" "un⇧" "fork" "switch" "caps-word" "word⇪"
    "caps-word-custom" "word⇪-custom" "caps-word-toggle" "caps-word-custom-toggle"
    "arbitrary-code" "dynamic-macro-record" "dynamic-macro-play"
    "dynamic-macro-record-stop" "dynamic-macro-record-stop-truncate"
    "clipboard-set" "clipboard-save" "clipboard-restore" "clipboard-save-swap"
    "clipboard-cmd-set" "clipboard-save-cmd-set" "chord" "on-press" "on↓"
    "on-release" "on↑" "on-idle" "hold-for-duration" "tap-virtualkey" "tap-vkey"
    "press-virtualkey" "press-vkey" "release-virtualkey" "release-vkey"
    "toggle-virtualkey" "toggle-vkey" "on-press-fakekey" "on↓fakekey"
    "on-release-fakekey" "on↑fakekey" "on-idle-fakekey")
  "Special action keywords in Kanata.")

(defconst kanata-kbd-mouse-actions
  '("mlft" "mmid" "mrgt" "mfwd" "mbck" "mltp" "mmtp" "mrtp" "mftp" "mbtp"
    "mwheel-up" "mwheel-down" "mwheel-left" "mwheel-right" "🖱☸↑" "🖱☸↓"
    "🖱☸←" "🖱☸→" "mwu" "mwd" "mwl" "mwr" "movemouse-up" "movemouse-down"
    "movemouse-left" "movemouse-right" "🖱↑" "🖱↓" "🖱←" "🖱→"
    "movemouse-accel-up" "movemouse-accel-down" "movemouse-accel-left"
    "movemouse-accel-right" "🖱accel↑" "🖱accel↓" "🖱accel←" "🖱accel→"
    "setmouse" "set🖱" "movemouse-speed" "🖱speed" "mvmt")
  "All mouse-related actions and keys.")

(defconst kanata-kbd-internal-keywords
  '("reverse-release-order" "or" "and" "not" "key-history" "key-timing"
    "less-than" "lt" "greater-than" "gt" "input" "real" "virtual"
    "input-history" "layer" "base-layer" "break" "fallthrough" "if-equal"
    "if-not-equal" "if-in-list" "if-not-in-list" "concat" "reset-timeout-on-press"
    "on-first-press-chord-deadline" "idle-reactivate-time" "smart-space" "none"
    "add-space-only" "full" "smart-space-punctuation" "output-character-mappings"
    "no-erase" "single-output" "first-release" "all-released")
  "Keywords used inside other directives/actions.")

(defconst kanata-kbd-common-key-names
  (append
   '("esc" "f1" "f2" "f3" "f4" "f5" "f6" "f7" "f8" "f9" "f10" "f11" "f12"
     "grv" "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "min" "eq" "bspc"
     "tab" "q" "w" "e" "r" "t" "y" "u" "i" "o" "p" "lbrc" "rbrc" "bsls" "bksl"
     "caps" "a" "s" "d" "f" "g" "h" "j" "k" "l" "scln" "quot" "ret"
     "lsft" "z" "x" "c" "v" "b" "n" "m" "comm" "dot" "slsh" "rsft"
     "lctl" "lmet" "lalt" "spc" "ralt" "rmet" "rctl" "fn" "menu"
     "ins" "home" "pgup" "del" "end" "pgdn" "up" "left" "down" "right" "rght"
     "nlck" "kp/" "kp*" "kp-" "kp+" "kp." "kp0" "kp1" "kp2" "kp3" "kp4"
     "kp5" "kp6" "kp7" "kp8" "kp9" "kpenter" "mute" "volu" "vold" "prev"
     "next" "play" "stop" "pp" "nonusbslash" "brdn" "brup" "C" "S" "A" "M" "W" "AG"
     "lC" "lS" "lA" "lM" "lW" "rC" "rS" "rA" "rM" "rW")
   kanata-kbd-mouse-actions)
  "Common key names and symbols in Kanata.")

(defconst kanata-kbd-font-lock-keywords
  `(;; Comments
    (";;.*" . font-lock-comment-face)
    ("#|\\(.\\|\n\\)*?|#" . font-lock-comment-face)
    
    ;; Top-level directives
    (,(concat "\\<" (regexp-opt kanata-kbd-top-level-directives) "\\>") . font-lock-keyword-face)
    
    ;; Keywords within defcfg
    (,(concat "\\<" (regexp-opt kanata-kbd-defcfg-keywords) "\\>") . font-lock-type-face)
    
    ;; Action keywords
    (,(concat "\\<" (regexp-opt kanata-kbd-action-keywords) "\\>") . font-lock-builtin-face)
    
    ;; Internal keywords
    (,(concat "\\<" (regexp-opt kanata-kbd-internal-keywords) "\\>") . font-lock-preprocessor-face)
    
    ;; Alias definition and usage
    ("(\\(?:defalias\\|deflayer\\)\\s-+\\([a-zA-Z_][a-zA-Z0-9_-]*\\)" 1 font-lock-variable-name-face)
    ("@\\([a-zA-Z_][a-zA-Z0-9_-]*\\)" 1 font-lock-function-name-face)
    ("\\$\\([a-zA-Z_][a-zA-Z0-9_-]*\\)" 1 font-lock-function-name-face)
    
    ;; Common key names
    (,(concat "\\<" (regexp-opt kanata-kbd-common-key-names) "\\>") . font-lock-constant-face)
    
    ;; Modifier prefixes
    ("\\([lr]?[CSAMW]G?\\|AG\\)-\\([a-zA-Z0-9]+\\)"
     (1 font-lock-preprocessor-face)
     (2 font-lock-constant-face))
    
    ;; Strings and numbers
    ("\"\\(?:\\\\.[^\"]*\\|[^\"]\\)*\"" . font-lock-string-face)
    ("\\b[0-9]+\\b" . font-lock-string-face))
  "Font lock keywords for `kanata-kbd-mode`.")

;;;###autoload
(define-derived-mode kanata-kbd-mode prog-mode "KanataKBD"
  "Major mode for editing Kanata .kbd configuration files."
  :syntax-table kanata-kbd-mode-syntax-table
  (setq-local font-lock-defaults '(kanata-kbd-font-lock-keywords))
  (setq-local comment-start ";; ")
  (setq-local comment-start-skip ";;+\\s-*")
  (setq-local indent-line-function 'kanata-kbd-indent-line)
  (setq-local indent-tabs-mode nil)
  (define-key kanata-kbd-mode-map (kbd "M-;") 'kanata-kbd-comment-dwim)
  (define-key kanata-kbd-mode-map (kbd "C-c C-a") 'kanata-kbd-align-deflayer))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.kbd\\'" . kanata-kbd-mode))

(provide 'kanata-kbd-mode)

;;; kanata-kbd-mode.el ends here
