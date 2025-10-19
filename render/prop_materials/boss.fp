varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec4 pos_worldview;

varying mediump float d;
varying mediump float f;

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

    float fog_distance = min(length(pos_worldview.xyz) / 48.0, 1.0);
    fog_distance = fog_distance * fog_distance * fog2.w;

    vec3 colour = vec3(texture2D(tex0, var_texcoord0.xy).xyz);

    float red = (-var_normal.x - var_normal.y + var_normal.z - (1 - f * 0.95)) * (-var_normal.x - var_normal.y + var_normal.z + (1.75 - f * 0.78));
    float green = (-var_normal.x - var_normal.y + var_normal.z - (1.3 - f * 1.35)) * (-var_normal.x - var_normal.y + var_normal.z + (1.75 - f * 0.8));
    float blue = (var_normal.x + var_normal.y - var_normal.z) * (-var_normal.x - var_normal.y + var_normal.z + 1);

    red = ceil(red);
    green = ceil(green);
    blue = ceil(blue);

    red = clamp(red, 0, 1);
    green = clamp(green, 0, 1);
    blue = clamp(blue, 0, 1);

    red = (2.0 * red + rgb_combined.x) / 3;
    green = (2.0 * green + rgb_combined.y) / 3;
    blue = (2.0 * blue + rgb_combined.z) / 3;

    vec3 tint = colour.xyz * vec3(red, green, blue);
    tint = tint * (1.0 - fog_distance) + fog_distance * fog_combined.xyz;
    
    gl_FragColor = vec4(tint.xyz, 1.0);



    
}