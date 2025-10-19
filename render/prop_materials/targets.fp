varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;

varying mediump float d;
varying mediump vec4 pos;

uniform lowp sampler2D tex0;
uniform lowp vec4 tint1;
uniform lowp vec4 tint2;
uniform lowp vec4 flash;


void main()
{
    if (gl_FrontFacing ^^ (d > 0.0))
    {
        discard;
    }
    float upper = clamp((-var_normal.y + 0.1) * 5, 0.0, 1.0);
    vec3 rgb_combined = vec3(tint1 - (tint1 - tint2) * tint1.w) * upper + upper * (1 - upper);

    vec3 colour = (texture2D(tex0, var_texcoord0.xy).xyz) * rgb_combined;
    colour = colour + 0.22 * (1.0 - flash.x) * upper;

    gl_FragColor = vec4(colour, 1.0);
}