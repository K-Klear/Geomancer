uniform lowp vec4 tint1;

varying mediump float d;

void main()
{
    if (gl_FrontFacing ^^ (d > 0.0))
    {
        discard;
    }
    gl_FragColor = vec4(tint1.xyz, 1.0);
}