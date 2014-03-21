//
//  OpenMatrixRenderer.h
//  OSXGLEssentials
//
//  Created by Matthew Doig on 3/20/14.
//
//

#import "glUtil.h"
#import <Foundation/Foundation.h>

@interface OpenMatrixRenderer : NSObject {
	
	GLuint m_defaultFBOName;
    
}

- (id) initWithDefaultFBO: (GLuint) defaultFBOName;
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height;
- (void) render;
- (void) dealloc;

@end

