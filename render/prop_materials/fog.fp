varying highp vec4 var_position;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;

uniform lowp sampler2D tex0;
uniform lowp vec4 tint1;
uniform lowp vec4 tint2;

void main()
{
    vec4 rgb_combined = vec4(tint1.x - (tint1.x - tint2.x) * tint1.w, tint1.y - (tint1.y - tint2.y) * tint1.w, tint1.z - (tint1.z - tint2.z) * tint1.w, 1.0);
    gl_FragColor = texture2D(tex0, var_texcoord0.xy) * rgb_combined;
}