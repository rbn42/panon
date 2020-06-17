#version 130
#define FP highp

attribute FP vec3 vertexPosition;
varying FP vec3 worldPosition;
uniform FP mat4 modelMatrix;
uniform FP mat4 mvp;

varying vec2 qt_TexCoord0;

in vec2 vertexTexCoord;

void main()
{
// Transform position, normal, and tangent to world coords
    worldPosition = vec3(modelMatrix * vec4(vertexPosition, 1.0));

// Calculate vertex position in clip coordinates
    gl_Position = mvp * vec4(worldPosition, 1.0);
    qt_TexCoord0=vertexTexCoord;
}
