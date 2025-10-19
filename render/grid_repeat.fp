varying highp vec2 var_texcoord0;

uniform highp sampler2D tex0;
uniform lowp vec4 tint;

varying highp vec2 var_boo;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);

    // Calculate the final UV coord based on local fragment position and texture UV space.
    float u = mod(var_boo.x * 80.0, 1);
    float v = mod(var_boo.y * 80.0, 1);
    
    gl_FragColor = texture2D(tex0, vec2(u, v)) * tint_pm;
}