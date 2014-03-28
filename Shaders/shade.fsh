// Interpolated values from the vertex shaders
in vec2 fraguv;
in vec3 position_worldspace;
in vec3 normal_cameraspace;
in vec3 eyedir_cameraspace;
in vec3 lightdir_cameraspace;

// Ouput data
out vec3 color;

// Values that stay constant for the whole mesh.
uniform sampler2D diffuseTexture;
uniform vec3 lightpos_worldspace;

void main(){
    
    // Light emission properties
	// You probably want to put them as uniforms
	vec3 lightColor = vec3(1,1,1);
	float lightPower = 40000.0f;
	
	// Material properties
	vec3 materialDiffuseColor = texture( diffuseTexture, fraguv ).rgb;
	vec3 materialAmbientColor = vec3(0.1,0.1,0.1) * materialDiffuseColor;
	vec3 materialSpecularColor = vec3(0.3,0.3,0.3);
    
	// Distance to the light
	float distance = length( lightpos_worldspace - position_worldspace );
    
	// Normal of the computed fragment, in camera space
	vec3 n = normalize( normal_cameraspace );
	// Direction of the light (from the fragment to the light)
	vec3 l = normalize( lightdir_cameraspace );
	// Cosine of the angle between the normal and the light direction,
	// clamped above 0
	//  - light is at the vertical of the triangle -> 1
	//  - light is perpendicular to the triangle -> 0
	//  - light is behind the triangle -> 0
	float cosTheta = clamp( dot( n,l ), 0,1 );
	
	// Eye vector (towards the camera)
	vec3 E = normalize(eyedir_cameraspace);
	// Direction in which the triangle reflects the light
	vec3 R = reflect(-l,n);
	// Cosine of the angle between the Eye vector and the Reflect vector,
	// clamped to 0
	//  - Looking into the reflection -> 1
	//  - Looking elsewhere -> < 1
	float cosAlpha = clamp( dot( E,R ), 0,1 );
    
    color =
    // Ambient : simulates indirect lighting
    materialAmbientColor +
    // Diffuse : "color" of the object
    materialDiffuseColor * lightColor * lightPower * cosTheta / (distance*distance) +
    // Specular : reflective highlight, like a mirror
    materialSpecularColor * lightColor * lightPower * pow(cosAlpha,5) / (distance*distance);
}