#version 140

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

void main()
{
    out_fragColor = vec4(abs(var_texcoord0.y * 6.0 - 3.0) - 1.0, 2.0 - abs(var_texcoord0.y * 6.0 - 4.0), 2.0 - abs(var_texcoord0.y * 6.0 - 2.0), 1.0);
}
