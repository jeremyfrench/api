(in-package :turtl)

(defun get-files (dir &optional (ext ".js") exclude)
  "Recursively grap all files in the given directory, with the given extension,
   excluding the patterns given."
  (unless (cl-fad:directory-exists-p dir)
    (return-from get-files nil))
  (when (and (stringp dir)
             (not (eq (aref dir (1- (length dir))) #\/)))
    (setf dir (format nil "~a/" dir)))
  (let* ((files (cl-fad:list-directory dir))
         (files (mapcar (lambda (file)
                          (if (cl-fad:directory-exists-p file)
                              (namestring file)
                              (let ((ext (pathname-type file)))
                              (concatenate 'string
                                           dir
                                           (pathname-name file)
                                           (when ext (format nil ".~a" ext))))))
                          files))
         (ext-length (length ext))
         (files (remove-if (lambda (file)
                             (and (not (string= (subseq file (- (length file) ext-length))
                                                ext))
                                  (not (cl-fad:directory-exists-p file))))
                           files))
         (files (remove-if (lambda (file)
                             (block do-remove
                               (dolist (ex exclude)
                                 (when (search ex file)
                                   (return-from do-remove t)))))
                           files))
         (final nil))
    (dolist (file files)
      (if (cl-fad:directory-exists-p file)
          (setf final (append final (get-files file ext exclude)))
          (push file final)))
    (sort final #'string<)))

(defun make-scripts (stream files)
  "Given a stream and list of files, print a <script ...></script> tag for each
   file onto the stream."
  (format stream "~%")
  (dolist (file files)
    (let* ((search-pos (search *site-assets* file))
           (search-pos (when search-pos
                         (+ (1- (length *site-assets*)) search-pos)))
           (search-pos (or search-pos 0))
           (file (subseq file search-pos)))
      (format stream "<script src=\"~a\"></script>~%" file))))

(defun make-css (stream files)
  "Given a stream and list of files, print a <link ...> css tag for each
   file on the stream."
  (format stream "~%")
  (dolist (file files)
    (let* ((search-pos (search *site-assets* file))
           (search-pos (when search-pos
                         (+ (1- (length *site-assets*)) search-pos)))
           (search-pos (or search-pos 0))
           (file (subseq file search-pos)))
      (format stream "<link rel=\"stylesheet\" href=\"~a\">~%" file))))

(defun generate-templates (stream view-dir)
  "Make a bunch of pre-cached javascript templates as <script> tags."
  (format stream "~%")
  (let ((files (get-files view-dir ".html")))
    (dolist (file files)
      (let* ((contents (file-contents file))
             (contents (cl-ppcre:regex-replace-all "</script>" contents "</%script%>"))
             (contents (cl-ppcre:regex-replace-all "<script" contents "<%script%"))
             (name (subseq file (1+ (length view-dir))))
             (name (subseq name 0 (position #\. name :from-end t))))
        (format stream "<script type=\"text/x-lb-tpl\" name=\"~a\">~%" name)
        (write-string contents stream)
        (format stream "</script>~%")))))

;; TODO: cache me!
(deflayout default (data :stream-var s :top-level t)
  (:html
    (:head
      (:meta :http-equiv "Content-Type" :content "test/html; charset=utf-8")
      (:meta :http-equiv "Content-Language" :content "en")
      (:title "Turtl")
      (:link :rel "stylesheet" :href "/css/reset.css")
      (:link :rel "stylesheet" :href "/css/template.css")
      (:link :rel "stylesheet" :href "/css/general.css")
      (make-css s (get-files *site-assets* ".css"
                             '("template.css" "reset.css" "general.css")))
      (:link :rel "shortcut icon" :href "/favicon.png" :type "image/png")
      (:script :src "/library/mootools-core-1.4.5.js")
      (:script :src "/library/mootools-more-1.4.0.1.js")
      (:script :src "/library/composer/composer.js")
      (:script :src "/library/composer/composer.relational.js")
      (:script :src "/library/composer/composer.filtercollection.js")
      (:script :src "/library/composer/composer.keyboard.js")

      (make-scripts s '("/config/config.js"
                        "/config/auth.js"
                        "/config/routes.js"))
      (make-scripts s (get-files (format nil "~alibrary" *site-assets*) ".js"
                                 '("ignore" "mootools-" "composer" "bookmarklet" "cowcrypt")))
      (:script :src "/library/cowcrypt/convert.js")
      (:script :src "/library/cowcrypt/crypto_math.js")
      (:script :src "/library/cowcrypt/biginteger.js")
      (:script :src "/library/cowcrypt/block_cipher.js")
      (:script :src "/library/cowcrypt/hasher.js")
      (:script :src "/library/cowcrypt/sha.js")
      (:script :src "/library/cowcrypt/hmac.js")
      (:script :src "/library/cowcrypt/aes.js")
      (:script :src "/library/cowcrypt/rsa.js")
      (:script :src "/library/cowcrypt/pbkdf2.js")
      (:script :src "/turtl.js")
      (make-scripts s (get-files (format nil "~aturtl" *site-assets*)))
      (make-scripts s (get-files (format nil "~ahandlers" *site-assets*)))
      (make-scripts s (get-files (format nil "~acontrollers" *site-assets*)))
      (make-scripts s (get-files (format nil "~amodels" *site-assets*)))
      
      (:script
        (format s "~%var __site_url = '~a';" *site-url*)
        (format s "~%var __api_url = '~a';" *api-url*)
        (format s "~%var __api_key = '~a';" *api-key*)))
    (:body :class "initial"
      (:div :id "loading-overlay"
        (:div
          (:span "Initializing")
          (:span :class "spin" "/")
          ;(:img :src "/images/site/icons/load_128x78.gif" :width "128" :height "78" :alt "Reticulating splines" :title "Reticulating splines")
          ))
      (:div :id "wrap-modal"
        (:div :id "wrap"
          (:div :class "sidebar-bg")
          (:header :class "clear"
            (:h1 "Turtl<span>.</span>")
            (:div :class "loading"
              (:img :src "/images/site/icons/load_42x11.gif")))
          (:div :id "main" :class "maincontent")))

      (:div :id "footer"
        (:footer
          (:div :class "gutter"
            (str (conc "Copyright &copy; "
                       (write-to-string (nth-value 5 (decode-universal-time (get-universal-time))))
                       " ")))))
      (generate-templates s (format nil "~aviews" (namestring *site-assets*))))))

