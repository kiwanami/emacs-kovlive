;;; kovlive.el --- kovlang translator interface

;; Copyright (C) 2014  Masashi Sakurai

;; Author: SAKURAI Masashi <m.sakurai at kiwanami.net>
;; Keywords: i18n
;; Package-Requires: ((deferred "0.3.2"))
;; URL: https://github.com/kiwanami/emacs-kovlive

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

;; ﾘｯｼﾞｮﾝ指定してっ M-x kov:translate-region するっ

;;; Code:

(require 'deferred)

(defvar kov:libpath (file-name-directory (or load-file-name "."))
  "directory for the kovlive program.")

(defvar kov:kovlive-cmd (list "python3"
                              (expand-file-name
                               "kovlive/kovlive.py"
                               kov:libpath))
  "driver program info.")

(defun kov:translate-region (&optional beg end)
  (interactive "r")
  (if (use-region-p) 
      (lexical-let ((beg beg) (end end)
                    (text (buffer-substring-no-properties beg end)))
        (deferred:nextc 
          (kov:translate-text-d text)
          (lambda (trans-text) 
            (delete-region beg end)
            (goto-char beg)
            (insert trans-text))))))

(defun kov:translate-text-d (text)
  (lexical-let ((tmpfile (make-temp-file "kovlive")))
    (let ((coding-system-for-write 'utf-8)
          (tmpbuf (get-buffer-create " *kov-tmp*")))
      (with-current-buffer tmpbuf
        (erase-buffer)
        (insert text)
        (write-file tmpfile)
        (kill-buffer tmpbuf)))
    (deferred:try
      (deferred:next
        (lambda () (apply 'deferred:process (append kov:kovlive-cmd (list tmpfile)))))
      :catch
      (lambda (err) 
        (message "Kovlive error : %S" err))
      :finally
      (lambda () 
        (ignore-errors 
          (when (file-exists-p tmpfile)
            (delete-file tmpfile)))))))


;; このスクリプトを使うと、
;; 文字列をこふ語に
;; 変換することができます。

;; (progn (eval-current-buffer) (deferred:pp (kov:translate-text-d "今日のお昼は、ステーキを食べたい。")))

(provide 'kovlive)
;;; kovlive.el ends here
