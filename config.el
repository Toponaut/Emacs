;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!


;; Enable fragtog mode
(add-hook 'org-mode-hook 'org-fragtog-mode)

;; org-babel
(after! org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python . t)
     (jupyter-python . t)))
  
  (setq org-confirm-babel-evaluate nil)
  (setq org-babel-python-command "python")
  
  ;; Ensure pyenv works with Emacs
  (setenv "PATH" (concat (getenv "HOME") "/.pyenv/shims:" (getenv "PATH")))
  (setq exec-path (cons (concat (getenv "HOME") "/.pyenv/shims") exec-path))
  
  ;; Force reload ob-python
  (require 'ob-python))

;; EIN polymode fix
(defun pm--visible-buffer-name (&optional buffer)
  "Return visible name for BUFFER."
  (buffer-name (or buffer (current-buffer))))

;; Fix timer errors when closing windows
(setq timer-max-repeats 0)


;; Exwm Config
(require 'exwm)
(require 'exwm-randr)
(require 'exwm-systemtray)

;; Disable EXWM system tray (use external trayer instead)
;; (setq exwm-systemtray-height 16)
;; (exwm-systemtray-mode 1)
;; Keybindings
;; Terminal keybindings
(defun exwm-launch-terminal-split ()
  "Split Emacs window and launch Kitty in the new pane."
  (interactive)
  (split-window-right)
  (other-window 1)
  (start-process-shell-command "kitty" nil "kitty"))

(defun exwm-launch-terminal-replace ()
  "Launch Kitty in current window."
  (interactive)
  (start-process-shell-command "kitty" nil "kitty"))

(defun exwm-launch-terminal-split-below ()
  "Split Emacs window horizontally and launch Kitty below."
  (interactive)
  (split-window-below)
  (other-window 1)
  (start-process-shell-command "kitty" nil "kitty"))

(exwm-input-set-key (kbd "<s-return>") 'exwm-launch-terminal-split)
(exwm-input-set-key (kbd "<s-S-return>") 'exwm-launch-terminal-replace)
(exwm-input-set-key (kbd "<s-C-return>") 'exwm-launch-terminal-split-below)

;; App launcher
(exwm-input-set-key (kbd "s-SPC") 'exwm-launcher)

;; Set the initial workspace number.
(setq exwm-workspace-number 10)
;; Make class name the buffer name.
(add-hook 'exwm-update-class-hook
  (lambda () (exwm-workspace-rename-buffer exwm-class-name)))
;; Configure line-mode for Evil compatibility
(setq exwm-input-line-mode-passthrough t)

;; Start applications in char-mode by default
(add-hook 'exwm-manage-finish-hook
          (lambda ()
            (when (and exwm-class-name exwm--id)
              (exwm-input-release-keyboard exwm--id))))

;; Define which keys should always pass through to Emacs/Evil in line-mode
(setq exwm-input-prefix-keys
      '(?\C-x
        ?\C-c
        ?\C-h
        ?\M-x
        ?\M-:
        ?\C-g
        ?\C-w
        ?\C-\ ))

;; Simulation keys for char-mode (keys sent to application)
(setq exwm-input-simulation-keys
      '(([?\C-b] . [left])
        ([?\C-f] . [right])
        ([?\C-p] . [up])
        ([?\C-n] . [down])
        ([?\C-a] . [home])
        ([?\C-e] . [end])
        ([?\M-v] . [prior])
        ([?\C-v] . [next])
        ([?\C-d] . [delete])
        ([?\C-k] . [S-end delete])))

;; Custom modeline elements for EXWM
(defun exwm-workspace-display ()
  "Display current workspace number."
  (format "  %d " exwm-workspace-current-index))

(defun exwm-datetime-display ()
  "Display current date and time."
  (format-time-string "  %d-%m-%Y  %H:%M "))

;; Volume control functions with notifications
(defun exwm-volume-up ()
  "Increase volume by 5%."
  (interactive)
  (start-process-shell-command "pactl" nil "pactl set-sink-volume @DEFAULT_SINK@ +5%")
  (start-process-shell-command "notify" nil "sh -c 'VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o \"[0-9]*%\" | head -1); notify-send -t 1500 -i audio-volume-high \"Volume\" \"$VOL\"'"))

(defun exwm-volume-down ()
  "Decrease volume by 5%."
  (interactive)
  (start-process-shell-command "pactl" nil "pactl set-sink-volume @DEFAULT_SINK@ -5%")
  (start-process-shell-command "notify" nil "sh -c 'VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o \"[0-9]*%\" | head -1); notify-send -t 1500 -i audio-volume-low \"Volume\" \"$VOL\"'"))

(defun exwm-volume-mute-toggle ()
  "Toggle volume mute."
  (interactive)
  (start-process-shell-command "pactl" nil "pactl set-sink-mute @DEFAULT_SINK@ toggle")
  (start-process-shell-command "notify" nil "sh -c 'MUTE=$(pactl get-sink-mute @DEFAULT_SINK@); if echo \"$MUTE\" | grep -q \"yes\"; then notify-send -t 1500 -i audio-volume-muted \"Volume\" \"Muted\"; else VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o \"[0-9]*%\" | head -1); notify-send -t 1500 -i audio-volume-medium \"Volume\" \"$VOL\"; fi'"))

;; Brightness control functions with notifications
(defun exwm-brightness-up ()
  "Increase brightness by 5%."
  (interactive)
  (start-process-shell-command "brightnessctl" nil "brightnessctl set +5%")
  (start-process-shell-command "notify" nil "sh -c 'BRIGHTNESS=$(brightnessctl get); MAX=$(brightnessctl max); PERCENT=$((BRIGHTNESS * 100 / MAX)); notify-send -t 1500 -i display-brightness-high \"Brightness\" \"${PERCENT}%\"'"))

(defun exwm-brightness-down ()
  "Decrease brightness by 5%."
  (interactive)
  (start-process-shell-command "brightnessctl" nil "brightnessctl set 5%-")
  (start-process-shell-command "notify" nil "sh -c 'BRIGHTNESS=$(brightnessctl get); MAX=$(brightnessctl max); PERCENT=$((BRIGHTNESS * 100 / MAX)); notify-send -t 1500 -i display-brightness-low \"Brightness\" \"${PERCENT}%\"'"))

;; Load Launcher module
(add-to-list 'load-path (expand-file-name "modules" doom-user-dir))
(require 'exwm-launcher)

;; Configure modeline with workspace and datetime only
(setq global-mode-string
      '((:eval (exwm-workspace-display))
        (:eval (exwm-datetime-display))))

;; Global keybindings.
(setq exwm-input-global-keys
      `(([?\s-r] . exwm-reset) ;; s-r: Reset (to line-mode).
        ([?\s-i] . exwm-input-toggle-keyboard) ;; s-i: Toggle line/char mode
        ([?\s-w] . exwm-workspace-switch) ;; s-w: Switch workspace.
        ([?\s-&] . (lambda (cmd) ;; s-&: Launch application.
                     (interactive (list (read-shell-command "$ ")))
                     (start-process-shell-command cmd nil cmd)))
        ;; s-N: Switch to certain workspace.
        ,@(mapcar (lambda (i)
                    `(,(kbd (format "s-%d" i)) .
                      (lambda ()
                        (interactive)
                        (exwm-workspace-switch-create ,i))))
                  (number-sequence 0 9))))
;; Safe X protocol operations with error handling
(defun my/safe-xcb-request (request-fn)
  "Safely execute an XCB request with error handling."
  (condition-case err
      (funcall request-fn)
    (error
     (message "XCB request failed: %s" err)
     nil)))

;; Visual indicator for EXWM input mode via border color
(defun exwm-update-top-border-color ()
  "Update window border with colored edge, adjusting size to fit screen."
  (when (and (derived-mode-p 'exwm-mode) exwm--id 
             (eq (current-buffer) (window-buffer (selected-window)))
             exwm--connection)
    (my/safe-xcb-request
     (lambda ()
       (let* ((border-pixel (if (eq exwm--input-mode 'line-mode)
                               16745843  ; Gruvbox muted orange for line-mode
                             8355711))  ; Gruvbox muted blue for char-mode
              (geometry (xcb:+request-unchecked+reply exwm--connection
                           (make-instance 'xcb:GetGeometry :drawable exwm--id))))
         (when geometry
           (let ((width (slot-value geometry 'width))
                 (height (slot-value geometry 'height))
                 (x (slot-value geometry 'x))
                 (y (slot-value geometry 'y)))
             ;; Adjust window size to account for border
             (when (> (+ x width) (- (x-display-pixel-width) 2))
               (xcb:+request exwm--connection
                   (make-instance 'xcb:ConfigureWindow
                                  :window exwm--id
                                  :value-mask xcb:ConfigWindow:Width
                                  :width (- width 2))))
             ;; Set thin border
             (xcb:+request exwm--connection
                 (make-instance 'xcb:ConfigureWindow
                                :window exwm--id
                                :value-mask xcb:ConfigWindow:BorderWidth
                                :border-width 1))
             ;; Set border color
             (xcb:+request exwm--connection
                 (make-instance 'xcb:ChangeWindowAttributes
                                :window exwm--id
                                :value-mask xcb:CW:BorderPixel
                                :border-pixel border-pixel))
             (xcb:flush exwm--connection))))))))

(defun exwm-update-border-width ()
  "Set border width for EXWM windows."
  (when (and (derived-mode-p 'exwm-mode) exwm--id exwm--connection)
    (my/safe-xcb-request
     (lambda ()
       (xcb:+request exwm--connection
           (make-instance 'xcb:ConfigureWindow
                          :window exwm--id
                          :value-mask xcb:ConfigWindow:BorderWidth
                          :border-width 1))
       (xcb:flush exwm--connection)))))

(defun exwm-clear-inactive-borders ()
  "Remove borders from inactive EXWM windows."
  (when exwm--connection
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (and (derived-mode-p 'exwm-mode) exwm--id
                   (not (eq buffer (window-buffer (selected-window)))))
          (my/safe-xcb-request
           (lambda ()
             ;; Remove border completely
             (xcb:+request exwm--connection
                 (make-instance 'xcb:ConfigureWindow
                                :window exwm--id
                                :value-mask xcb:ConfigWindow:BorderWidth
                                :border-width 0))
             (xcb:flush exwm--connection))))))))

(defun exwm-update-all-borders ()
  "Update border colors for all windows based on focus."
  (when (and (fboundp 'exwm-clear-inactive-borders)
             (fboundp 'exwm-update-top-border-color)
             exwm--connection)
    (ignore-errors
      (exwm-clear-inactive-borders)
      (exwm-update-top-border-color))))

;; Update border color when input mode changes
(add-hook 'exwm-input-input-mode-change-hook #'exwm-update-top-border-color)
(add-hook 'window-selection-change-functions 
          (lambda (&rest _) 
            (ignore-errors (exwm-update-all-borders))))
(add-hook 'buffer-list-update-hook 
          (lambda () 
            (ignore-errors (exwm-update-all-borders))))
(add-hook 'focus-in-hook 
          (lambda () 
            (ignore-errors (exwm-update-all-borders))))
(add-hook 'mouse-leave-buffer-hook 
          (lambda () 
            (ignore-errors (exwm-update-all-borders))))

;; Set default X cursor
(setq x-pointer-shape x-pointer-hand2)
(set-mouse-color "white")

;; Enable EXWM
(exwm-wm-mode)


;; Helper functions for robust startup
(defun my/wait-for-x11-ready ()
  "Wait for X11 to be fully ready for operations."
  (let ((max-attempts 50)
        (attempt 0)
        (ready nil))
    (while (and (< attempt max-attempts) (not ready))
      (condition-case nil
          (progn
            (x-display-pixel-width)
            (x-display-pixel-height)
            (setq ready t))
        (error
         (setq attempt (1+ attempt))
         (sleep-for 0.1))))
    ready))

(defun my/wait-for-process-start (process-name command max-wait)
  "Wait for a process to actually start, up to MAX-WAIT seconds."
  (let ((start-time (float-time))
        (started nil))
    (while (and (< (- (float-time) start-time) max-wait)
                (not started))
      (when (get-process process-name)
        (setq started t))
      (unless started
        (sleep-for 0.1)))
    started))

(defun my/safe-start-process (name command args)
  "Safely start a process with error handling."
  (condition-case err
      (apply 'start-process name nil command args)
    (error
     (message "Failed to start %s: %s" name err)
     nil)))

(defun my/kill-orphaned-processes (process-pattern)
  "Kill orphaned processes matching PROCESS-PATTERN."
  (ignore-errors
    (call-process "pkill" nil nil nil "-f" process-pattern)))

;; System tray setup with proper dependency checking
(defun my/start-system-tray ()
  "Start system tray components with proper sequencing."
  (interactive)
  (when (my/wait-for-x11-ready)
    ;; Start trayer first if not running
    (unless (get-process "trayer")
      ;; Clean up any orphaned trayer processes
      (my/kill-orphaned-processes "trayer")
      (sleep-for 0.2)  ; Brief pause after cleanup
      
      (let* ((screen-width (x-display-pixel-width))
             (tray-width (min 150 (/ screen-width 10)))
             (tray-height (if (> screen-width 1600) 24 20)))
        (when (my/safe-start-process
               "trayer" "trayer"
               (list "--edge" "top" "--align" "right" 
                     "--SetDockType" "true" "--SetPartialStrut" "true"
                     "--expand" "false" "--widthtype" "pixel" 
                     "--width" (number-to-string tray-width)
                     "--heighttype" "pixel" 
                     "--height" (number-to-string tray-height)
                     "--transparent" "true" "--alpha" "256" 
                     "--tint" "0x00000000" "--distance" "2"))
          ;; Wait for trayer to be ready before starting applets
          (my/wait-for-process-start "trayer" nil 3.0))))
    
    ;; Start applets sequentially, only if not already running
    (let ((applets '(("nm-applet" . "nm-applet")
                     ("blueman-applet" . "blueman-applet")  
                     ("dunst" . "dunst")
                     ("protonvpn-app" . "protonvpn-app"))))
      (dolist (applet applets)
        (let ((process-name (car applet))
              (command (cdr applet)))
          (unless (get-process process-name)
            (my/safe-start-process process-name command nil)
            (sleep-for 0.2)))))))  ; Small delay between applets

;; Hook system tray startup into EXWM initialization
(add-hook 'exwm-init-hook #'my/start-system-tray)

;; Background services startup with dependency checking
(defun my/start-background-services ()
  "Start background services after X11 is ready."
  (when (my/wait-for-x11-ready)
    ;; Set root window cursor
    (my/safe-start-process "xsetroot-cursor" "xsetroot" '("-cursor_name" "hand2"))
    (sleep-for 0.1)
    
    ;; Start picom for compositing
    (unless (get-process "picom")
      (my/safe-start-process "picom" "picom" '("--vsync")))
    (sleep-for 0.1)
    
    ;; Start screen lock daemon
    (unless (get-process "xss-lock")
      (my/safe-start-process "xss-lock" "xss-lock" '("--" "betterlockscreen" "-l")))))

;; Hook background services to EXWM init
(add-hook 'exwm-init-hook #'my/start-background-services)

;; Natural scrolling configuration with dependency checking
(defun exwm-enable-natural-scrolling ()
  "Enable natural scrolling for touchpad and mouse devices."
  (interactive)
  (when (my/wait-for-x11-ready)
    ;; Wait a bit for input devices to be fully initialized
    (sleep-for 0.5)
    ;; Enable natural scrolling for touchpad
    (ignore-errors
      (my/safe-start-process
       "natural-scroll-touchpad" "xinput"
       '("set-prop" "ELAN050A:01 04F3:3158 Touchpad" 
         "libinput Natural Scrolling Enabled" "1")))
    ;; Enable for mouse if present
    (ignore-errors
      (my/safe-start-process
       "natural-scroll-mouse" "xinput"
       '("set-prop" "ELAN050A:01 04F3:3158 Mouse" 
         "libinput Natural Scrolling Enabled" "1")))
    (message "Natural scrolling enabled")))

;; Delayed natural scrolling setup - wait for input subsystem
(defun my/setup-natural-scrolling ()
  "Set up natural scrolling after input devices are ready."
  (run-with-idle-timer 2.0 nil #'exwm-enable-natural-scrolling))

;; Apply natural scrolling after EXWM is fully initialized
(add-hook 'exwm-init-hook #'my/setup-natural-scrolling)
(exwm-input-set-key (kbd "s-n") #'exwm-enable-natural-scrolling)

;; Lock screen functionality
(defun exwm-lock-screen ()
  "Lock the screen using betterlockscreen with blur effect."
  (interactive)
  (start-process-shell-command "betterlockscreen" nil "betterlockscreen -l blur"))

(defun exwm-lock-screen-dim ()
  "Lock the screen using betterlockscreen with dim effect."
  (interactive)
  (start-process-shell-command "betterlockscreen" nil "betterlockscreen -l dim"))

(defun exwm-lock-screen-pixel ()
  "Lock the screen using betterlockscreen with pixel effect."
  (interactive)
  (start-process-shell-command "betterlockscreen" nil "betterlockscreen -l pixel"))

;; Lock screen keybindings
(exwm-input-set-key (kbd "s-l") #'exwm-lock-screen)        ; Blur effect
(exwm-input-set-key (kbd "s-L") #'exwm-lock-screen-dim)    ; Dim effect
(exwm-input-set-key (kbd "s-C-l") #'exwm-lock-screen-pixel) ; Pixel effect

;; Media key bindings
(exwm-input-set-key (kbd "<XF86AudioPlay>")
                    (lambda () (interactive)
                      (start-process-shell-command "playerctl" nil "playerctl play-pause")))

(exwm-input-set-key (kbd "<XF86AudioPause>")
                    (lambda () (interactive)
                      (start-process-shell-command "playerctl" nil "playerctl play-pause")))

(exwm-input-set-key (kbd "<XF86AudioNext>")
                    (lambda () (interactive)
                      (start-process-shell-command "playerctl" nil "playerctl next")))

(exwm-input-set-key (kbd "<XF86AudioPrev>")
                    (lambda () (interactive)
                      (start-process-shell-command "playerctl" nil "playerctl previous")))

(exwm-input-set-key (kbd "<XF86AudioRaiseVolume>") 'exwm-volume-up)
(exwm-input-set-key (kbd "<XF86AudioLowerVolume>") 'exwm-volume-down)
(exwm-input-set-key (kbd "<XF86AudioMute>") 'exwm-volume-mute-toggle)

;; Brightness control
(exwm-input-set-key (kbd "<XF86MonBrightnessUp>") 'exwm-brightness-up)
(exwm-input-set-key (kbd "<XF86MonBrightnessDown>") 'exwm-brightness-down)



;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-gruvbox)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
