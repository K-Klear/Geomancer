varying mediump float d;
varying mediump vec4 var_normal;

void main()
{
    if (gl_FrontFacing ^^ (d > 0.0))
    {
        discard;
    }

    vec3 n = normalize(var_normal.xyz);
    float tint = abs(n.x) * abs(n.y) * 0.75;

    gl_FragColor = vec4(tint, tint, tint, 1.0 + tint);
}