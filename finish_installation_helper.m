
#import <AppKit/AppKit.h>
#import "SUInstaller.h"
#import "SUHost.h"
#import "SUStandardVersionComparator.h"
#import "SUStatusController.h"
#import "SUPlainInstallerInternals.h"
#import "SULog.h"

static void new_connection_handler(xpc_connection_t peer)
{
    xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
        // Handle messages and errors.
        
        xpc_type_t type = xpc_get_type(event);
        if (type == XPC_TYPE_ERROR) {
            
        }
        else {
            assert(type == XPC_TYPE_DICTIONARY);
            
            xpc_object_t array = xpc_dictionary_get_value(event, "Root");
            
            if( xpc_array_get_count(array) < 5 || xpc_array_get_count(array) > 6 )
                return;
            
            [NSTask launchedTaskWithLaunchPath: [NSString stringWithUTF8String:xpc_array_get_string(array, 0)] arguments:[NSArray arrayWithObjects:[NSString stringWithUTF8String:xpc_array_get_string(array, 1)], [NSString stringWithUTF8String:xpc_array_get_string(array, 2)], [NSString stringWithUTF8String:xpc_array_get_string(array, 3)], [NSString stringWithUTF8String:xpc_array_get_string(array, 4)], xpc_array_get_bool(array, 5) ? @"1" : @"0", nil]];
            
            xpc_connection_send_message(xpc_dictionary_get_remote_connection(event), xpc_dictionary_create_reply(event));
        }
    });
    xpc_connection_resume(peer);
}

int main (int argc, const char * argv[])
{
    xpc_main(new_connection_handler);
    
    exit(EXIT_FAILURE);
}
