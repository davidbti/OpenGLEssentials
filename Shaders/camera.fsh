in vec2      fragTexCoord;
out vec4     fragColor;

uniform sampler2D diffuseTexture;

void main()
{
	fragColor = texture(diffuseTexture, fragTexCoord.st, 0.0);
}