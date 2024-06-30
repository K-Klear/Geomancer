varying highp vec4 var_position;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;

uniform lowp sampler2D tex0;
uniform lowp vec4 tint;

void main()
{
    vec4 colour = texture2D(tex0, var_texcoord0.xy) * tint;
    if (colour.w < 0.5){
        discard;
    }
    gl_FragColor = colour;
}