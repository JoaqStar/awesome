//
//  SNSMessenger.m
//  awesome
//
//  Created by Joaquin Brown on 1/6/14.
//  Copyright (c) 2014 Joaquin Brown. All rights reserved.
//

#import "SNSMessenger.h"
#import <AWSSNS/AWSSNS.h>
#import "AmazonClientManager.h"

@interface SNSMessenger ()

@property (nonatomic, strong) AmazonSNSClient *snsClient;

@end

@implementation SNSMessenger

+ (id)sharedManager {
    static SNSMessenger *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        AmazonWIFCredentialsProvider *provider = [AmazonClientManager provider];
        self.snsClient = [[AmazonSNSClient alloc] initWithCredentialsProvider:provider];
        self.snsClient.endpoint = [AmazonEndpoints snsEndpoint:US_WEST_2];
    }
    return self;
}

- (BOOL) sendNotificationToEndpoint:(NSString *)endpointARN withComment:(NSString *)comment
{
    @try {
        SNSPublishRequest *publishRequest = [[SNSPublishRequest alloc] init];
        [publishRequest setTargetArn:endpointARN];
#ifdef DEBUG
        NSString *jsonString = [NSString stringWithFormat:@"{\"default\":\"default comment\",\"APNS_SANDBOX\":\"{\\\"aps\\\":{\\\"alert\\\":\\\"%@\\\",\\\"sound\\\":\\\"Glass.caf\\\",\\\"badge\\\":1}}\"}", comment];
#else
        NSString *jsonString = [NSString stringWithFormat:@"{\"default\":\"default comment\",\"APNS\":\"{\\\"aps\\\":{\\\"alert\\\":\\\"%@\\\",\\\"sound\\\":\\\"Glass.caf\\\",\\\"badge\\\":1}}\"}", comment];
#endif
        
        [publishRequest setMessage:jsonString];
        [publishRequest setMessageStructure:@"json"];
        SNSPublishResponse *publishResponse = [self.snsClient publish:publishRequest];
        
        if (publishResponse.requestId == nil) {
#ifdef DEBUG
            jsonString = [NSString stringWithFormat:@"{\"default\":\"default comment\",\"APNS_SANDBOX\":\"{\\\"aps\\\":{\\\"alert\\\":\\\"Someone thinks you are Awesome.\\\",\\\"sound\\\":\\\"Glass.caf\\\",\\\"badge\\\":1}}\"}"];
#else
            jsonString = [NSString stringWithFormat:@"{\"default\":\"default comment\",\"APNS\":\"{\\\"aps\\\":{\\\"alert\\\":\\\"Someone thinks you are Awesome.\\\",\\\"sound\\\":\\\"Glass.caf\\\",\\\"badge\\\":1}}\"}"];
#endif
            [publishRequest setMessage:jsonString];
            publishResponse = [self.snsClient publish:publishRequest];
        }
        
    } @catch (NSException *exception) {
        NSLog(@"exception is %@", exception);
        return NO;
    }
    
    return YES;
}

- (NSString *) createEndpointARNFromToken:(NSString *)token forUser:(NSString *)userId
{
    NSString *endpoint;
    @try {
        SNSCreatePlatformEndpointRequest *createEndpointRequest = [[SNSCreatePlatformEndpointRequest alloc] init];
        [createEndpointRequest setToken:token];
        [createEndpointRequest setCustomUserData:userId];
#ifdef DEBUG
        [createEndpointRequest setPlatformApplicationArn:@"arn:aws:sns:us-west-2:234023849645:app/APNS_SANDBOX/Awesome."];
#else
        [createEndpointRequest setPlatformApplicationArn:@"arn:aws:sns:us-west-2:234023849645:app/APNS/Awesome."];
#endif
        SNSCreatePlatformEndpointResponse *createEndpointResponse = [self.snsClient createPlatformEndpoint:createEndpointRequest];
        
        if (createEndpointResponse.requestId != nil && createEndpointResponse.endpointArn != nil) {
            endpoint = [createEndpointResponse endpointArn];
        } else {
            SNSListEndpointsByPlatformApplicationRequest *listEndpointsRequest = [[SNSListEndpointsByPlatformApplicationRequest alloc] init];
#ifdef DEBUG
            [listEndpointsRequest setPlatformApplicationArn:@"arn:aws:sns:us-west-2:234023849645:app/APNS_SANDBOX/Awesome."];
#else
            [listEndpointsRequest setPlatformApplicationArn:@"arn:aws:sns:us-west-2:234023849645:app/APNS/Awesome."];
#endif
            [listEndpointsRequest setNextToken:token];
            SNSListEndpointsByPlatformApplicationResponse *listEndpointsResponse = [self.snsClient listEndpointsByPlatformApplication:listEndpointsRequest];
            
            for (SNSEndpoint *endpoint in listEndpointsResponse.endpoints) {
                NSLog(@"endpoint is %@", endpoint);
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"exception is %@", exception);
        return nil;
    }
    return endpoint;
}

@end
