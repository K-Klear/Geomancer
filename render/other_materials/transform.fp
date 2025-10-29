varying mediump vec2 var_texcoord0;

uniform lowp sampler2D tex0;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 color = texture2D(tex0, var_texcoord0.xy);

    gl_FragColor = color * 0.25;
}