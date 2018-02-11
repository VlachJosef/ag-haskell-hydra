;;-*- Mode: Emacs-Lisp -*-
;;; Cask --- project definition

;; Copyright (C) 2018 Vlach Josef

;; Author: Josef Vlach <Vlach.Josef@gmail.com>

;;; Commentary:
;;
;;  Cask is a package manager for emacs lisp projects, this generates
;;  the *-pkg.el.
;;
;;  See http://cask.readthedocs.org/en/latest/guide/dsl.html for more
;;  information about Cask.
;;
;;    cask pkg-file
;;
;;    cask update
;;    cask install
;;
;;  are particularly useful commands.
;;
;; To run the tests:
;;    cask exec ert-runner
;;
;; Or directly from emacs with `overseer' minor mode:
;;    C-c , a overseer-test
;;; Code:

(source melpa)

(package-file "ag-haskell-hydra.el")

(depends-on "ag")
(depends-on "hydra")
(depends-on "projectile")

(development
 (depends-on "ert-runner")
 ;;(depends-on "ecukes")
 ;;(depends-on "espuds")
 (depends-on "undercover")
 )

;;; Cask ends here
