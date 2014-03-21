//
//  OpenCubeRenderer.m
//  OSXGLEssentials
//
//  Created by Matthew Doig on 3/19/14.
//
//

#import "OpenMatrixRenderer.h"


#import "glm/glm.hpp"
#import "glm/gtc/matrix_transform.hpp"
#import <iostream>
#import <fstream>
#import <string>
#import <vector>

#define GetGLError()									\
{														\
	GLenum err = glGetError();							\
	while (err != GL_NO_ERROR) {						\
		NSLog(@"GLError %s set in File:%s Line:%d\n",	\
				GetGLErrorString(err),					\
				__FILE__,								\
				__LINE__);								\
		err = glGetError();								\
	}													\
}

// Toggle this to disable vertex buffer objects
// (i.e. use client-side vertex array objects)
// This must be 1 if using the GL3 Core Profile on the Mac
#define USE_VERTEX_BUFFER_OBJECTS 1

// Indicies to which we will set vertex array attibutes
// See buildVAO and buildProgram
enum {
	POS_ATTRIB_IDX,
	NORMAL_ATTRIB_IDX,
	TEXCOORD_ATTRIB_IDX
};

#ifndef NULL
#define NULL 0
#endif

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@implementation OpenMatrixRenderer

static const GLfloat matrixPositions[] = {
    -1.0f, -1.0f, 0.0f,
    1.0f, -1.0f, 0.0f,
    0.0f,  1.0f, 0.0f,
};
unsigned int matrixElements[] = {
    0, 1, 2,
};

GLuint m_characterPrgName;
GLint m_characterMvpUniformIdx;
GLuint m_characterVAOName;
GLfloat m_characterAngle;

GLuint m_viewWidth;
GLuint m_viewHeight;

GLboolean m_useVBOs;


- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height
{
	glViewport(0, 0, width, height);
    
	m_viewWidth = width;
	m_viewHeight = height;
}

- (void) render
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Use the program for rendering our character
	glUseProgram(m_characterPrgName);
    
    // Projection matrix : 45° Field of View, 4:3 ratio, display range : 0.1 unit <-> 100 units
    glm::mat4 Projection = glm::perspective(45.0f, 4.0f / 3.0f, 0.1f, 100.0f);
    // Camera matrix
    glm::mat4 View       = glm::lookAt(
                                       glm::vec3(4,3,3), // Camera is at (4,3,3), in World Space
                                       glm::vec3(0,0,0), // and looks at the origin
                                       glm::vec3(0,1,0)  // Head is up (set to 0,-1,0 to look upside-down)
                                       );
    // Model matrix : an identity matrix (model will be at the origin)
    glm::mat4 Model      = glm::mat4(1.0f);  // Changes for each model !
    // Our ModelViewProjection : multiplication of our 3 matrices
    glm::mat4 MVP        = Projection * View * Model; // Remember, matrix multiplication is the other way around
    
    // Send our transformation to the currently bound shader,
    // in the "MVP" uniform
    // For each model you render, since the MVP will be different (at least the M part)
    glUniformMatrix4fv(m_characterMvpUniformIdx, 1, GL_FALSE, &MVP[0][0]);
	
	// Bind our vertex array object
	glBindVertexArray(m_characterVAOName);
    
    glDrawElements(GL_TRIANGLES, sizeof(matrixElements), GL_UNSIGNED_INT, 0);
    
    m_characterAngle++;
}

static GLsizei GetGLTypeSize(GLenum type)
{
	switch (type) {
		case GL_BYTE:
			return sizeof(GLbyte);
		case GL_UNSIGNED_BYTE:
			return sizeof(GLubyte);
		case GL_SHORT:
			return sizeof(GLshort);
		case GL_UNSIGNED_SHORT:
			return sizeof(GLushort);
		case GL_INT:
			return sizeof(GLint);
		case GL_UNSIGNED_INT:
			return sizeof(GLuint);
		case GL_FLOAT:
			return sizeof(GLfloat);
	}
	return 0;
}

- (GLuint) buildVAO
{
	GLuint vaoName;
	
	// Create a vertex array object (VAO) to cache model parameters
	glGenVertexArrays(1, &vaoName);
	glBindVertexArray(vaoName);
    
    GLuint posBufferName;
    
    // Create a vertex buffer object (VBO) to store positions
    glGenBuffers(1, &posBufferName);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
    
    // Allocate and load position data into the VBO
    glBufferData(GL_ARRAY_BUFFER, sizeof(matrixPositions), matrixPositions, GL_STATIC_DRAW);
    
    // Enable the position attribute for this VAO
    glEnableVertexAttribArray(POS_ATTRIB_IDX);
    
    // Get the size of the position type so we can set the stride properly
    //GLsizei posTypeSize = GetGLTypeSize(GL_FLOAT);
    
    // Set up parmeters for position attribute in the VAO including,
    //  size, type, stride, and offset in the currenly bound VAO
    // This also attaches the position VBO to the VAO
    glVertexAttribPointer(POS_ATTRIB_IDX,		// What attibute index will this array feed in the vertex shader (see buildProgram)
                          3,	// How many elements are there per position?
                          GL_FLOAT,	// What is the type of this data?
                          GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-pont types)
                          0, // What is the stride (i.e. bytes between positions)?
                          BUFFER_OFFSET(0));	// What is the offset in the VBO to the position data?
    
    
    GLuint elementBufferName;
    
    // Create a VBO to vertex array elements
    // This also attaches the element array buffer to the VAO
    glGenBuffers(1, &elementBufferName);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
    
    // Allocate and load vertex array element data into VBO
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(matrixElements), matrixElements, GL_STATIC_DRAW);
    
	GetGLError();
	
	return vaoName;
}

-(void)destroyVAO:(GLuint) vaoName
{
     GLuint index;
     GLuint bufName;
     
     // Bind the VAO so we can get data from it
     glBindVertexArray(vaoName);
     
     // For every possible attribute set in the VAO
     for(index = 0; index < 16; index++)
     {
         // Get the VBO set for that attibute
         glGetVertexAttribiv(index , GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
     
         // If there was a VBO set...
         if(bufName)
         {
             //...delete the VBO
             glDeleteBuffers(1, &bufName);
         }
     }
     
     // Get any element array VBO set in the VAO
     glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
     
     // If there was a element array VBO set in the VAO
     if(bufName)
     {
         //...delete the VBO
         glDeleteBuffers(1, &bufName);
     }
     
     // Finally, delete the VAO
     glDeleteVertexArrays(1, &vaoName);
     
     GetGLError();
}

-(GLuint) loadShadersWithVertexPath:(NSString *)vtxPath
                withFragmentPath:(NSString *)frgPath
{
    const char * vertex_file_path = [vtxPath cStringUsingEncoding:NSASCIIStringEncoding];
    const char * fragment_file_path = [frgPath cStringUsingEncoding:NSASCIIStringEncoding];
    
    // Create the shaders
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    
    // Read the Vertex Shader code from the file
    std::string VertexShaderCode;
    std::ifstream VertexShaderStream(vertex_file_path, std::ios::in);
    if(VertexShaderStream.is_open())
    {
        std::string Line = "";
        while(getline(VertexShaderStream, Line))
            VertexShaderCode += "\n" + Line;
        VertexShaderStream.close();
    }
    
    // Read the Fragment Shader code from the file
    std::string FragmentShaderCode;
    std::ifstream FragmentShaderStream(fragment_file_path, std::ios::in);
    if(FragmentShaderStream.is_open()){
        std::string Line = "";
        while(getline(FragmentShaderStream, Line))
            FragmentShaderCode += "\n" + Line;
        FragmentShaderStream.close();
    }
    
    GLint Result = GL_FALSE;
    int InfoLogLength;
    
    // Compile Vertex Shader
    printf("Compiling shader : %s\n", vertex_file_path);
    char const * VertexSourcePointer = VertexShaderCode.c_str();
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
    glCompileShader(VertexShaderID);
    
    // Check Vertex Shader
    glGetShaderiv(VertexShaderID, GL_COMPILE_STATUS, &Result);
    glGetShaderiv(VertexShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
    std::vector<char> VertexShaderErrorMessage(InfoLogLength);
    glGetShaderInfoLog(VertexShaderID, InfoLogLength, NULL, &VertexShaderErrorMessage[0]);
    fprintf(stdout, "%s\n", &VertexShaderErrorMessage[0]);
    
    // Compile Fragment Shader
    printf("Compiling shader : %s\n", fragment_file_path);
    char const * FragmentSourcePointer = FragmentShaderCode.c_str();
    glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , NULL);
    glCompileShader(FragmentShaderID);
    
    // Check Fragment Shader
    glGetShaderiv(FragmentShaderID, GL_COMPILE_STATUS, &Result);
    glGetShaderiv(FragmentShaderID, GL_INFO_LOG_LENGTH, &InfoLogLength);
    std::vector<char> FragmentShaderErrorMessage(InfoLogLength);
    glGetShaderInfoLog(FragmentShaderID, InfoLogLength, NULL, &FragmentShaderErrorMessage[0]);
    fprintf(stdout, "%s\n", &FragmentShaderErrorMessage[0]);
    
    // Link the program
    fprintf(stdout, "Linking program\n");
    GLuint ProgramID = glCreateProgram();
    glAttachShader(ProgramID, VertexShaderID);
    glAttachShader(ProgramID, FragmentShaderID);
    glLinkProgram(ProgramID);
    
    // Check the program
    glGetProgramiv(ProgramID, GL_LINK_STATUS, &Result);
    glGetProgramiv(ProgramID, GL_INFO_LOG_LENGTH, &InfoLogLength);
    std::vector<char> ProgramErrorMessage( std::max(InfoLogLength, int(1)) );
    glGetProgramInfoLog(ProgramID, InfoLogLength, NULL, &ProgramErrorMessage[0]);
    fprintf(stdout, "%s\n", &ProgramErrorMessage[0]);
    
    glDeleteShader(VertexShaderID);
    glDeleteShader(FragmentShaderID);
    
    return ProgramID;
}

- (id) initWithDefaultFBO: (GLuint) defaultFBOName
{
	if((self = [super init]))
	{
		NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
        
        ////////////////////////////////////////////////////
		// Build all of our and setup initial state here  //
		// Don't wait until our real time run loop begins //
		////////////////////////////////////////////////////
		
		m_defaultFBOName = defaultFBOName;
		
		m_viewWidth = 100;
		m_viewHeight = 100;
        
        m_characterAngle = 0;
		
		m_useVBOs = USE_VERTEX_BUFFER_OBJECTS;
        
        // Build Vertex Buffer Objects (VBOs) and Vertex Array Object (VAOs) with our model data
		m_characterVAOName = [self buildVAO];
        
        ////////////////////////////////////////////////////
		// Load and Setup shaders for character rendering //
		////////////////////////////////////////////////////
		
        NSString* vtxPathName = nil;
        vtxPathName = [[NSBundle mainBundle] pathForResource:@"matrix" ofType:@"vsh"];
        NSString* frgPathName = nil;
        frgPathName = [[NSBundle mainBundle] pathForResource:@"matrix" ofType:@"fsh"];
        m_characterPrgName = [self loadShadersWithVertexPath:vtxPathName withFragmentPath:frgPathName];
        m_characterMvpUniformIdx = glGetUniformLocation(m_characterPrgName, "MVP");
		
		if(m_characterMvpUniformIdx < 0)
		{
			NSLog(@"No modelViewProjectionMatrix in character shader");
		}
        
        ////////////////////////////////////////////////
		// Set up OpenGL state that will never change //
		////////////////////////////////////////////////
		
		// Depth test will always be enabled
		glEnable(GL_DEPTH_TEST);
        
		// We will always cull back faces for better performance
		glEnable(GL_CULL_FACE);
		
		// Always use this clear color
		glClearColor(0.0f, 0.0f, 0.4f, 0.0f);
		
		// Draw our scene once without presenting the rendered image.
		//   This is done in order to pre-warm OpenGL
		// We don't need to present the buffer since we don't actually want the 
		//   user to see this, we're only drawing as a pre-warm stage
		[self render];
		
		// Check for errors to make sure all of our setup went ok
		GetGLError();
	}
	
	return self;
}


- (void) dealloc
{
	
    [super dealloc];
}

@end
