uniform lowp vec4 tint1;
uniform lowp vec4 tint2;
uniform lowp vec4 fog1;
uniform lowp vec4 fog2;

varying mediump float d;
varying mediump vec4 pos_worldview;

void main()
{
    if (gl_FrontFacing ^^ (d > 0.0))
    {
        discard;
    }
    vec3 fog_combined = vec3(fog1 - (fog1 - fog2) * tint1.w);
    vec3 rgb = vec3(tint1 - (tint1 - tint2) * tint1.w);

    float fog_distance = min(length(pos_worldview.xyz) / 48.0, 1.0);
    fog_distance = fog_distance * fog2.w;

    vec3 colour = rgb * (1.0 - fog_distance) + fog_distance * fog_combined.xyz;
    
    gl_FragColor = vec4(colour.xyz, 1.0);
}