varying highp vec4 var_position;
varying mediump vec3 var_normal;

uniform lowp vec4 tint;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);

    gl_FragColor = vec4(tint_pm);
}