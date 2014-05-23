//
//  SUService.h
//  Sparkle
//
//  Created by Sinoru on 2014. 5. 23..
//
//

#import <Foundation/Foundation.h>

@interface SUService : NSObject {
    xpc_connection_t _serviceConnection;
}

- (BOOL)copyPathWithAuthentication:(NSString *)src overPath:(NSString *)dst temporaryName:(NSString *)tmp error:(NSError **)error;

- (void)launchTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments;

@end
