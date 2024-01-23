;;; init-ui-completion.el --- Init UI Completion elements -*- lexical-binding: t -*-
;; UI Completion elements
;; Copyright (C) 2021, 2022 by Stephen Fromm

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


(use-package which-key
  :custom (which-key-idle-delay 1.5)
  :demand t
  :diminish
  :commands which-key-mode
  :config (which-key-mode))


;;; Completion
;; https://github.com/minad/vertico
(use-package vertico
  :demand t
  :init
  (vertico-mode))

;; https://github.com/oantolin/orderless
(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic)))

;; https://github.com/minad/consult
(use-package consult
  :demand t
  :bind
  ;; M-g go-to map
  (("M-g g" . consult-goto-line)
   ("M-g h" . consult-org-heading)
   ("M-g i" . consult-imenu)
   ;; M-s search map
   ("M-s l" . consult-line)
   ("M-s g" . consult-grep)
   ("M-s G" . consult-git-grep)
   ("M-s r" . consult-ripgrep)
   ("M-y" . consult-yank-pop)
   ([remap switch-to-buffer] . consult-buffer)
   ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
   ([remap switch-to-buffer-other-frame] . consult-buffer-other-frame)
   ("C-c f" . consult-find))
  :config
  (setq consult-narrow-key "<"
        consult-project-root-function
        (lambda ()
          (when-let (project (project-current))
            (car (project-roots project))))))

;; https://github.com/minad/marginalia
(use-package marginalia
  :demand t
  :bind (:map minibuffer-local-map
              ("C-M-a" . marginalia-cycle))
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  :config
  (marginalia-mode))

(provide 'init-ui-completion)
