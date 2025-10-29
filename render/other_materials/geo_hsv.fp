varying highp vec4 var_position;
varying mediump vec3 var_normal;
varying mediump vec2 var_texcoord0;

uniform lowp sampler2D tex0;
uniform lowp vec4 hsv;
uniform lowp vec4 hsv2;


vec3 hue2rgb(float hue) {
    hue = fract(hue); //only use fractional part
    float r = abs(hue * 6 - 3) - 1; //red
    float g = 2 - abs(hue * 6 - 2); //green
    float b = 2 - abs(hue * 6 - 4); //blue
    vec3 rgb = vec3(r,g,b); //combine components
    rgb = clamp(rgb, 0, 1); //clamp between 0 and 1
    return rgb;
}

vec3 hsv2rgb(vec3 _hsv)
{
    vec3 rgb = hue2rgb(_hsv.x); //apply hue
    rgb = 1 + _hsv.y * (rgb - 1); //lerp(1, rgb, _hsv.y); //apply saturation
    rgb = rgb * _hsv.z; //apply value
    return rgb;
}

void main()
{

    vec3 hsv3 = vec3(hsv.x - (hsv.x - hsv2.x) * hsv.w, hsv.y - (hsv.y - hsv2.y) * hsv.w, hsv.z - (hsv.z - hsv2.z) * hsv.w);

   
    vec3 rgb = hsv2rgb(hsv3);
    
    //vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    vec4 color = texture2D(tex0, var_texcoord0.xy) * vec4(rgb.xyz, 1.0);
    //vec4 color = texture2D(tex0, var_position.xy) * tint_pm;

    gl_FragColor = vec4(color.rgb, 1.0);
}