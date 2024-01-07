varying mediump vec2 var_texcoord0;
varying lowp vec4 var_color;

uniform lowp sampler2D texture_sampler;
uniform lowp vec4 invert;

void main()
{
    lowp vec4 tex = texture2D(texture_sampler, var_texcoord0.xy);
    tex.r = abs(invert.r - tex.r);
    tex.g = abs(invert.r - tex.g);
    tex.b = abs(invert.r - tex.b);
    gl_FragColor = tex * var_color;
}
