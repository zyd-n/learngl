(defpackage #:nohgl.triangle
  (:use #:cl #:org.shirakumo.fraf.math #:nohgl)
  (:local-nicknames (#:glfw #:org.shirakumo.fraf.glfw))
  (:export #:start-render))

(in-package #:nohgl.triangle)

;; This render draws a basic triangle.

(defvao 'v1
  :vertex-shader
  (shader-s "hello.vert")
  :fragment-shader
  (shader-s "hello.frag")
  :verts
  (gfill :float
   +0.0 +1.0 +0.0
   -1.0 -1.0 +0.0
   +1.0 -1.0 +0.0))

(defmethod init-options ()
  (gl:viewport 0 0 900 600)
  (gl:clear-color .09 .09 .09 0))

(defmethod format-vertex-attribs ()
  (default-format))

(defun draw-vertex (vao-store &optional (vertex-count 3) (offset 0))
  (gl:use-program (program (get-vao vao-store)))
  (gl:bind-vertex-array (vao (get-vao vao-store)))
  (gl:draw-arrays :triangles offset vertex-count))

(define-render triangle ()
  (gl:clear :color-buffer)
  (draw-vertex 'v1 3))

(defun start-render ()
  (start 'triangle :title "nohgl - A basic triangle" :width 900 :height 600))
