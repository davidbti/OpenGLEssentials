//
//  OpenTexture1Renderer.h
//  OSXGLEssentials
//
//  Created by Matthew Doig on 3/21/14.
//
//

#import "glUtil.h"
#import <Foundation/Foundation.h>

@interface OpenObjRenderer : NSObject

- (id) initWithDefaultFBO: (GLuint) defaultFBOName;
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height;
- (void) render;
- (void) dealloc;

@end