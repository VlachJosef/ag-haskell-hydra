;;; ag-haskell-hydra.el --- Hydra for quick searching of data, type, class, function etc. declarations in Haskell codebase

;; Copyright (c) 2018 Josef Vlach

;; Homepage: https://github.com/VlachJosef/ag-haskell-hydra
;; Package-Version:  0.1

;;; Commentary:
;;
;;; Code:

(require 'ag)
(require 'hydra)
(require 'projectile)

(defvar ahh:ag-mode nil)
(defvar ahh:last-search nil)
(defvar ahh:ag-prompt-regexp "\\[.*] Ag \\(regexp \\)?search for\\( (default \\(.+\\))\\)?:"
  "Matches regexp of this form:
[crypto] Ag regexp search for (default listenForClientConnection):
[crypto] Ag search for (default listenForClientConnection):
[crypto] Ag regexp search for:")

(defconst ahh:regexp-boundaries "^\\(\\\\b\\)\\(.*\\)\\(\\1\\)")
(defconst ahh:regexp-suffix "\\(\\.\\*=\\)$")
(defconst ahh:keywords '("data"  "newtype"  "class"  "type"))
(defconst ahh:word-boundary "\\b")
(defconst ahh:function ".*=")

(defun ahh:clear-minibuffer ()
  (delete-region (move-beginning-of-line 1) (point-max)))

(defun ahh:inspect (command &optional word)
  (let* ((contents (minibuffer-contents-no-properties))
         (word-boundary-prefix (when (string-match ahh:regexp-boundaries contents) ahh:word-boundary))
         (word-boundary-prefix-s (if word-boundary-prefix word-boundary-prefix ""))
         (function-postfix (when (string-match ahh:regexp-suffix contents) ahh:function))
         (function-postfix-s (if function-postfix function-postfix ""))
         (looking-for (replace-regexp-in-string ahh:regexp-suffix "" (replace-regexp-in-string "\\(\\\\b\\)" "" contents)))
         (expected (format "%s%s%s%s" word-boundary-prefix-s looking-for word-boundary-prefix-s function-postfix-s))
         (set-prompt (lambda (key-word look-for)
                       (insert (format "%s%s%s%s%s" word-boundary-prefix-s (if key-word (format "%s " key-word) "") look-for word-boundary-prefix-s function-postfix-s)))))
    (when (equal expected contents)
      (ahh:clear-minibuffer)
      (pcase command
        ('ahh:toggle-function (insert (format "%s%s%s" word-boundary-prefix-s looking-for word-boundary-prefix-s))
                              (unless function-postfix (insert ahh:function)))
        ('ahh:toggle-words-only (if word-boundary-prefix
                                    (insert (format "%s%s" looking-for function-postfix-s))
                                  (insert (format "%s%s%s%s" ahh:word-boundary looking-for ahh:word-boundary function-postfix-s))))
        ('ahh:toggle-word
         (let* ((look-att (when (string-match "\\([a-z]*\\) " looking-for)
                            (match-string-no-properties 1 looking-for)))
                (looking-for-core (if (string= "" looking-for) ""
                                    (substring looking-for (+ 1 (length look-att))))))
           (if (member look-att ahh:keywords)
               (if (equal look-att word)
                   (funcall set-prompt nil looking-for-core)
                 (funcall set-prompt word looking-for-core))
             (funcall set-prompt word looking-for))))
        (_ nil)))))

(defmacro ahh:with-current-search-and-default (&rest body)
  `(ahh:with-current-search
    (when (string= "" (minibuffer-contents-no-properties))
      (insert looking-for))
    ,@body))

(defmacro ahh:with-current-search (&rest body)
  `(let* ((prompt (minibuffer-prompt))
          (looking-for (when (string-match ahh:ag-prompt-regexp prompt)
                         (let ((maybe-match (match-string-no-properties 3 prompt)))
                           (if maybe-match maybe-match "")))))
     ,@body))

(defun ahh:haskell-insert-current ()
  (ahh:with-current-search
   (ahh:clear-minibuffer)
   (insert looking-for)))

(defun ahh:haskell-insert-or-replace-word (word)
  (ahh:with-current-search-and-default
   (ahh:inspect 'ahh:toggle-word word)))

(defun ahh:haskell-switch (&optional content)
  (pcase ahh:ag-mode
    ('ahh-regexp (setq ahh:ag-mode 'ahh-normal))
    ('ahh-normal (setq ahh:ag-mode 'ahh-regexp))
    (_ nil))
  (setq ahh:last-search (if content content
                          (minibuffer-contents-no-properties)))
  (let ((enable-recursive-minibuffers t))
    (select-window (minibuffer-selected-window))
    (condition-case nil
        (call-interactively 'ahh:projectile-ag-regexp)
      (quit (message "[AG] Quit from recursive edit")))
    (abort-recursive-edit)))

(defun ahh:whole-words-only ()
  (ahh:with-current-search-and-default
   (ahh:inspect 'ahh:toggle-words-only)
   (when (equal ahh:ag-mode 'ahh-normal)
     (ahh:haskell-switch (minibuffer-contents-no-properties)))))

(defun ahh:haskell-insert-function ()
  (ahh:with-current-search-and-default
   (ahh:inspect 'ahh:toggle-function)))

(defun ahh:projectile-ag-regexp ()
  "
\(use-package haskell-mode
  :config
  :bind ((\"s-F\" . ahh:projectile-ag-regexp))
\)"
  (interactive)
  (xref-push-marker-stack)
  (unless ahh:ag-mode (setq ahh:ag-mode 'ahh-regexp))
  (let ((prefix-arg (pcase ahh:ag-mode
                      ('ahh-regexp 4)
                      ('ahh-normal nil)
                      (_ nil))))
    (let ((current-prefix-arg prefix-arg))
      (call-interactively 'projectile-ag))))

(defhydra ahh:haskell-minibuffer-search ()
  "
Search for _d_ data _n_ newtype _f_ function _c_ class _t_ type _s_ switch _p_ current _w_ words _q_ quit"
  ("d" (ahh:haskell-insert-or-replace-word "data") nil)
  ("n" (ahh:haskell-insert-or-replace-word "newtype") nil)
  ("f" (ahh:haskell-insert-function) nil)
  ("c" (ahh:haskell-insert-or-replace-word "class") nil)
  ("t" (ahh:haskell-insert-or-replace-word "type") nil)
  ("w" (ahh:whole-words-only) nil)
  ("p" (ahh:haskell-insert-current) nil)
  ("s" (ahh:haskell-switch) nil)
  ("q" nil nil :color blue))

(defmacro ahh:in-haskell-mode-minibuffer (&rest body)
  `(when (and
          (with-current-buffer (window-buffer (minibuffer-selected-window))
            (or
             (derived-mode-p 'haskell-mode)
             (derived-mode-p 'simple-ghci-mode)))
          (string-match ahh:ag-prompt-regexp (minibuffer-prompt)))
     ,@body))

(defun ahh:haskell-mini-hook ()
  (ahh:in-haskell-mode-minibuffer
   (when ahh:last-search
     (insert ahh:last-search))
   (ahh:haskell-minibuffer-search/body)))

(defun ahh:haskell-mini-reset ()
  (ahh:in-haskell-mode-minibuffer
   (setq ahh:last-search nil)))

(add-hook 'minibuffer-setup-hook 'ahh:haskell-mini-hook)
(add-hook 'minibuffer-exit-hook 'ahh:haskell-mini-reset)

(defun ahh:go-to-source ()
  "Go to source when only one match found, if no match found repeat search otherwise do nothing."
  (pop-to-buffer next-error-last-buffer)
  (re-search-forward "^\\(0\\|1\\) matches$" nil t 1)
  (let ((match (match-string 1)))
    (pcase match
      ("0" (let* ((ag-buffer (current-buffer))
                  (ag-window (get-buffer-window ag-buffer)))
             (kill-buffer ag-buffer)
             (delete-window ag-window))
       (call-interactively 'ahh:projectile-ag-regexp))
      ("1" (let* ((ag-buffer (current-buffer))
                  (ag-window (get-buffer-window ag-buffer)))
             (next-error)
             (kill-buffer ag-buffer)
             (delete-window ag-window)))
      (_ nil))))

(provide 'ag-haskell-hydra)
;;; ag-haskell-hydra.el ends here
