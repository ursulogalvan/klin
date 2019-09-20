
;; for consecutive processing of individual bibtex files assoc. to single pdfs
(setq bib-processing-bibfiles-frames nil)

(setq bib-processing-currently-processing nil)

(defun bibtex-get-field-from-entry-under-cursor (field)
  (with-current-buffer "bibliography.bib"
    (save-excursion
      (bibtex-beginning-of-entry)
      (let* ((entry (bibtex-parse-entry t))
             (field-value (org-ref-reftex-get-bib-field field entry)))
        field-value
        )
      )
    )
  )

(defun klin-bibtex-get-field (field &optional key bibfile-path)
  "Returns the value of the key value pair (FIELD, value) of a bibtex entry.
   When called from an org-mode buffer with org-ref installed,
   it only needs the bibtex KEY if an org-ref -style bibliography link
   in the org buffer links to a collective .bib file.
   Otherwise, it needs an explicit bibfile-path.
   If it's just a single entry, the KEY is optional."

  (unless key (setq key "negele98_quant"))
  (unless bibfile-path (setq bibfile-path (cdr (org-ref-get-bibtex-key-and-file key))))
  (unless bibfile-path (setq bibfile-path (expand-file-name "~/Dropbox/2TextBooks/.1-NegeleOrland-QuantumManyParticeSystems.pdf.bib")))

  (let* (entry)
    (with-temp-buffer
      (bibtex-mode)
      (insert-file-contents bibfile-path)
      (bibtex-set-dialect (parsebib-find-bibtex-dialect) t)
      ;; refresh the parsing of the keys
      (bibtex-parse-keys)
      ;; if just one, get it's key
      (unless key
        (if (= 1 (length (bibtex-global-key-alist)))
            (setq key (car (nth 0 (bibtex-global-key-alist)))))
        )
      (unless key (setq key "negele98_quanti")) ;; debugging

      (if (not (bibtex-search-entry key nil 0)) ;; find the one you are looking for
          (progn
            (message (concat "no key " key " found in " bibfile-path)) nil)
        (setq entry (bibtex-parse-entry)) ;; sets cursor at the end of entry's last field
        (let ((field-value (org-ref-reftex-get-bib-field field entry)))
          (if (>= (length field-value) 1)
              (progn
                ;; (replace-regexp-in-string "/+" "/" field-value) ;; clean it up (?)
                field-value
                )
            (message "no field " field " found in " bibfile-path " -> " key) nil))
          ) ;; sets cursor at the beginning of the entry's line
      )
    )
  )


(defun open-bibtex-document-on-page (bibtexkey page)
  (let* ((file-page-offset (string-to-number (klin-bibtex-get-field "file-page-offset" bibtexkey)))
         (filepath (klin-bibtex-get-field "filepath" bibtexkey))
         (page (- (+ page file-page-offset) 1)))
    (open-pdf-document-new-frame filepath page)
    )
  )

(defun make-bibtex-file-for-pdf (&optional pdfpath isbn doi)
  (interactive)
  ;; (unless pdfpath (setq pdfpath (expand-file-name "~/Dropbox/2TextBooks/1-NegeleOrland-QuantumManyParticeSystems.pdf")))
  ;; (unless isbn (setq isbn "0-7382-0052-2"))
  (let* ((basedir (file-name-directory pdfpath))
         (filename (file-name-nondirectory pdfpath))
         (bibtexfilename (concat "." filename ".bib")) ;; "hidden" file
         (bibfilepath (concat basedir bibtexfilename))
         )

    ;; check if pdf actually exists
    (unless (file-exists-p pdfpath)
      (unless (yes-or-no-p "pdf file doesn't exist, continue anyway?")
        (error "pdf file doesn't exist, chose to quit")
        ))

    ;; this appends to a file (and creates one if there is none)
    (unless bibfilepath (setq bibfilepath (expand-file-name "~/Dropbox/stuff/1Book/testfile.txt")))
    (with-temp-buffer (write-region "" nil bibfilepath 'append))
    (side-by-side-bibtex-edit bibfilepath nil)
    )
  )

(defun on-bibtex-processing-frame-close-hf (frame)
  "If the current frame of the bibtex batch processing is closed, you move on
   to the next frame in the list. FRAME is the frame that is about to be deleted"
  (interactive)
  (let* ((fitting-tuple (car (rassoc frame bib-processing-bibfiles-frames))))
    ;; if that frame is inside the bib-processing-bibfiles-frames, delete the tuple from the list
    (if fitting-tuple
        (let* ((frame (cdr fitting-tuple))
               (intended-bibfile-path (car fitting-tuple)))

          ;; close the intended-bibfile-buffer
          (let ((intended-bibfile-buffer (get-buffer (file-name-nondirectory intended-bibfile-path))))
            (if intended-bibfile-buffer
                (kill-buffer intended-bibfile-buffer)
              )
            )
          ;; if the intended-bibfile is empty now (maybe after saving), delete it
          (if (string= "" (with-temp-buffer
                            (insert-file-contents intended-bibfile-path) (buffer-string)))
              (delete-file intended-bibfile-path)
            )
          )
      )
    )
    (setq bib-processing-bibfiles-frames (delq frame bib-processing-bibfiles-frames))
    ;; then, let it proceed to delete the frame
  )

(defun side-by-side-bibtex-edit (&optional intended-bibfile-path alternative-bibtex-entry-str)
  "bib file already exists somewhere, don't overwrite it, complete it with another
   alternative bibtex entry delivered to the function.
   removes the existing-bibfile if it remains empty
   "
  (interactive)
  ;; (unless intended-bibfile-path (setq intended-bibfile-path (expand-file-name "~/Dropbox/2TextBooks/.1-NegeleOrland-QuantumManyParticeSystems.pdf.bib")))

  ;; open the existing bibfile
  (let* ((tmpfilepath (make-temp-file "alternative-bibtex-entry")))
    (find-file-other-frame intended-bibfile-path)

    ;; split it in two to get side-by-side view with another buffer
    (progn
      (if (<= (length (window-list)) 1)
          (split-window-vertically))
      (other-window 1))

    (if alternative-bibtex-entry-str
        ;; if some text was given, open a temp file and insert it
        (progn
          (find-file tmpfilepath)
          (insert alternative-bibtex-entry-str))
      ;; else: ask for the isbn and populate the suggestion field with a bibtex entry
      ;; based on that it
      (let* ((isbn (read-string "ISBN? (return to continue):")))
        (isbn-to-bibtex isbn tmpfilepath) ;; goes to the internet
        )
      ;; if a suggestion could be found by isbn, and the intended buffer is empty,
      ;; ask to insert it there
      (let* ((suggested-bibtex-entry-str (buffer-string))
             )
        (if (and (/= 0 (length suggested-bibtex-entry-str))
                 (= 0 (length
                       (with-current-buffer
                           (get-buffer (file-name-nondirectory intended-bibfile-path))
                         (buffer-string)))))
            (progn
              (if (yes-or-no-p
                   (concat intended-bibfile-path
                           "'s shown buffer is empty. Fill it with the standard suggestion?"))
                  (progn
                    (switch-to-buffer-other-window
                     (get-buffer (file-name-nondirectory intended-bibfile-path)))
                    (insert suggested-bibtex-entry-str)
                    ;; (other-window -1)
                    )
                )
              )
          )
        )
      )

      ;; for consecutive processing of individual bibtex files assoc. to single pdfs
      (setq bib-processing-bibfiles-frames
            (append bib-processing-bibfiles-frames `(,intended-bibfile-path ,(selected-frame))))
      (setq bib-processing-currently-processing t)

      ;; add a function to delete-frame-functions that will handle the transition:
      ;; when kill-frame-and-buffers-within is called at some point, that will call (delete-frame)
      ;; then, the function added below will run and check if there are some bibfiles
      ;; left in the queue to be processed. If yes, it will start side-by-side-bibtex-edit
      ;; for the next intended-bibfile-path
      (add-to-list 'delete-frame-functions 'on-bibtex-processing-frame-close-hf)
    )
  )

(defun diagnose-bib-entry-file-page-offset (&optional bibtexkey page)
  (interactive)
  "run in the context of a bib-buffer
   TODO check if there's a file-page-offset field in the bib entry you're hovering over.
   If not, or if it doesn't contain a value, ask to diagonose the pdf manually
   by opening it and asking for the value.
   There's probably also a way to do it automatically and semi-reliably... "
  ;; (unless bibfile-path (setq bibfile-path (expand-file-name "~/Dropbox/2TextBooks/.1-NegeleOrland-QuantumManyParticeSystems.pdf.bib")))
  ;; (unless pdf-path (setq pdf-path (expand-file-name "~/Dropbox/2TextBooks/1-NegeleOrland-QuantumManyParticeSystems.pdf")))
  (let* ((key (bibtex-get-field-from-entry-under-cursor "=key="))
         (file-page-offset-str (bibtex-get-field-from-entry-under-cursor "file-page-offset"))
         ;; returns "" if file-page-offset field is not there or has no value
         (file-page-offset (if (string= "" file-page-offset-str)
                               nil
                             (string-to-number file-page-offset-str)))
         )
    (if file-page-offset
        (progn
          (if (yes-or-no-p
               (concat "file-page-offset is set to " file-page-offset-str))
              (save-excursion
                (progn
                  ;; open up the pdf in a new frame on page 1 (first pdf page)
                  (let* ((filepath (bibtex-get-field-from-entry-under-cursor "filepath"))
                         red-string
                         number
                         (old-buffer (current-buffer)))
                    (if filepath
                        (progn
                          (open-pdf-document-new-frame filepath file-page-offset)
                          (setq number (call-interactively 'klin-ask-pdf-offset-number))
                          (delete-frame (selected-frame))
                          (switch-to-buffer-other-frame old-buffer)
                          (bibtex-set-field "file-page-offset" (number-to-string number))
                          )
                      (message "no filepath declared for " key)
                      )
                    )
                  )
                  )
                )
              )
      ;; else, ask to open the pdf to see
      (if (yes-or-no-p
           (concat "There's no file-page-offset field in " key
                   ". How 'bout opening up the PDF to manually find the offset?"))
          (save-excursion
            (progn
              ;; open up the pdf in a new frame on page 1 (first pdf page)
              (let* ((filepath (bibtex-get-field-from-entry-under-cursor "filepath"))
                     red-string
                     (old-buffer (current-buffer)))
                (if filepath
                    (progn
                      (open-pdf-document-new-frame filepath 1)
                      (setq number (call-interactively 'klin-ask-pdf-offset-number))
                      (delete-frame (selected-frame))
                      (switch-to-buffer-other-frame old-buffer)
                      (bibtex-set-field "file-page-offset" (number-to-string number))
                      )
                  (message "no filepath declared for " key)
                  )
                )
              )
              )
            )
      )
    )
  )


(defun bibtex-next-entry (&optional n)
  "Jump to the beginning of the next bibtex entry. N is a prefix
argument. If it is numeric, jump that many entries
forward. Negative numbers do nothing."
  (interactive "P")
  ;; Note if we start at the beginning of an entry, nothing
  ;; happens. We need to move forward a char, and call again.
  (when (= (point) (save-excursion
                     (bibtex-beginning-of-entry)))
    (forward-char)
    (bibtex-next-entry))

  ;; search forward for an entry
  (when
      (re-search-forward bibtex-entry-head nil t (and (numberp n) n))
    ;; go to beginning of the entry
    (bibtex-beginning-of-entry)))


(defun bibtex-previous-entry (&optional n)
  "Jump to beginning of the previous bibtex entry. N is a prefix
argument. If it is numeric, jump that many entries back."
  (interactive "P")
  (bibtex-beginning-of-entry)
 (when
     (re-search-backward bibtex-entry-head nil t (and (numberp n) n))
   (bibtex-beginning-of-entry)))

(defun jmax-bibtex-get-fields ()
  "Get a list of fields in a bibtex entry."
  (bibtex-beginning-of-entry)
  (remove "=type="
          (remove "=key="
                  (mapcar 'car (bibtex-parse-entry)))))

(defun jmax-bibtex-jump-to-field (field)
  "Jump to FIELD in the current bibtex entry"
  (interactive
   (list
    (ido-completing-read "Field: " (jmax-bibtex-get-fields))))
  (save-restriction
    (bibtex-narrow-to-entry)
    (bibtex-beginning-of-entry)
    (when
        ;; fields start with spaces, a field name, possibly more
        ;; spaces, then =
        (re-search-forward (format "^\\s-*%s\\s-*=" field) nil t))))

(defun check-pdfs-for-bib-file (&optional filepaths check-all)
  "runs side-by-side-view on files consecutively
  if CHECK-ALL is not nil, diagnose every bibtex file"
  (interactive)
  "you can mark some files in dired an run it on them"
  (unless filepaths (setq filepaths (dired-get-marked-files)))
  (unless check-all (setq check-all nil))

  (if (> (length bib-processing-bibfiles-frames) 0)
      (progn
        (if (yes-or-no-p ("some bib files are still waiting to be processed. Skip them?"))
            (progn
              (setq bib-processing-bibfiles-frames nil)
              )
          )
        )
    )
  ;; setup the global bib-processing-bibfiles-frames list with the filepaths

  ;; start with the first one, that initiates it; after closing that one,
  ;; there is a hook to open the 2nd one and so on.
  (let* ((pdf-filepath (nth 0 filepaths))
         ;; (pdf-filename (file-name-nondirectory pdf-filepath))
         ;; (bibtex-filename (concat "." pdf-filename ".bib"))
         ;; (bibtex-filepath (concat (file-name-directory pdf-filepath) bibtex-filename))
         )
    (make-bibtex-file-for-pdf pdf-filepath)
    )
  )