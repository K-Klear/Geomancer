uniform lowp vec4 tint1;
uniform lowp vec4 tint2;

varying mediump float d;
varying mediump vec4 var_normal;

void main()
{
    if (gl_FrontFacing ^^ (d > 0.0))
    {
        discard;
    }
    
    vec3 rgb_combined = vec3(tint1 - (tint1 - tint2) * tint1.w);
    
    vec3 n = normalize(var_normal.xyz);
    float tint = abs(n.x) * abs(n.y);

    gl_FragColor = vec4(rgb_combined * tint, 1.0 + tint);
}