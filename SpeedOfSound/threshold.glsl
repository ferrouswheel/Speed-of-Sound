uniform sampler2D src_tex_unit0;
uniform vec2 src_tex_offset0;

void main(void)
{
	float dx = src_tex_offset0.s;
	float dy = src_tex_offset0.t;
	vec2 st = gl_TexCoord[0].st;

	vec4 color	 = texture2D(src_tex_unit0, st);
	
    if (color[0] >= 0.9) {
        color = vec4(1.0, 1.0, 1.0, 1.0);
    } else {
        color = vec4(0.0, 0.0, 0.0, 1.0);
    }
	gl_FragColor = color;
	
}