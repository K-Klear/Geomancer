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
    //vec4 rgb_combined = vec4(tint1.x - (tint1.x - tint2.x) * tint1.w, tint1.y - (tint1.y - tint2.y) * tint1.w, tint1.z - (tint1.z - tint2.z) * tint1.w, 1.0);
    float transparency = 1 - max(rgb_combined.r, max(rgb_combined.g, rgb_combined.b));
    transparency = transparency * transparency;
    gl_FragColor = vec4(rgb_combined, transparency);
}