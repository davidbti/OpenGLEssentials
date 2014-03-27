uniform mat4 mvp;
uniform mat4 model;
uniform mat4 view;
uniform vec3 lightpos_worldspace;

in vec3 vertpos_modelspace;
in vec2 vertuv;
in vec3 vertnormal_modelspace;

out vec2 fraguv;
out vec3 position_worldspace;
out vec3 normal_cameraspace;
out vec3 eyedir_cameraspace;
out vec3 lightdir_cameraspace;

void main() {
    // Pass the texture coord straight through to the fragment shader
    fraguv = vertuv;
    
    // Apply all matrix transformations to vert
    gl_Position = mvp * vec4(vertpos_modelspace, 1);
    
    // Position of the vertex, in worldspace : M * position
	position_worldspace = (model * vec4(vertpos_modelspace,1)).xyz;
	
	// Vector that goes from the vertex to the camera, in camera space.
	// In camera space, the camera is at the origin (0,0,0).
	vec3 vertpos_cameraspace = ( view * model * vec4(vertpos_modelspace,1)).xyz;
	eyedir_cameraspace = vec3(0,0,0) - vertpos_cameraspace;
    
	// Vector that goes from the vertex to the light, in camera space. M is ommited because it's identity.
	vec3 lightpos_cameraspace = ( view * vec4(lightpos_worldspace,1)).xyz;
	lightdir_cameraspace = lightpos_cameraspace + eyedir_cameraspace;
	
	// Normal of the the vertex, in camera space
	normal_cameraspace = ( view * model * vec4(vertnormal_modelspace,0)).xyz; // Only correct if ModelMatrix does not scale the model ! Use its inverse transpose if not.
}

