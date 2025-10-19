uniform lowp vec4 tint1;
uniform lowp vec4 tint2;


void main()
{
    vec3 rgb = vec3(tint1 - (tint1 - tint2) * tint1.w);
    
    gl_FragColor = vec4(rgb.xyz, 1.0);
}