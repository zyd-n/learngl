(in-package #:cl-user)

(defpackage #:nohgl
  (:use #:cl #:org.shirakumo.fraf.math)
  (:local-nicknames (#:glfw #:org.shirakumo.fraf.glfw))
  (:export
   ;; Main
   #:*g*
   #:store
   #:start
   #:init-options
   #:define-render
   #:quit
   #:compile-shaders
   #:initialize-vao
   ;; vao
   #:defvao
   #:vao
   #:vbo
   #:ebo
   #:verts
   #:indices
   #:program
   #:vertex-shader
   #:fragment-shader
   #:get-vao
   #:format-vertex-attribs
   ;; util
   #:gfill
   #:debug-with-time))

(defpackage #:nohgl.triangle
  (:use #:cl #:org.shirakumo.fraf.math #:nohgl)
  (:local-nicknames (#:glfw #:org.shirakumo.fraf.glfw))
  (:export #:start-triangle))

(defpackage #:nohgl.rectangle
  (:use #:cl #:org.shirakumo.fraf.math #:nohgl)
  (:local-nicknames (#:glfw #:org.shirakumo.fraf.glfw))
  (:export #:start-rectangle))

(defpackage #:nohgl.two-triangles
  (:use #:cl #:org.shirakumo.fraf.math #:nohgl)
  (:local-nicknames (#:glfw #:org.shirakumo.fraf.glfw))
  (:export #:start-triangles))

(defpackage #:nohgl.hello-vaos
  (:use #:cl #:org.shirakumo.fraf.math #:nohgl)
  (:local-nicknames (#:glfw #:org.shirakumo.fraf.glfw))
  (:export #:start-vaos))

(defpackage #:nohgl.s5
  (:use #:cl #:org.shirakumo.fraf.math #:nohgl)
  (:local-nicknames (#:glfw #:org.shirakumo.fraf.glfw))
  (:export #:start-s5))
