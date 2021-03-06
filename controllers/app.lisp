(in-package :turtl)

(defun user-id (request)
  "Grab a user id from a request."
  (gethash "id" (request-data request)))

;; this is responsible for checking user auth
;; TODO: if this ever does MORE than just check auth, be sure to split into
;;       multiple functions
(add-hook :pre-route
  (lambda (req res)
    (let ((future (make-future)))
      (let* ((auth (getf (request-headers req) :authorization))
             (path (puri:uri-path (request-uri req)))
             (method (request-method req))
             (auth-fail-fn (lambda ()
                             (let ((err (make-instance 'auth-failed :msg "Authentication failed.")))
                               ;; TODO: implement random delay between 1-250 ms
                               ;; here to help prevent timing attacks
                               (send-response res
                                              :status (error-code err)
                                              :headers '(:content-type "application/json")
                                              :body (error-json err))
                               (signal-error future err)))))
        (if (or (< (length path) 5)
                (not (string= (subseq path 0 5) "/api/"))
                (is-public-action method path))
            ;; this is a signup or file serve. let it fly with no auth
            (finish future)
            ;; not a signup, test the auth...
            (if auth
                (let* ((auth (subseq auth 6))
                       (auth (cl-base64:base64-string-to-string auth))
                       (split-pos (position #\: auth))
                       (auth-key (if split-pos
                                     (subseq auth (1+ split-pos))
                                     nil)))
                  (catch-errors (res)
                    (alet* ((user (check-auth auth-key)))
                      (if user
                          (progn 
                            (setf (request-data req) user)
                            (finish future))
                          (funcall auth-fail-fn)))))
                (funcall auth-fail-fn))))
      future))
  :turtl-auth)

