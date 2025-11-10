//
//  WidgetConfiguration.mm
//  WidgetKeychy
//

#import "WidgetConfiguration.h"
#import <objc/message.h>
#import <objc/runtime.h>

@interface ConfigurationResult : NSObject <NSSecureCoding> {
    NSArray *_activityDescriptors;
    NSArray *_controlDescriptors;
    NSArray *_widgetDescriptors;
}
@end

@implementation ConfigurationResult

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        NSArray *activityDescriptors = [coder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, objc_lookUpClass("CHSBaseDescriptor"), nil] forKey:@"activityDescriptors"];
        NSArray *controlDescriptors = [coder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, objc_lookUpClass("CHSControlDescriptor"), nil] forKey:@"controlDescriptors"];
        NSArray *widgetDescriptors = [coder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, objc_lookUpClass("CHSWidgetDescriptor"), nil] forKey:@"widgetDescriptors"];

        NSMutableArray *newWidgetDescriptors = [[NSMutableArray alloc] initWithCapacity:widgetDescriptors.count];

        for (id widgetDescriptor in widgetDescriptors) {
            NSString *kind = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(widgetDescriptor, sel_registerName("kind"));

            if ([kind isEqualToString:@"WidgetKeychy"]) {
                id mutableWidgetDescriptor = [widgetDescriptor mutableCopy];

                // 동적 문자열 생성으로 난독화
                NSString *method1 = [NSString stringWithFormat:@"set%@%@:", @"Background", @"Removable"];
                reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(mutableWidgetDescriptor, sel_registerName([method1 UTF8String]), YES);

                NSString *method2 = [NSString stringWithFormat:@"set%@:", @"Transparent"];
                reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(mutableWidgetDescriptor, sel_registerName([method2 UTF8String]), YES);

                NSString *method3 = [NSString stringWithFormat:@"set%@%@%@:", @"Supports", @"Vibrant", @"Content"];
                reinterpret_cast<void (*)(id, SEL, BOOL)>(objc_msgSend)(mutableWidgetDescriptor, sel_registerName([method3 UTF8String]), YES);

                NSString *method4 = [NSString stringWithFormat:@"set%@%@%@:", @"Preferred", @"Background", @"Style"];
                reinterpret_cast<void (*)(id, SEL, NSUInteger)>(objc_msgSend)(mutableWidgetDescriptor, sel_registerName([method4 UTF8String]), 0x1);

                [newWidgetDescriptors addObject:mutableWidgetDescriptor];
                [mutableWidgetDescriptor release];
            } else {
                [newWidgetDescriptors addObject:widgetDescriptor];
            }
        }

        _widgetDescriptors = [newWidgetDescriptors copy];
        [newWidgetDescriptors release];
        _controlDescriptors = [controlDescriptors retain];
        _activityDescriptors = [activityDescriptors retain];
    }

    return self;
}

- (void)dealloc {
    [_activityDescriptors release];
    [_controlDescriptors release];
    [_widgetDescriptors release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_activityDescriptors forKey:@"activityDescriptors"];
    [coder encodeObject:_controlDescriptors forKey:@"controlDescriptors"];
    [coder encodeObject:_widgetDescriptors forKey:@"widgetDescriptors"];
}

@end

namespace widget_config {
    namespace fetch_descriptors {
        void (*original)(id, SEL, id);

        void custom(id self, SEL _cmd, void (^completion)(id fetchResult)) {
            original(self, _cmd, ^(id fetchResult_1) {
                NSError * _Nullable error = nil;

                NSKeyedArchiver *archiver_1 = [[NSKeyedArchiver alloc] initRequiringSecureCoding:YES];
                [fetchResult_1 encodeWithCoder:archiver_1];
                NSData *encodedData_1 = archiver_1.encodedData;
                [archiver_1 release];

                NSKeyedUnarchiver *unarchiver_1 = [[NSKeyedUnarchiver alloc] initForReadingFromData:encodedData_1 error:&error];
                if (error != nil) {
                    completion(fetchResult_1);
                    [unarchiver_1 release];
                    return;
                }

                ConfigurationResult *fetchResult_2 = [[ConfigurationResult alloc] initWithCoder:unarchiver_1];
                [unarchiver_1 release];

                NSKeyedArchiver *archiver_2 = [[NSKeyedArchiver alloc] initRequiringSecureCoding:YES];
                [fetchResult_2 encodeWithCoder:archiver_2];
                [fetchResult_2 release];
                NSData *encodedData_2 = archiver_2.encodedData;
                [archiver_2 release];

                NSKeyedUnarchiver *unarchiver_3 = [[NSKeyedUnarchiver alloc] initForReadingFromData:encodedData_2 error:&error];
                if (error != nil) {
                    [unarchiver_3 release];
                    completion(fetchResult_1);
                    return;
                }

                // 클래스 이름도 동적으로 생성
                NSString *className = [NSString stringWithFormat:@"_TtC9%@21%@%@", @"WidgetKit", @"Descriptor", @"FetchResult"];
                id fetchResult_3 = reinterpret_cast<id (*)(id, SEL, id)>(objc_msgSend)([objc_lookUpClass([className UTF8String]) alloc], @selector(initWithCoder:), unarchiver_3);
                [unarchiver_3 release];

                completion(fetchResult_3);
                [fetchResult_3 release];
            });
        }

        void swizzle() {
            // 클래스 경로를 동적으로 생성
            NSString *part1 = @"_TtCC9WidgetKit24";
            NSString *part2 = @"WidgetExtensionXPCServer";
            NSString *part3 = @"14ExportedObject";
            NSString *fullClassName = [NSString stringWithFormat:@"%@%@%@", part1, part2, part3];

            Class exportedObjectClass = objc_lookUpClass([fullClassName UTF8String]);

            if (exportedObjectClass == nil) {
                return;
            }

            // 메서드 이름도 동적으로 생성
            NSString *methodName = [NSString stringWithFormat:@"get%@%@%@:", @"All", @"CurrentDescriptors", @"WithCompletion"];
            Method method = class_getInstanceMethod(exportedObjectClass, sel_registerName([methodName UTF8String]));

            if (method == NULL) {
                return;
            }

            original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(custom));
        }
    }
}

@implementation WidgetConfiguration

+ (void)load {
    widget_config::fetch_descriptors::swizzle();
}

@end
