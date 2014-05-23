//
//  SUService.m
//  Sparkle
//
//  Created by Sinoru on 2014. 5. 23..
//
//

#import "SUService.h"

@implementation SUService

- (id)init
{
    self = [super init];
    if (self) {
        _serviceConnection = xpc_connection_create("org.andymatuschak.Sparkle-Service", NULL);
        xpc_connection_set_event_handler(_serviceConnection, ^(xpc_object_t event) { [self serviceConnectionDidReceiveEvent:event]; });
        
        if (_serviceConnection == NULL)
            return nil;
    }
    return self;
}

- (void)serviceConnectionDidReceiveEvent:(xpc_object_t)event
{
    xpc_type_t type = xpc_get_type(event);
    
    if (type == XPC_TYPE_ERROR) {
        
        if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
            // The service has either cancaled itself, crashed, or been
            // terminated.  The XPC connection is still valid and sending a
            // message to it will re-launch the service.  If the service is
            // state-full, this is the time to initialize the new service.
            
            NSLog(@"Interrupted connection to XPC service");
        } else if (event == XPC_ERROR_CONNECTION_INVALID) {
            // The service is invalid. Either the service name supplied to
            // xpc_connection_create() is incorrect or we (this process) have
            // canceled the service; we can do any cleanup of appliation
            // state at this point.
            
            NSLog(@"Connection Invalid error for XPC service");
        } else {
            NSLog(@"Unexpected error for XPC service");
        }
    } else {
        NSLog(@"Received unexpected event for XPC service");
    }
}

- (BOOL)copyPathWithAuthentication:(NSString *)src overPath:(NSString *)dst temporaryName:(NSString *)tmp error:(NSError **)error
{
    xpc_connection_resume(_serviceConnection);
    
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    
    xpc_dictionary_set_string(message, "perform", "copyPathWithAuthentication");
    
    xpc_dictionary_set_string(message, "src", src.UTF8String);
    xpc_dictionary_set_string(message, "dst", src.UTF8String);
    
    if (tmp)
        xpc_dictionary_set_string(message, "tmp", tmp.UTF8String);
    
    xpc_object_t repliedMessage = xpc_connection_send_message_with_reply_sync(_serviceConnection, message);
    
    xpc_type_t repliedMessageType = xpc_get_type(repliedMessage);
    
    BOOL errorOccured;
    if (repliedMessageType == XPC_TYPE_ERROR) {
        // Something happend
        errorOccured = YES;
    }
    else {
        assert(repliedMessage == XPC_TYPE_DICTIONARY);
        
        size_t dataLength;
        const void *dataBytes = xpc_dictionary_get_data(repliedMessage, "error", &dataLength);
        
        if (dataLength == 0)
            errorOccured = NO;
        else {
            errorOccured = YES;
            
            if (error) {
                NSData *errorData = [[NSData alloc] initWithBytes:dataBytes length:dataLength];
                
                *error = [NSKeyedUnarchiver unarchiveObjectWithData:errorData];
            }
        }
    }
    
    xpc_connection_suspend(_serviceConnection);
    
    return !errorOccured;
}

- (void)launchTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments
{
    xpc_connection_resume(_serviceConnection);
    
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    
    xpc_dictionary_set_string(message, "perform", "launchTask");
    
    xpc_dictionary_set_string(message, "path", path.UTF8String);
    
    xpc_object_t xpcArguments = xpc_array_create(NULL, 0);
    [arguments enumerateObjectsUsingBlock:^(NSString *argument, NSUInteger idx, BOOL *stop) {
        xpc_array_append_value(xpcArguments, xpc_string_create(argument.UTF8String));
    }];
    xpc_dictionary_set_value(message, "arguments", xpcArguments);
    
    xpc_object_t repliedMessage = xpc_connection_send_message_with_reply_sync(_serviceConnection, message);
    
    xpc_type_t repliedMessageType = xpc_get_type(repliedMessage);
    
    if (repliedMessageType == XPC_TYPE_ERROR) {
        // Something happend
    }
    
    xpc_connection_suspend(_serviceConnection);
}

@end
