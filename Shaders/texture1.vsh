in vec3  inPosition;
in vec2  inTexcoord;
out vec2 varTexcoord;

// Values that stay constant for the whole mesh.
uniform mat4 modelViewProjectionMatrix;

void main()
{
	// Transform the vertex by the model view projection matrix so
	// the polygon shows up in the right place
	gl_Position	= modelViewProjectionMatrix * vec4(inPosition, 1);
	
	// Pass the unmodified texture coordinate from the vertex buffer
	// directly down to the rasterizer.
    varTexcoord = inTexcoord;
}

