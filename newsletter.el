(require 'ox)
(require 'ox-ascii)
(require 'cl-lib)

(defun dw/get-newsletter-css ()
  (let ((css (with-temp-buffer
               (insert-file-contents (expand-file-name "../../assets/css/newsletter.css"))
               (buffer-string))))
    (with-temp-buffer
      (insert "<style type=\"text/css\">\n" css "</style>")
      (buffer-string))))

(defun dw/org-html-template (contents info)
  (org-html-template
   (format "<table><thead><tr><td><img alt=\"System Crafters Logo\" src=\"https://systemcrafters.net/img/sc_logo.png\" width=250 height=74></td></tr></thead><tbody><tr><td class=\"header-title\">%s</td></tr><tr><td class=\"header-date\">%s</td></tr><tr><td><div class=\"notice\">This e-mail also provides <code>text/plain</code> content if you prefer it to HTML!  Just ask your e-mail client to show the plain text version of this e-mail.</div>%s</td></tr></tbody></table>"
           (car (plist-get info :title))
           (car (plist-get info :subtitle))
           contents)
   info))

(defun dw/org-html-src-block (src-block _contents info)
  (let* ((lang (org-element-property :language src-block))
	       (code (org-html-format-code src-block info)))
    (format "<pre>%s</pre>" (string-trim code))))

(defun dw/filter-html-paragraph (paragraph contents info)
  (replace-regexp-in-string "-&gt;" "<span class=\"arrow\">↪</span>" paragraph))

(defun dw/export--html-newsletter(newsletter-file-name)
  (interactive)
  (let ((org-export-use-babel nil)
        (org-export-filter-paragraph-functions '(dw/filter-html-paragraph))
        (org-html-doctype "html5")
        (org-html-html5-fancy t)
        (org-html-head-extra (dw/get-newsletter-css))
        (org-html-validation-link nil)
        (org-export-with-toc 1)
        (org-export-with-author nil)
        (org-export-with-date nil)
        (org-export-time-stamp-file nil)
        (org-export-with-timestamps nil)
        (org-export-preserve-breaks t)
        (org-export-with-title nil)
        (org-indent-mode nil)
        (org-html-htmlize-output-type nil)
        (org-export-with-section-numbers nil)
        (org-html-prefer-user-labels t)
        (org-html-head-include-default-style nil)
        (org-html-head-include-scripts nil)
        (html-backend (org-export-create-backend :name 'newsletter-html
                                                 :parent 'html
                                                 :transcoders '((src-block . dw/org-html-src-block)
                                                                (template . dw/org-html-template)))))
    (org-export-to-file html-backend (format "%s-email.html" newsletter-file-name))))

(defun dw/org-ascii-toc (info &optional n scope keyword)
  (concat
   "== Table of Contents ==\n\n"
   (let ((index 0)
         (text-width
	        (if keyword (org-ascii--current-text-width keyword info)
	          (- (plist-get info :ascii-text-width)
	             (plist-get info :ascii-global-margin)))))
     (mapconcat
      (lambda (headline)
	      (let* ((level (org-export-get-relative-level headline info))
	             (indent (* (1- level) 3)))
	        (concat
           (format "%s. " (cl-incf index))
	         (unless (zerop indent) (concat (make-string (1- indent) ?.) " "))
	         (org-ascii--build-title
	          headline info (- text-width indent) nil
	          (or (not (plist-get info :with-tags))
		            (eq (plist-get info :with-tags) 'not-in-toc))
	          'toc))))
      (org-export-collect-headlines info n scope) "\n"))))

(defun dw/format-issue-line (issue title)
  (let ((fill-column 80))
    (with-temp-buffer
      (insert "Issue #")
      (insert issue)
      (insert " - ")
      (insert title)
      (center-line)
      (buffer-string))))

(defun dw/org-ascii-template (contents info)
  (let* ((newsletter-file-name (file-name-sans-extension
                                (file-name-nondirectory
                                 (plist-get info :input-file))))
         (issue-number (and (string-match "sc-news-\\([0-9]+\\)" newsletter-file-name)
                            (match-string 1 newsletter-file-name))))
    (concat
     (format
      (string-join
       (list
        "‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"
        "                                 Welcome to the"
        "                          System Crafters Newsletter!"
        ""
        (dw/format-issue-line issue-number (car (plist-get info :subtitle)))
        ""
        "                                by David Wilson"
        ""
        ""
        "         --  This newsletter is best viewed with a monospace font!   --"
        "         --    If your e-mail client can't do that, use this URL:    --"
        (format "         --  https://systemcrafters.net/newsletter/%s.html  --" newsletter-file-name)
        "         --            Read it in Emacs with `M-x eww`!              --")
       "\n")
      issue-number
      (car (plist-get info :subtitle)))
     "\n\n"
     (dw/org-ascii-toc info 1)
     contents
     "\n\n")))

(defun dw/org-ascii-headline (headline contents info)
  "Transcode a HEADLINE element from Org to ASCII.
CONTENTS holds the contents of the headline.  INFO is a plist
holding contextual information."
  ;; Don't export footnote section, which will be handled at the end
  ;; of the template.
  (let* ((low-level (org-export-low-level-p headline info))
         (level (org-export-get-relative-level headline info))
	       (width (org-ascii--current-text-width headline info))
	       ;; Export title early so that any link in it can be
	       ;; exported and seen in `org-ascii--unique-links'.
	       (title (car (org-element-property :title headline)))
	       (links (and (plist-get info :ascii-links-to-notes)
		                 (org-ascii--describe-links
			                (org-ascii--unique-links headline info) width info)))
	       ;; Re-build contents, inserting section links at the right
	       ;; place.  The cost is low since build results are cached.
	       (body
	        (if (not (org-string-nw-p links)) contents
	          (let* ((contents (org-element-contents headline))
		               (section (let ((first (car contents)))
				                      (and (eq (org-element-type first) 'section)
				                           first))))
		          (concat (and section
			                     (concat (org-element-normalize-string
				                            (org-export-data section info))
				                           "\n"))
                      (if (> (length links) 0)
                          (format "------\nLinks:\n\n%s" links)
                        "")
			                (mapconcat (lambda (e) (org-export-data e info))
				                         (if section (cdr contents) contents)
				                         ""))))))
    ;; Deep subtree: export it as a list item.
    (if low-level
	      (let* ((bullets (cdr (assq (plist-get info :ascii-charset)
				                           (plist-get info :ascii-bullets))))
		           (bullet
		            (format "%c "
			                  (nth (mod (1- low-level) (length bullets)) bullets))))
	        (concat bullet title "\n\n"
		              ;; Contents, indented by length of bullet.
		              (org-ascii--indent-string body (length bullet))))
	    ;; Else: Standard headline.
	    (concat "== " title " ==\n\n" body))))

(defun dw/org-ascii-link (link contents info)
  (let ((exported-link (org-ascii-link link contents info)))
    ;; If exported-link is a string wrapped in angle brackets, use a regex to strip them off
    (if (string-match "^<\\(.*\\)>$" exported-link)
        (match-string 1 exported-link)
      exported-link)))

(defun dw/filter-ascii-paragraph (paragraph contents info)
  (replace-regexp-in-string "->" "  ↪" paragraph))

(defun dw/export--txt-newsletter(newsletter-file-name)
  (let ((org-export-use-babel nil)
        (org-export-filter-paragraph-functions '(dw/filter-ascii-paragraph))
        (org-export-with-toc 1)
        (org-export-with-author nil)
        (org-export-with-date nil)
        (org-export-time-stamp-file nil)
        (org-export-with-timestamps nil)
        (org-export-preserve-breaks t)
        (org-export-with-title nil)
        (org-export-headline-levels 1)
        (org-indent-mode nil)
        (org-export-with-section-numbers nil)
        (org-ascii-global-margin 0)
        (org-ascii-text-width 80)
        (org-ascii-inner-margin 0)
        (org-ascii-paragraph-spacing 1)
        (org-ascii-headline-spacing '(1 . 1))
        (txt-backend (org-export-create-backend :name 'newsletter-txt
                                                :parent 'ascii
                                                :transcoders '((template . dw/org-ascii-template)
                                                               (link . dw/org-ascii-link)
                                                               (headline . dw/org-ascii-headline)))))

    (org-export-to-file txt-backend (format "%s.txt" newsletter-file-name))))

(defun dw/export-newsletter ()
  (interactive)
  (let ((newsletter-file-name (file-name-sans-extension
                               (file-name-nondirectory
                                (buffer-file-name)))))
    (if (not (string-match "sc-news-\\([0-9]+\\)" newsletter-file-name))
        (message "This is not a newsletter file!")
      (dw/export--html-newsletter newsletter-file-name)
      (dw/export--txt-newsletter newsletter-file-name))))
