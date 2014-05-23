
#import <AppKit/AppKit.h>
#import "SUPlainInstallerInternals.h"

static void new_connection_handler(xpc_connection_t peer)
{
    xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
        // Handle messages and errors.
        
        xpc_type_t type = xpc_get_type(event);
        if (type == XPC_TYPE_ERROR) {
            
        }
        else {
            assert(type == XPC_TYPE_DICTIONARY);
            
            NSString *perfrom = [NSString stringWithUTF8String:xpc_dictionary_get_string(event, "perform")];
            
            if ([perfrom isEqualToString:@"copyPathWithAuthentication"]) {
                const char *utf8Src = xpc_dictionary_get_string(event, "src");
                const char *utf8Dst = xpc_dictionary_get_string(event, "dst");
                const char *utf8Tmp = xpc_dictionary_get_string(event, "tmp");
                
                NSString *src = [NSString stringWithUTF8String:utf8Src];
                NSString *dst = [NSString stringWithUTF8String:utf8Dst];
                NSString *tmp = NULL;
                if (utf8Tmp != NULL)
                    tmp = [NSString stringWithUTF8String:utf8Tmp];
                
                NSError *error = NULL;
                [SUPlainInstaller copyPathWithAuthentication:src overPath:dst temporaryName:tmp error:&error];
                
                xpc_object_t replyMessage = xpc_dictionary_create_reply(event);
                
                if (error) {
                    NSData *errorData = [NSKeyedArchiver archivedDataWithRootObject:error];
                    
                    xpc_dictionary_set_data(replyMessage, "error", errorData.bytes, errorData.length);
                }
                
                xpc_connection_send_message(xpc_dictionary_get_remote_connection(event), replyMessage);
            }
            else if ([perfrom isEqualToString:@"launchTask"]) {
                const char *utf8Path = xpc_dictionary_get_string(event, "path");
                xpc_object_t xpcArguments = xpc_dictionary_get_value(event, "arguments");
                
                NSString *path = [NSString stringWithUTF8String:utf8Path];
                NSMutableArray *arguments = [[NSMutableArray alloc] initWithCapacity:xpc_array_get_count(xpcArguments)];
                for (size_t i = 0; i < xpc_array_get_count(xpcArguments); i++) {
                    [arguments addObject:[NSString stringWithUTF8String:xpc_array_get_string(xpcArguments, i)]];
                }
                
                [NSTask launchedTaskWithLaunchPath:path arguments:arguments];
                
                xpc_connection_send_message(xpc_dictionary_get_remote_connection(event), xpc_dictionary_create_reply(event));
            }
        }
    });
    xpc_connection_resume(peer);
}

int main (int argc, const char * argv[])
{
    xpc_main(new_connection_handler);
    
    exit(EXIT_FAILURE);
}
