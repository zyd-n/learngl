(in-package #:learngl)

;;; Globals

(defvar *g* nil)
(defvar *g-should-die* nil)
(defvar *vbo-handle* nil)
(defvar *vs-source* "shaders/hello.vert")
(defvar *fs-source* "shaders/hello.frag")

;;; g(raphical programs)

(defclass g (glfw:window)
  ((glfw:title :initform "LearnGL")
   (context-version-major :initform 3)
   (opengl-profile :initform :opengl-core-profile)))

;;; Bindings

(defclass binding ()
  ((name :initarg :name :accessor binding-name)
   (prefix :initarg :prefix :accessor binding-prefix)
   (package :initarg :package :accessor binding-package)
   (initform :initarg :initform :accessor binding-initform)
   (initarg :initarg :initarg :accessor binding-initarg)
   (accessor :initarg :accessor :accessor binding-accessor)))

(defun make-accessor (name prefix package)
  (let ((symbol (alexandria:symbolicate prefix '#:- name)))
    (if package
        (intern (symbol-name symbol) (symbol-package prefix))
        symbol)))

(defun make-binding (name &key (prefix nil)
                               (package nil)
                               (initform nil)
                               (initarg (alexandria:make-keyword name))
                               (accessor (make-accessor name prefix package)))
  (make-instance 'binding :name name
                          :prefix prefix
                          :package package
                          :initform initform
                          :initarg initarg
                          :accessor accessor))

(defun parse-bindings (prefix binding-forms)
  (loop :for (name value) in binding-forms
        :collect (make-binding name prefix :initform value)))

;;; Render

(defun +defclass (name bindings)
  `(defclass ,name (g)
     (,@(loop :for binding in bindings
              :collect `(,(binding-name binding)
                         :initarg ,(binding-initarg binding)
                         :accessor ,(binding-accessor binding))))))

(defun +prepare (name bindings)
  `(defmethod prepare ((render ,name)
                       &key ,@(loop for b in bindings
                                    collect `((,(binding-initarg b) ,(binding-name b)) ,(binding-initform b)))
                       &allow-other-keys)
     (setf ,@(loop for b in bindings
                   collect `(,(binding-accessor b) render)
                   collect (binding-name b)))))

(defun +draw (name bindings body)
  `(defmethod draw ((render ,name))
     (with-accessors (,@(loop for b in bindings
                              collect `(,(binding-name b) ,(binding-accessor b))))
         render
       ,@body)))

(defmacro define-render (name binding-forms &body body)
  (let ((bindings (parse-bindings name binding-forms)))
    `(progn ,(+defclass name bindings)
            ,(+prepare name bindings)
            ,(+draw name bindings body)
            (make-instances-obsolete ',name)
            (find-class ',name))))

;;; Exit

(defun quit ()
  "Quit the program."
  (setf *g-should-die* t))

(defun shutdown ()
  "Destroy the glfw window context."
  (glfw:destroy *g*)
  (glfw:shutdown)
  (setf *g* nil)
  (setf *g-should-die* nil))

(defun clean-buffer ()
  "Clean/clear out the buffer"
  (setf *vbo-handle* nil))

;;; OpenGL Types

(defun make-gl-array (&rest args)
  "Allocate a GL array for vertices. Must be a length that is a multiple of 3 (a
vertex has three points). Converts integers to floats."
  (let ((arr (gl:alloc-gl-array :float (length args)))
        (args (mapcar (lambda (n) (/ n 1.0)) args)))
    (dotimes (i (length args) arr)
      (setf (gl:glaref arr i)
            (elt args i)))))

;;; Utility

(defun read-file (file)
  "Return the contents of FILE as a string."
  (let ((src (pathname file)))
    (with-output-to-string (output)
      (with-open-file (stream src)
        (loop :for line := (read-line stream nil)
              :while line
              :do (format output "~a~%" line))))))

;;; Conditions

(define-condition shader-link-error (error)
  ((shader-log :initarg :shader-log :initform nil :reader shader-log))
  (:report (lambda (condition stream)
             (format stream "Error linking shader program:~%~a" (shader-log condition)))))

(define-condition invalid-shader-program (error)
  ((shader-log :initarg :shader-log :initform nil :reader shader-log))
  (:report (lambda (condition stream)
             (format stream "Invalid shader program:~%~a" (shader-log condition)))))

;;; Input

(defmethod glfw:key-changed ((window g) key scan-code action modifiers)
  (when (eq key :escape)
    (quit)))

(defun process-input ()
  "Allows for input events to be sent to the window."
  (glfw:poll-events :timeout 0.03))

;;; Shaders

(defun create-vertex-buffer ()
  "Initialize the vertex buffer: contains the coordinates of the object we want
to create and allocates memory for the GPU."
  (let ((verts (make-gl-array -1.0 -1.0 +0.0
                              +0.0 +1.0 +0.0
                              +1.0 -1.0 +0.0)))
    ;; Allocate/reserve an unused handle in the namespace.
    (setf *vbo-handle* (gl:gen-buffer))
    ;; Create an object (an array buffer) and assocate or bind it to our
    ;; handle. This informs our opengl driver that we plan to populate it with
    ;; vertex attributes (positions, textures, colors etc).
    (gl:bind-buffer :array-buffer *vbo-handle*)
    ;; Finally, we actually load the position of our vertex into the vertex
    ;; buffer object. Notice the first argument: it is the target to which we
    ;; bound our handle. We don't have to specify our handle again because
    ;; OpenGL already knows which handle is currently bound to the
    ;; :array-buffer target.
    (gl:buffer-data :array-buffer :static-draw verts)))

(defun add-shader (program src type)
  (let ((shader (gl:create-shader type)))
    (assert (not (zerop shader)))
    (gl:shader-source shader src)
    (gl:compile-shader shader)
    (unwind-protect (assert (gl:get-shader shader :compile-status))
      (format t "~&[Shader Info]~%----------~%~a" (gl:get-shader-info-log shader)))
    (gl:attach-shader program shader)))

(defun check-program (program condition status)
  (if (null (gl:get-program program status))
      (error condition :shader-log (gl:get-program-info-log program))
      (gl:get-program-info-log program)))

(defun compile-shaders ()
  (let ((program (gl:create-program)))
    (assert (not (zerop program)))
    (add-shader program (read-file *vs-source*) :vertex-shader)
    (add-shader program (read-file *fs-source*) :fragment-shader)
    (gl:link-program program)
    (check-program program 'shader-link-error :link-status)
    (gl:validate-program program)
    (check-program program 'invalid-shader-program :validate-status)
    (gl:use-program program)))

;;; Init

(defun init (render-name)
  (glfw:init)
  (glfw:make-current (setf *g* (make-instance render-name)))
  (prepare *g*)
  (gl:viewport 0 0 800 600)
  ;; Set the color of the window when we clear it.
  (gl:clear-color 1.0 0.0 0.0 0.0)
  (create-vertex-buffer)
  (compile-shaders))

(defun main ()
  (unwind-protect
       (loop until *g-should-die*
             do (process-input)
                (draw *g*)
                (sleep 0.03)
                (restart-case (swank::process-requests t)
                  (continue () :report "Main Loop: Continue")))
    (shutdown)
    (clean-buffer)
    (format t "~%Killed window.")))

(defun start (render-name)
  (unless *g*
    (init render-name)
    (main)))

