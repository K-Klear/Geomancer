varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;
varying mediump vec4 pos_worldview;

varying mediump float d;
varying mediump float f;

uniform lowp sampler2D tex0;

void main()
{
    if (gl_FrontFacing ^^ (d > 0.0))
    {
        discard;
    }

    vec3 colour = vec3(texture2D(tex0, var_texcoord0.xy).xyz);

    vec3 normal = normalize(var_normal);

    float red = (-normal.x - normal.y + normal.z) * (-normal.x - normal.y + normal.z + 1.0);
    float green = (-normal.x - normal.y + normal.z) * (-normal.x - normal.y + normal.z + 1.0);
    float blue = 1;//(normal.x + normal.y - normal.z) * (-normal.x - normal.y + normal.z + 1);

    red = ceil(red);
    green = ceil(green);
    blue = ceil(blue);

    red = clamp(red, 0, 1);
    green = clamp(green, 0, 1);
    blue = clamp(blue, 0, 1);

    red = red * colour.x;
    green = (2.0 * green + colour.y) / 3;
    blue = (2.0 * blue + colour.z) / 3;

    vec3 tint = vec3(red, green, blue);

    gl_FragColor = vec4(tint, 1.0);
}