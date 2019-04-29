;;; forge-orgmode.el --- This is an Emacs Lisp file with Emacs Lisp code. -*- lexical-binding: t -*-

;; Copyright (C) Stephen Fromm

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

(use-package org
    :ensure org-plus-contrib
    :preface
    (defun forge/capture-current-song ()
      "Capture the current song details."
      (let ((itunes-song (forge/get-current-song-itunes))
            (mpd-song (or (forge/get-current-song-mpd) nil))
            (song-info nil))
        (setq song-info (if itunes-song itunes-song mpd-song))
        (concat (car song-info) ", \"" (car (cdr song-info)) "\"")))

    (defun forge/org-tbl-export (name)
      "Search for table named `NAME` and export"
      (interactive "s")
      (show-all)
      (push-mark)
      (goto-char (point-min))
      (let ((case-fold-search t))
        (if (search-forward-regexp (concat "#\\+NAME: +" name) nil t)
            (progn
              (next-line)
              (org-table-export (format "%s.csv" name) "orgtbl-to-csv"))))
      (pop-mark))

    (defun forge/tangle-org-mode-on-save ()
      "Tangle org-mode file when saving."
      (when (string= (message "%s" major-mode) "org-mode")
        (org-babel-tangle)))

    (defun forge/org-mode-hook ()
      "Turn on settings for org-mode."
      (interactive)
      (set-fill-column 100)
      (when (fboundp 'turn-on-auto-fill)
        (turn-on-auto-fill))
      (when (fboundp 'turn-on-flyspell)
        (turn-on-flyspell)))

    ;; via https://vxlabs.com/2018/10/29/importing-orgmode-notes-into-apple-notes/
    (defun forge/org-html-publish-to-html-for-apple-notes (plist filename pub-dir)
      "Convert exported files to format that plays nicely with Apple Notes. Takes PLIST, FILENAME, and PUB-DIR."
      ;; https://orgmode.org/manual/HTML-preamble-and-postamble.html
      ;; disable author + date + validate link at end of HTML exports
      ;;(setq org-html-postamble nil)

      (let* ((org-html-with-latex 'imagemagick)
             (outfile
              (org-publish-org-to 'html filename
                                  (concat "." (or (plist-get plist :html-extension)
                                                  org-html-extension
                                                  "html"))
                                  plist pub-dir)))
        ;; 1. apple notes handles <p> paras badly, so we have to replace all blank
        ;;    lines (which the orgmode export accurately leaves for us) with
        ;;    <br /> tags to get apple notes to actually render blank lines between
        ;;    paragraphs
        ;; 2. remove large h1 with title, as apple notes already adds <title> as
        ;; the note title
        (shell-command (format "sed -i \"\" -e 's/^$/<br \\/>/' -e 's/<h1 class=\"title\">.*<\\/h1>$//' %s" outfile)) outfile))

    :hook
    ((org-mode . forge/org-mode-hook)
     (after-save . forge/tangle-org-mode-on-save)
     (org-mode . variable-pitch-mode))

    :bind (("<f8>" . org-cycle-agenda-files)
	   ("<f12>" . org-agenda)
	   ("C-c l" . org-store-link)
	   ("C-c c" . org-capture)
	   ("C-c a" . org-agenda)
	   ("C-c b" . org-switchb))
    :bind (:map org-mode-map
	        ("M-q" . endless/fill-or-unfill)
	        ("C-c >" . org-time-stamp-inactive)
	        ("RET" . org-return-indent))
    :init
    (setq org-directory "~/forge"
	  org-agenda-files (list
			    (concat org-directory "/journal.org")
			    (concat org-directory "/tasks.org")
			    (concat org-directory "/work.org")
			    (concat org-directory "/personal.org")
			    (concat org-directory "/notebook.org"))
	  org-default-notes-file (concat org-directory "/journal.org")
	  org-file-apps (quote ((auto-mode . emacs)
			        ("\\.doc\\'" . "open %s")
			        ("\\.docx\\'" . "open %s")
			        ("\\.xlsx\\'" . "open %s")
			        ("\\.pptx\\'" . "open %s")
			        ("\\.pdf\\'" . default)))

	  org-agenda-sticky t
	  org-agenda-restore-windows-after-quit t
	  org-agenda-window-setup 'current-window

	  org-ellipsis "⤵"
	  org-log-done t
	  org-log-reschedule "note"

	  org-capture-templates '(("j" "Journal" entry (function org-journal-find-location)
                                   "* %(format-time-string org-journal-time-format)%^{Title}\n%i%?")
                                  ("b" "Bookmark" entry (file+headline "~/forge/startpage.org" "Unfiled")
                                   "* %? %^L %^g \n:PROPERTIES:\n:CREATED: %U\n:END:\n\n" :prepend t)
                                  ("t" "To do" entry (file+headline "~/forge/tasks.org" "Tasks")
                                   "* TODO %?\nSCHEDULED: %(org-insert-time-stamp (org-read-date nil t \"+0d\"))\n%a\n")
                                  ("m" "Music" entry  (file+olp+datetree "~/forge/journal.org")
                                   "** %?%U %(forge/capture-current-song) :music:\n"))

          org-export-allow-bind-keywords t
          org-export-coding-system 'utf-8

          org-modules '(org-w3m org-bbdb org-bibtex org-docview
                        org-gnus org-info org-irc org-mhe org-rmail org-habit)
          org-src-preserve-indentation t
          org-src-window-setup 'current-window                    ;; use current window when editing a source block
          org-cycle-separator-lines 2                             ;; leave this many empty lines in collapsed view
          org-table-export-default-format "orgtbl-to-csv"         ;; export tables as CSV instead of tab-delineated
          org-todo-keywords '((sequence "TODO(t)" "WAITING(w)" "DELEGATED(l)" "|" "DONE(d)")
                              (sequence "|" "CANCELLED(c)"))
          org-publish-project-alist '(("public"
                                       :base-directory "~/forge"
                                       :publishing-directory "~/Documents")))
    (org-babel-do-load-languages 'org-babel-load-languages '((ditaa . t)
							     (emacs-lisp . t)
							     (org . t)
							     (perl . t)
							     (python . t)
							     (ruby . t)
							     (shell . t)
							     (calc . t)))

    (org-load-modules-maybe t)
    ;; Keep tables with a fixed-pitch font.
    (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
    (set-face-attribute 'org-code nil :inherit 'fixed-pitch)
    (set-face-attribute 'org-block nil :inherit 'fixed-pitch)

    (add-to-list 'auto-mode-alist '("doc/org/.*\\.org$" . org-mode)))


(use-package org-git-link)

(use-package org-contacts
    :after org
    :config
    (setq org-contacts-files (list  "~/forge/contacts.org"))
    (add-to-list 'org-capture-templates '("c" "Contacts" entry (file (concat org-directory "/contacts.org"))
					  "* %(org-contacts-template-name)\n:PROPERTIES:\n:EMAIL: %(org-contacts-template-email)\n:PHONE:\n:ADDRESS:\n:BIRTHDAY:\n:END:")))

(use-package org-bullets
    :ensure t
    :after org
    :init (add-hook 'org-mode-hook 'org-bullets-mode))

(use-package org-id
    :after org
    :config
    (setq org-id-method 'uuid
	  org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id))

(use-package org-indent
    :diminish t
    :config
    (setq org-startup-indented t))

(use-package ox-twbs
    :ensure t)

(use-package org-mime
    :ensure nil
    :defer t
    :init
    (setq org-mime-export-options '(:section-numbers nil
                                    :with-author nil
                                    :with-toc nil)))

(use-package ox-reveal
    :ensure t
    :init
    (setq org-reveal-note-key-char nil))

(use-package ox-tufte
    :ensure t)


;;;
;;; org-journal
;;; https://github.com/bastibe/org-journal
(use-package org-journal
    :ensure t
    :preface
    (defun org-journal-find-location ()
      "Open today's journal file."
      ;; Open today's journal, but specify a non-nil prefix argument in order to
      ;; inhibit inserting the heading; org-capture will insert the heading.
      (org-journal-new-entry t)
      ;; Position point on the journal's top-level heading so that org-capture
      ;; will add the new entry as a child entry.
      (goto-char (point-min)))

    :init
    (setq org-journal-dir (concat org-directory "/journal/")
          org-journal-file-type 'yearly
          org-journal-file-format "%Y"
          org-journal-date-format "%A, %d %B %Y"))


(use-package org-present
    :ensure t
    :defer 20
    :init
    (add-hook 'org-present-mode-hook
	      (lambda ()
		(org-present-big)
		(org-display-inline-images)
		(org-present-hide-cursor)
		(org-present-read-only)))
    (add-hook 'org-present-mode-quit-hook
	      (lambda ()
		(org-present-small)
		(org-remove-inline-images)
		(org-present-show-cursor)
		(org-present-read-write))))


(use-package org-pomodoro
    :ensure t
    :bind
    (("C-c C-x C-i" . org-pomodoro)
     ("C-c C-x C-o" . org-pomodoro))

    :preface
    (defun forge/notify-pomodoro (title message)
      (notifications-notify
       :title title
       :body message
       :urgency 'low))

    :hook
    (org-pomodoro-finished . (lambda () (forge/notify-pomodoro "Pomodoro completed" "Time for a break")))
    (org-pomodoro-break-finished . (lambda () (forge/notify-pomodoro "Break completed" "Ready for another?")))
    (org-pomodoro-long-break-finished . (lambda () (forge/notify-pomodoro "Long break completed" "Ready for another?")))

    :init
    (setq
     org-pomodoro-audio-player "mpv"
     org-pomodoro-finished-sound "~/annex/Music/drip.ogg"))


(defun forge/tangle-file (file)
  "Given an 'org-mode' FILE, tangle the source code."
  (interactive "fOrg File: ")
  (find-file file)
  (org-babel-tangle)
  (kill-buffer))

(defun forge/tangle-files (path &optional full)
  "Tangle files in PATH (directory), FULL for absolute paths.
Example: (forge/tangle-files \"~/.emacs.d/*.org\")."
  (interactive)
  (mapc 'forge/tangle-file (forge/get-files path full)))

(defun forge/get-files (path &optional full)
  "Return list of files in directory PATH that match glob pattern, FULL for absolute paths."
  (directory-files (file-name-directory path)
                   full
                   (eshell-glob-regexp (file-name-nondirectory path))))


(provide 'forge-orgmode)
;;; forge-orgmode.el ends here
