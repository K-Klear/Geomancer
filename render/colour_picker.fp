#version 140

in mediump vec2 var_texcoord0;
in mediump vec4 var_color;

out vec4 out_fragColor;

void main()
{
    //out_fragColor = var_color;
    //float r = (1.0 - var_texcoord0.x) * var_texcoord0.y;
    //float g = (1.0 - var_texcoord0.x) * var_texcoord0.y;
    //float b = (1.0 - var_texcoord0.x) * var_texcoord0.y;
    float r = (1 - var_texcoord0.x * (1 - var_color.x)) * var_texcoord0.y;
    float g = (1 - var_texcoord0.x * (1 - var_color.y)) * var_texcoord0.y;
    float b = (1 - var_texcoord0.x * (1 - var_color.z)) * var_texcoord0.y;
    out_fragColor = vec4(r, g, b, 1.0);
}
