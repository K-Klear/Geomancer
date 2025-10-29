uniform lowp vec4 tint1;
uniform lowp vec4 tint2;

varying mediump float d;

void main()
{
    if (gl_FrontFacing ^^ (d > 0.0))
    {
        discard;
    }
    vec3 rgb_combined = vec3(tint1 - (tint1 - tint2) * tint1.w);
    float transparency = max(rgb_combined.r, max(rgb_combined.g, rgb_combined.b));
    gl_FragColor = vec4(rgb_combined * transparency * 0.75, transparency * 0.25);
}