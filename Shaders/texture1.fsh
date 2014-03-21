in vec2      varTexcoord;
out vec4     fragColor;

uniform sampler2D diffuseTexture;

void main()
{
	fragColor = texture(diffuseTexture, varTexcoord.st, 0.0);
}