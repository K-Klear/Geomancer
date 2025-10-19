varying mediump vec4 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec4 pos_worldview;
varying mediump vec4 pos_world;

uniform lowp sampler2D tex0;
uniform lowp sampler2D tex1;
uniform lowp vec4 tint1;
uniform lowp vec4 tint2;
uniform lowp vec4 fog1;
uniform lowp vec4 fog2;


void main()
{
    if (gl_FrontFacing)
    {
        discard;
    }
    vec3 rgb_combined = vec3(tint1 - (tint1 - tint2) * tint1.w);
    vec3 fog_combined = vec3(fog1 - (fog1 - fog2) * tint1.w);

    float light_band = max((0.5 + pos_world.y), 0.0);
    float floor_tex = ceil(light_band) * var_normal.y;
    light_band = light_band * max((-0.125 - pos_world.y), 0.0) * 10;

    vec4 texture0 = texture2D(tex0, var_texcoord0.xy) * (1.0 - floor_tex);
    vec4 texture1 = texture2D(tex1, var_texcoord0.xy) * floor_tex;
    vec3 texture_final = vec3(texture0.xyz + texture1.xyz);
    float darken = (var_normal.x + var_normal.y + var_normal.z) / 3.0;
    float v = max(rgb_combined.x, max(rgb_combined.y, rgb_combined.z));
    darken = darken * (1.0 - v) + v;

    float fog_distance = min(length(pos_worldview.xyz) / 48.0, 1.0);
    fog_distance = fog_distance * fog_distance * fog2.w;

    vec3 colour = vec3((texture_final + 3.0 * rgb_combined) / 4.0) * darken * v * 3 + 0.03 * (1.0 - tint2.w);
    colour = (colour + light_band) * (1.0 - fog_distance) + fog_distance * fog_combined.xyz;
    
    gl_FragColor = vec4(colour.xyz, 1.0);
}