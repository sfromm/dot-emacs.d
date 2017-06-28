;; build - Tangle all org-babel files to their configy-goodness
;;
;; Written by Stephen Fromm <sfromm gmail com>
;; (C) 2016 Stephen Fromm
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.
;;
;; The goal is that this can be pulled in by emacs from the CLI
;; tangle out all the relevant dot-files.  This then can be called
;; by make or something similar.
;;
;; Invocation:  emacs --batch --load ~/.emacs.d/build.el

(require 'em-glob)
(require 'org)       ;; org-mode
(require 'ob)        ;; org-mode export
(require 'ob-tangle) ;; and finally org-mode tangle

(defun sf/tangle-file (file)
  "Given an 'org-mode' FILE, tangle the source code"
  (interactive "fOrg File: ")
  (find-file file)
  (org-babel-tangle)
  (kill-buffer))

(defun sf/tangle-files (path &optional full)
  "Tangle files in path (directory)"
  (interactive)
  (mapc 'sf/tangle-file (sf/get-files path full)))

(defun sf/get-files (path &optional full)
  "Return list of files in directory that match glob pattern"
  (directory-files (file-name-directory path)
    full
    (eshell-glob-regexp (file-name-nondirectory path))))

(defun sf/build-configs ()
  "Tangle all configs"
  (interactive)
  (sf/tangle-files "~/.emacs.d/*.org")
  (sf/tangle-files "~/forge/*.org" t))

(sf/build-configs)

(provide 'dot-files)
