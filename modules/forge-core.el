;;; forge-core.el --- Set up the core.  -*- lexical-binding: t -*-

;; Copyright (C) 2018-2020 Stephen Fromm

;; Author: Stephen Fromm

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(defvar forge-emacs-dir (file-truename user-emacs-directory)
  "Path to this emacs.d directory.")

(defvar forge-modules-dir (concat forge-emacs-dir "modules/")
  "Path to built-in modules.")

(defvar forge-site-dir (concat forge-emacs-dir "site-lisp/")
  "Path to user's site configuration.")

(defvar forge-personal-dir (concat forge-emacs-dir "user/")
  "Path to user's personal configuration.")

(defvar forge-themes-dir (concat forge-emacs-dir "themes/")
  "Path to user themes.")

(defvar forge-state-dir (concat forge-emacs-dir "var/")
  "Path to Emacs' persistent data files.")

(defvar forge-backup-dir (concat forge-state-dir "backup/")
  "Path to Emacs' backup and autosave files.")

(defvar forge-log-dir (concat forge-state-dir "log/")
  "Path to Emacs packages' log files.")

(defgroup forge nil
  "Forge custom settings."
  :group 'environment)

(add-to-list 'load-path forge-modules-dir)
(add-to-list 'load-path forge-site-dir)
(add-to-list 'custom-theme-load-path forge-themes-dir)


;;;
;;; Everyone loves garbage collection
;;;
(defvar forge--file-name-handler-alist file-name-handler-alist)

;; Crank garbage collection to 11 for initialization.
;; Reset after init
(setq file-name-handler-alist nil
      message-log-max 16384
      gc-cons-threshold 536870912 ;; 512mb
      gc-cons-percentage 0.6)

;; only run garbage collection after 50MB of allocated data.
(defun forge/reset-startup-settings ()
  "Reset garbage collection related settings to normal settings."
  (setq file-name-handler-alist forge--file-name-handler-alist)
  (setq gc-cons-threshold 16777216 ;; 16mb
        gc-cons-percentage 0.1
        message-log-max 1024))

(add-hook 'after-init-hook #'forge/reset-startup-settings)
(add-hook 'focus-out-hook #'garbage-collect)


;;;
;;; Packages
;;;
(require 'forge-package)


;;;
;;; Helper functions
;;;
(defun forge/turn-on-hl-line ()
  "Turn on `hl-line-mode'."
  (interactive)
  (hl-line-mode 1))

(defun forge/turn-off-hl-line ()
  "Turn off `hl-line-mode'."
  (interactive)
  (hl-line-mode nil))

(defun forge/turn-on-delete-trailing-whitespace ()
  "Turn on `delete-trailing-whitespace' when saving files."
  (add-hook 'before-save-hook 'delete-trailing-whitespace nil t))

(defun forge/turn-off-delete-trailing-whitespace ()
  "Turn off `delete-trailing-whitespace' when saving files."
  (remove-hook 'before-save-hook 'delete-trailing-whitespace t))

(defun forge/clean-user-emacs-directory ()
  "Set appropriate paths to keep `user-emacs-directory' clean."
  (interactive)
  (with-no-warnings
    (setq gamegrid-user-score-file-directory (concat forge-state-dir "games")
          bookmark-default-file (concat forge-state-dir "bookmarks")
          transient-history-file (concat forge-state-dir "transient/history.el")
          transient-levels-file (concat forge-personal-dir "transient/levels.el")
          transient-values-file (concat forge-personal-dir "transient/values.el")
          message-auto-save-directory (concat forge-state-dir "messages")
          tramp-auto-save-directory (concat forge-state-dir "tramp/auto-save")
          tramp-persistency-file-name (concat forge-state-dir "tramp/persistency.el")
          url-cache-directory (concat forge-state-dir "url/cache/")
          url-configuration-directory (concat forge-state-dir "url/configuration/"))))

(defun forge/message-module-load (mod time)
  "Log message on how long it took to load module MOD from TIME."
  (message "Loaded %s (%0.2fs)" mod (float-time (time-subtract (current-time) time))))

(defun forge-initialize ()
  "Initialize paths and session for this Emacs instance."
  (dolist (dir (list forge-site-dir forge-personal-dir forge-state-dir forge-backup-dir forge-log-dir))
    (unless (file-directory-p dir)
      (make-directory dir t)))
  (forge/clean-user-emacs-directory)
  (setq inhibit-splash-screen t
        ;; always load the newer version of a file
        load-prefer-newer t
        ;; only run garbage collection after 50MB of allocated data.
        gc-cons-threshold 50000000
        ;; warn when opening files bigger than 50MB
        large-file-warning-threshold 50000000))

(defun forge/load-directory-modules (path)
  "Load Lisp files in PATH directory."
  (let ((t1 (current-time)))
    (when (file-exists-p path)
      (message "Loading lisp files in %s..." path)
      (mapc 'load (directory-files path 't "^[^#\.].*el$"))
      (forge/message-module-load path t1))))

(defun forge/load-modules (&rest modules)
  "Load forge modules MODULES."
  (interactive)
  (dolist (module (cons '() modules ))
    (when module
      (let ((t1 (current-time)))
        (unless (featurep module)
          (require module nil t)
          (forge/message-module-load module t1))))))

;; Via jwiegley
;; https://github.com/jwiegley/dot-emacs/blob/master/init.el
(defun lookup-password (host user port)
  "Look up password for HOST, USER, and PORT."
  (require 'auth-source)
  (require 'auth-source-pass)
  (let ((auth (auth-source-search :host host :user user :port port)))
    (if auth
        (let ((secretf (plist-get (car auth) :secret)))
          (if secretf
              (funcall secretf)
            (error "Auth entry for %s@%s:%s has no secret!"
                   user host port)))
      (error "No auth entry found for %s@%s:%s" user host port))))

;; Via https://emacs.stackexchange.com/questions/8104/is-there-a-mode-to-automatically-update-copyright-years-in-files
(defun forge/enable-copyright-update ()
  "Update copyright year when saving a file."
  (when (fboundp 'copyright-update)
    (setq copyright-names-regexp "Free Software")
    (add-hook 'before-save-hook #'copyright-update)))

;;;
;;; look up current playing song in itunes
;;; useful resources:
;;; - https://apple.stackexchange.com/questions/297240/getting-the-file-path-of-a-currently-playing-itunes-track-with-applescript
;;; - https://alvinalexander.com/blog/post/mac-os-x/applescript-concatenate-strings
;;;
(defun forge/get-current-song-itunes ()
  "Get current song playing via itunes."
  (let ((as-tmpl "")
        (cursong nil))
    (setq as-tmpl "tell application \"Music\"
	if player state is not stopped then
		set ct to (properties of current track)
		set this_song to \"\"
		if (class of ct is URL track) and (get current stream title) is not missing value then
			set this_song to (get current stream title)
		else
			set this_song to artist in ct & \" - \" & name in ct
		end if
		this_song
	end if
end tell")
    (condition-case nil
        (setq cursong (split-string (do-applescript as-tmpl) " - "))
      (error nil))
    cursong))

;; Delete window if not the only one.
(defun forge/delete-window ()
  "Delete window if it is not the only one."
  (when (not (one-window-p))
    (delete-window)))


;; Peek at queries

(defcustom forge-peek-buffer-name "*forge-peek*"
  "Buffer for peeking at data."
  :group 'forge
  :type 'string)

(defun forge/peek-first ()
  "Go to beginning of peek buffer."
  (interactive)
  (goto-char (point-min)))

(defun forge/peek-last ()
  "Go to end of peek buffer."
  (interactive)
  (goto-char (point-max)))

(defvar forge-peek-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") 'delete-frame)
    (define-key map (kbd "<") 'forge/peek-first)
    (define-key map (kbd ">") 'forge/peek-last)
    map)
  "Keymap for forge-peek mode.")

(define-derived-mode forge-peek-mode fundamental-mode "ForgePeek"
                     "A major mode for peeking at query responses."
                     :group 'forge
                     (setq buffer-read-only t)
                     (setq buffer-undo-list t))

(defun forge/peek-make-buffer ()
  "Return the peek query buffer."
  (let ((buffer (get-buffer-create forge-peek-buffer-name)))
    (with-current-buffer buffer (forge-peek-mode))
    buffer))

;; Make a peek-frame, a modified version of what is from here:
;; https://tuhdo.github.io/emacs-frame-peek.html
(defun forge/peek-make-frame (func &rest args)
  "Make a new frame for peeking at information.  Provide FUNC that will return data and optional ARGS."
  (let ((summary)
        (peek-frame)
        (x) (y)
        (abs-pixel-pos (save-excursion
                         ;; (beginning-of-thing 'word)
                         (window-absolute-pixel-position))))
    (setq x (car abs-pixel-pos))
    (setq y (+ (cdr abs-pixel-pos) (frame-char-height)))

    (setq peek-frame (make-frame '((minibuffer . nil)
                                   (name . "*Peek*")
                                   (width . 80)
                                   (visibility . nil)
                                   (height . 25))))
    (message "peek %s" peek-frame)

    (set-frame-position peek-frame x y)

    (with-selected-frame peek-frame
      (forge/peek-make-buffer)
      (funcall func)
      (recenter-top-bottom 0)
      (select-window (display-buffer forge-peek-buffer-name t t))
      (delete-other-windows))

    (make-frame-visible peek-frame)))

(defun forge/peek-ip-qry ()
  "Look up information on IP address."
  (interactive)
  (let ((qry (lambda ()
               (let ((ipqry (concat (getenv "HOME") "/src/ncon/ncon.sh"))
                     (ipaddr))
                 (if (not (region-active-p))
                     (setq ipaddr (read-string "IP address: "))
                   (setq ipaddr (buffer-substring (region-beginning) (region-end))))
                 (with-current-buffer forge-peek-buffer-name
                   (let ((inhibit-read-only t))
                     (goto-char (point-max))
                     (call-process ipqry nil forge-peek-buffer-name t "ip qry " ipaddr)))))))
    (forge/peek-make-frame qry)))


;;;
;;; Platform specific details.
;;;
(defun forge/system-type-darwin-p ()
  "Return non-nil if system is Darwin/MacOS."
  (string-equal system-type "darwin"))

(defun forge/system-type-windows-p ()
  "Return non-nil if system is Windows."
  (string-equal system-type "windows-nt"))

(defun forge/system-type-linux-p ()
  "Return non-nil if system is GNU/Linux."
  (string-equal system-type "gnu/linux"))

;;;
;;; exec-path-from-shell
;;; Set exec-path based on shell PATH.
;;; Some platforms, such as MacOSX, do not get this done correctly.
;;;
(use-package exec-path-from-shell
  :defer t
  :init
  (exec-path-from-shell-initialize))

(when (forge/system-type-linux-p)
  (require 'dbus))

(when (forge/system-type-darwin-p)
  (dolist (path (list "/usr/local/bin" (expand-file-name "~/bin")))
    (progn
      (setenv "PATH" (concat path ":" (getenv "PATH")))
      (add-to-list 'exec-path path))))


;;;
;;; Set up the server
;;;
(load "server")
(unless (server-running-p) (server-start))
(forge-initialize)

;;;
(provide 'forge-core)
;;; forge-core.el ends here
