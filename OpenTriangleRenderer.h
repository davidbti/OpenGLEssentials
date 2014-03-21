//
//  OpenTriangleRenderer.h
//  OSXGLEssentials
//
//  Created by Matthew Doig on 3/20/14.
//
//

#include "glUtil.h"
#import <Foundation/Foundation.h>

@interface OpenTriangleRenderer : NSObject {
	
	GLuint m_defaultFBOName;
    
}

- (id) initWithDefaultFBO: (GLuint) defaultFBOName;
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height;
- (void) render;
- (void) dealloc;

@end
