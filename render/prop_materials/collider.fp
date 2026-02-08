varying mediump vec2 var_texcoord0;

uniform lowp vec4 tint;
uniform lowp sampler2D tex0;

void main()
{
    vec3 colour = vec3(texture2D(tex0, var_texcoord0.xy).xyz);
    gl_FragColor = vec4(colour * 0.3, 0.3) * tint;
}