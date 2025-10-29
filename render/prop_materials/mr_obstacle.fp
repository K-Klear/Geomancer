varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;

varying mediump vec4 pos;
varying mediump vec4 f;
varying mediump vec4 pos_worldview;

uniform lowp sampler2D tex0;
uniform lowp vec4 tint1;
uniform lowp vec4 tint2;
uniform lowp vec4 fog1;
uniform lowp vec4 fog2;
uniform lowp vec4 glow1;
uniform lowp vec4 glow2;

void main()
{
    vec3 rgb_combined = vec3(tint1 - (tint1 - tint2) * tint1.w);
    vec3 fog_combined = vec3(fog1 - (fog1 - fog2) * tint1.w);
    vec3 glow_combined = vec3(glow1 - (glow1 - glow2) * tint1.w);

    float glow_dir = max(var_normal.x + var_normal.y + var_normal.z * 0.45 - 0.8, 0) * 3;
    rgb_combined = (rgb_combined + glow_combined * glow_dir) / (1.0 + glow_dir);

    float darken = -(abs(var_normal.x) - var_normal.y + abs(var_normal.z)) / 6.0;
    float v = max(rgb_combined.x, max(rgb_combined.y, rgb_combined.z)) * 4.0;
    darken = darken * (4.0 - v) + v;

    float dist = max(12.0 - length(pos.xyz - vec3(0, 0, f.z)), 0.0);

    float fog_distance = min(length(pos_worldview.xyz) / 48.0, 1.0);
    fog_distance = fog_distance * fog_distance * fog2.w;

    vec3 colour = vec3((texture2D(tex0, var_texcoord0.xy).xyz + 3.0 * rgb_combined) / 4.0) * darken + 0.02 * (1.0 - f.x);
    colour = colour * (1.0 - fog_distance) + fog_distance * fog_combined.xyz + dist * f.w;

    gl_FragColor = vec4(colour.xyz, 1.0);
}