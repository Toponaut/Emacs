;;; exwm-launcher.el --- Application launcher for EXWM -*- lexical-binding: t; -*-

(defvar exwm-launcher--app-cache nil
  "Cache for parsed desktop applications.")

(defvar exwm-launcher--cache-timestamp 0
  "Timestamp when cache was last updated.")

(defvar exwm-launcher--cache-ttl 300
  "Cache time-to-live in seconds (5 minutes).")

(defvar exwm-launcher--desktop-paths
  '("/usr/share/applications/"
    "/usr/local/share/applications/"
    "~/.local/share/applications/"
    "~/.local/share/flatpak/exports/share/applications/"
    "/var/lib/flatpak/exports/share/applications/")
  "Paths to search for .desktop files.")

(defvar exwm-launcher--bin-paths
  '("/usr/bin/"
    "/usr/local/bin/"
    "~/.local/bin/")
  "Paths to search for executable files.")

(defun exwm-launcher--parse-desktop-file (file)
  "Parse a .desktop file and return app info."
  (when (and (file-exists-p file)
             (string-match-p "\\.desktop$" file))
    (with-temp-buffer
      (insert-file-contents file)
      (let ((name nil)
            (exec nil)
            (no-display nil)
            (hidden nil)
            (in-desktop-entry nil))
        (goto-char (point-min))
        (while (not (eobp))
          (let ((line (buffer-substring-no-properties
                       (line-beginning-position)
                       (line-end-position))))
            (cond
             ;; Check if we're entering the [Desktop Entry] section
             ((string-match "^\\[Desktop Entry\\]" line)
              (setq in-desktop-entry t))
             ;; Stop if we hit another section
             ((and in-desktop-entry (string-match "^\\[" line))
              (setq in-desktop-entry nil))
             ;; Only parse if we're in the Desktop Entry section
             ((and in-desktop-entry (string-match "^Name=\\(.+\\)$" line))
              (unless name (setq name (match-string 1 line))))
             ((and in-desktop-entry (string-match "^Exec=\\(.+\\)$" line))
              (unless exec (setq exec (match-string 1 line))))
             ((and in-desktop-entry (string-match "^NoDisplay=true" line))
              (setq no-display t))
             ((and in-desktop-entry (string-match "^Hidden=true" line))
              (setq hidden t))))
          (forward-line 1))
        (when (and name exec (not no-display) (not hidden))
          (list :name name :exec exec))))))

(defun exwm-launcher--clean-exec-command (exec-string)
  "Clean exec command by removing field codes like %f, %u, etc."
  (when exec-string
    (let ((cleaned (replace-regexp-in-string " %[fFuUdDnNickvm]" "" exec-string)))
      (string-trim cleaned))))

(defun exwm-launcher--scan-bin-directories ()
  "Scan bin directories for executable files (optimized)."
  (let ((executables '())
        (common-apps '("firefox" "chromium" "code" "gimp" "libreoffice"
                      "vlc" "thunderbird" "obs" "steam" "discord")))
    (dolist (path exwm-launcher--bin-paths)
      (let ((expanded-path (expand-file-name path)))
        (when (file-directory-p expanded-path)
          (dolist (app common-apps)
            (let ((app-path (expand-file-name app expanded-path)))
              (when (and (file-exists-p app-path)
                        (file-executable-p app-path))
                (push (cons app app) executables)))))))
    executables))

(defun exwm-launcher--scan-applications ()
  "Scan all desktop files and bin directories for applications."
  (let ((apps '()))
    ;; Scan desktop files
    (dolist (path exwm-launcher--desktop-paths)
      (let ((expanded-path (expand-file-name path)))
        (when (file-directory-p expanded-path)
          (dolist (file (directory-files expanded-path t "\\.desktop$"))
            (let ((app-info (exwm-launcher--parse-desktop-file file)))
              (when app-info
                (push (cons (plist-get app-info :name)
                           (exwm-launcher--clean-exec-command
                            (plist-get app-info :exec)))
                      apps)))))))
    
    ;; Scan executables in bin directories
    (let ((executables (exwm-launcher--scan-bin-directories))
          (desktop-commands (mapcar (lambda (app) 
                                     (car (split-string (cdr app)))) 
                                   apps)))
      ;; Only add executables that don't already have desktop entries
      (dolist (executable executables)
        (unless (member (cdr executable) desktop-commands)
          (push executable apps))))
    
    (sort apps (lambda (a b) (string< (car a) (car b))))))

(defun exwm-launcher--get-applications ()
  "Get cached applications or scan if cache is expired."
  (let ((current-time (float-time)))
    (when (or (null exwm-launcher--app-cache)
              (> (- current-time exwm-launcher--cache-timestamp) exwm-launcher--cache-ttl))
      (setq exwm-launcher--app-cache (exwm-launcher--scan-applications)
            exwm-launcher--cache-timestamp current-time)))
  exwm-launcher--app-cache)

(defun exwm-launcher-refresh-cache ()
  "Refresh the application cache."
  (interactive)
  (setq exwm-launcher--app-cache nil
        exwm-launcher--cache-timestamp 0)
  (exwm-launcher--get-applications)
  (message "Application cache refreshed (%d apps found)"
           (length exwm-launcher--app-cache)))

(defun exwm-launcher ()
  "Launch an application using Emacs completion."
  (interactive)
  (let* ((apps (exwm-launcher--get-applications))
         (app-names (mapcar #'car apps))
         (selected (completing-read "Launch app: " app-names nil t))
         (command (cdr (assoc selected apps))))
    (if command
        (progn
          (start-process-shell-command selected nil command)
          (message "Launched: %s" selected))
      (message "No command found for: %s" selected))))

(provide 'exwm-launcher)
;;; exwm-launcher.el ends here