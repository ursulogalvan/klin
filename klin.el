;;; klin.el --- key bindings for klin functions in different modes  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  chris

;; Author: chris <chris@chris-tower>
;; Keywords:

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

;; Key bindings can either be (1) declared in a new map bundled within a
;; minor mode (first option: buffer-local, second option global),
;; or (2) they can be (easier option in my opinion) just set in hooks
;; when entering the specific file type or mode (e.g. org-mode) where
;; you want to have them available.  I'm going to do (2) here.

;;; Code:

(require 'klin-utils)
(require 'klin-org)
(require 'klin-bibtex)
(require 'klin-optional)
(require 'klin-tabs)
(require 'klin-pdf-frames)
(require 'klin-presentations)

;; (require 'klin-hydras)
(require 'klin-bindings)
;; (require 'klin-multiple-cursors)

(provide 'klin)
;;; klin.el ends here
