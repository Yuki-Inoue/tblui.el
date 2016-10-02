;;; tblui.el --- Define tabulated list UI easily -*- lexical-binding: t -*-

;; Copyright (C) 2016 Yuki Inoue

;; Author: Yuki Inoue <inouetakahiroki _at_ gmail.com>
;; URL: https://github.com/Yuki-Inoue/tblui.el
;; Version: 0.0.1
;; Package-Requires: ((dash "2.12.1") (magit-popup "2.6.0") (tablist "0.70") (cl-lib "0.5"))

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Define tabulated list UI easily.

;;; Code:

(require 'tablist)
(require 'dash)
(require 'cl-lib)

(defun tblui--append-str-to-symbol (symbol str)
  (intern (concat (symbol-name symbol) str)))

(defun tblui--select-if-empty (&optional arg)
  "Select current row is selection is empty."
  (save-excursion
    (when (null (tablist-get-marked-items))
      (tablist-put-mark))))

(defmacro tblui-define (mode-name entries-provider table-layout popup-definitions)

  (let* ((goto-ui-symbol
          (tblui--append-str-to-symbol mode-name "-goto-ui"))
         (ui-buffer-name
          (concat "*" (symbol-name mode-name) "*"))
         (refresher-symbol
          (tblui--append-str-to-symbol mode-name "-refresher"))
         (mode-name-symbol
          (tblui--append-str-to-symbol mode-name "-mode"))
         (mode-map-symbol
          (tblui--append-str-to-symbol mode-name-symbol "-map"))
         (tablist-funcs
          (->> popup-definitions
               (mapcar (apply-partially #'assoc-default :funcs))
               (apply #'append)
               (mapcar (apply-partially #'nth 2))))
         (tablist-func-info-assoc
          (->> tablist-funcs
               (mapcar
                (lambda (tablist-func)
                  (cons tablist-func
                        (tblui--append-str-to-symbol tablist-func "-popup-interface")))))))

    `(progn
       (defun ,refresher-symbol ()
         (setq tabulated-list-entries (,entries-provider)))

       ,@(mapcar
          (lambda (tablist-func-info-entry)
            `(defun ,(cdr tablist-func-info-entry) ()
               (interactive)
               (,(car tablist-func-info-entry)
                (mapcar #'car (tablist-get-marked-items)))))
          tablist-func-info-assoc)

       ,@(mapcar
          (lambda (popup-definition)
            (let ((popup-name (assoc-default :name popup-definition))
                  (associated-funcs (assoc-default :funcs popup-definition)))
              `(progn
                 (magit-define-popup ,popup-name (quote ,mode-name)
                   :actions ',(mapcar
                               (lambda (entry)
                                 (cl-multiple-value-bind
                                     (key descr raw-func) entry
                                   (list key descr (assoc-default raw-func tablist-func-info-assoc))))
                               associated-funcs))
                 (add-function :before (symbol-function ',popup-name) #'tblui--select-if-empty))
              ))
            popup-definitions)

       (define-derived-mode ,mode-name-symbol tabulated-list-mode "Containers Menu"
         "Major mode for handling a list of docker containers."

         ,@(mapcar
            (lambda (popup-definition)
              (let ((key (assoc-default :key popup-definition))
                    (popup-name (assoc-default :name popup-definition)))
                `(define-key ,mode-map-symbol ,key (function ,popup-name))
                ))
            popup-definitions)

         (setq tabulated-list-format ,table-layout)
         (setq tabulated-list-padding 2)
         (add-hook 'tabulated-list-revert-hook (function ,refresher-symbol) nil t)
         (tabulated-list-init-header)
         (tablist-minor-mode))

       (defun ,goto-ui-symbol ()
         (pop-to-buffer ,ui-buffer-name)
         (tabulated-list-init-header)
         (,mode-name-symbol)
         (tabulated-list-revert))

       )
    ))

(provide 'tblui)
