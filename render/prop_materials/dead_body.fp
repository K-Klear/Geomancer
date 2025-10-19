varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec4 pos_worldview;

varying mediump float d;

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

    vec3 fog_combined = vec3(fog1 - (fog1 - fog2) * tint1.w);

    float fog_distance = min(length(pos_worldview.xyz) / 48.0, 1.0);
    fog_distance = fog_distance * fog_distance * fog2.w;

    vec3 colour = vec3(texture2D(tex0, var_texcoord0.xy).xyz);

    vec3 normal = var_normal;

    float red = (-normal.x - normal.y + normal.z - 1) * (-normal.x - normal.y + normal.z + 1.75);
    float green = (-normal.x - normal.y + normal.z - 1.3) * (-normal.x - normal.y + normal.z + 1.75);
    float blue = (normal.x + normal.y - normal.z) * (-normal.x - normal.y + normal.z + 1);

    red = ceil(red);
    green = ceil(green);
    blue = ceil(blue);

    red = clamp(red, 0, 1);
    green = clamp(green, 0, 1);
    blue = clamp(blue, 0, 1);

    vec3 tint = vec3(0.5 * blue + 1 * red + green, 0.25 * blue + 0.75 * green, blue + green + 0.5 * red) * colour;
    tint = tint * (1.0 - fog_distance) + fog_distance * fog_combined.xyz;
    
    gl_FragColor = vec4(tint.xyz, 1.0 + tint2.w);
}