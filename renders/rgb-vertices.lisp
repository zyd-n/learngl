(in-package #:nohgl.rgb-vertices)

(defmethod init-options ()
  (gl:viewport 225 150 450 300)
  (gl:clear-color .09 .09 .09 0))

(defun start-rgb ()
  (start 'rgb :title "nohgl - Every vertex gets a color" :width 900 :height 600))

(defvao 'v1
  :vertex-shader
  "#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 color;

out vec3 vertexColor;
uniform float xoffset;

void main()
{
  gl_Position = vec4(position.x + xoffset, position.y, position.z, 1.0);
  vertexColor = color;
}
"
  :fragment-shader
  "#version 330 core

out vec4 FragColor;
in vec3 vertexColor;

void main()
{
  FragColor = vec4(vertexColor, 1.0);
}
"
  :verts (gfill :float
                ;;   <pos>          <color>
                ;; ---------------------------
                ;;
                ;;   top              red
                +0.0 +1.0 +0.0  +1.0 +0.0 +0.0
                ;; bottom-left        green
                -1.0 -1.0 +0.0  +0.0 +1.0 +0.0
                ;; bottom-right       blue
                +1.0 -1.0 +0.0  +0.0 +0.0 +1.0)
  :uniforms '("xoffset"))

(defmethod format-vertex-attribs ()
  (let ((size-of-float (cffi:foreign-type-size :float)))
    (gl:vertex-attrib-pointer 0 3 :float :false (* 6 size-of-float) 0)
    (gl:enable-vertex-attrib-array 0)
    (gl:vertex-attrib-pointer 1 3 :float :false (* 6 size-of-float) (* 3 size-of-float))
    (gl:enable-vertex-attrib-array 1)))

(defun draw-vertex (vao-store &optional (vertex-count 3) (offset 0))
  (gl:bind-vertex-array (vao (get-vao vao-store)))
  (gl:draw-arrays :triangles offset vertex-count))

(define-render rgb ()
  (let* ((v (get-vao 'v1))
         (uniform-location (gl:get-uniform-location (program v) "xoffset")))
    (gl:clear :color-buffer)
    (gl:use-program (program v))
    (%gl:uniform-1f uniform-location 1.0)
    (draw-vertex 'v1 3)))
