uniform lowp vec4 tint1;
uniform lowp vec4 tint2;
uniform lowp vec4 fog1;
uniform lowp vec4 fog2;
uniform lowp vec4 flash;

varying mediump float d;
varying mediump float var_dist;
varying mediump vec4 pos_world;
varying mediump vec4 pos_worldview;
varying mediump vec3 var_normal;

void main()
{
    if (gl_FrontFacing ^^ (d > 0.0))
    {
        discard;
    }
    vec3 fog_combined = vec3(fog1 - (fog1 - fog2) * tint1.w);
    vec3 rgb = vec3(tint1 - (tint1 - tint2) * tint1.w);

    float fog_distance = min(length(pos_worldview.xyz) / 48.0, 1.0);
    fog_distance = fog_distance * fog_distance * fog2.w;

    float limit = min(floor(rgb.x + rgb.y + rgb.z), 1.0);
    float reverse_flash = 1 - flash.x;
    vec3 f = vec3(reverse_flash * limit, reverse_flash, reverse_flash);
    rgb = rgb - f * 0.5;

    rgb = rgb + max(var_normal.x, 0) * max(var_normal.y, 0) * max(-var_normal.z, 0) * 3;
    
    vec3 colour = rgb * (1.0 - fog_distance) + fog_combined.xyz * fog_distance;
    colour = colour + max((-0.125 - pos_world.y) * 10, 0.0);
    
    gl_FragColor = vec4(colour.xyz, 1.0);
}