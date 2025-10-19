varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;

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

    float red = (-normal.x - normal.y + normal.z - (1 - f * 0.95)) * (-normal.x - normal.y + normal.z + (1.75 - f * 0.78));
    float green = (-normal.x - normal.y + normal.z - (1.3 - f * 1.35)) * (-normal.x - normal.y + normal.z + (1.75 - f * 0.8));
    float blue = (normal.x + normal.y - normal.z) * (-normal.x - normal.y + normal.z + 1);

    red = ceil(red);
    green = ceil(green);
    blue = ceil(blue);

    vec3 tint = vec3(red, green, blue);

    gl_FragColor = vec4(colour.xyz * tint, 1.0);
}