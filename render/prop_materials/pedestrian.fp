varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;

varying mediump float d;
varying mediump vec4 pos;
varying mediump vec4 f;
varying mediump vec4 pos_worldview;

uniform lowp sampler2D tex0;
uniform lowp vec4 tint1;
uniform lowp vec4 tint2;
uniform lowp vec4 fog1;
uniform lowp vec4 fog2;


void main()
{
    if (gl_FrontFacing ^^ (d > 0.0))
    {
        discard;
    }

    vec3 rgb_combined = vec3(tint1 - (tint1 - tint2) * tint1.w);
    vec3 fog_combined = vec3(fog1 - (fog1 - fog2) * tint1.w);

    float darken = -(abs(var_normal.x) - var_normal.y + abs(var_normal.z)) / 6.0;
    float v = max(rgb_combined.x, max(rgb_combined.y, rgb_combined.z)) * 5.0;
    darken = darken * (5.0 - v) + v;
    darken = clamp(darken, 0, 1);

    float fog_distance = min(length(pos_worldview.xyz) / 48.0, 1.0);
    fog_distance = fog_distance * fog_distance * fog2.w;

    
    float limit = v / 5;
    vec3 colour = (texture2D(tex0, var_texcoord0.xy).xyz) * (1 - limit) * rgb_combined + rgb_combined * limit;
    colour = colour * darken + 0.02 * (1.0 - f.x);
    
    colour = colour * (1.0 - fog_distance) + fog_distance * fog_combined.xyz;

    gl_FragColor = vec4(colour.xyz, 1.0);
}