varying highp vec4 var_position;

void main()
{
    float transparency = min(length(var_position.xyz), 10.0);
    transparency = max(0.0, (transparency - 1.0) * 0.1);
    gl_FragColor = vec4(transparency, transparency, transparency, transparency);
}