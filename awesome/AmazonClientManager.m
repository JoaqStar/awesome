/*
 * Copyright 2010-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "AmazonClientManager.h"
#import <AWSRuntime/AWSRuntime.h>
#import "AmazonAnonymousKeyChainWrapper.h"
#import <AWSSecurityTokenService/AWSSecurityTokenService.h>
#import "AmazonTVMClient.h"

static AmazonCredentials *credentials = nil;
static AmazonTVMClient *tvm = nil;
static AmazonWIFCredentialsProvider      *provider = nil;

// This DynamoDB client object is used for operations that are not supported by the Persistence Framework. eg. Create tables

static AmazonDynamoDBClient *ddb = nil;

@implementation AmazonClientManager

+ (AmazonClientManager *)sharedInstance
{
    static AmazonClientManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AmazonClientManager alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Anonymous loging

- (AmazonCredentials *)credentials;
{
    [AmazonClientManager validateCredentials];
    return credentials;
}

- (void)refresh
{
    [AmazonClientManager wipeAllCredentials];
    [AmazonClientManager validateCredentials];
}
+ (AmazonTVMClient *)tvm
{
    if (tvm == nil) {
        tvm = [[AmazonTVMClient alloc] initWithEndpoint:TOKEN_VENDING_MACHINE_URL useSSL:USE_SSL];
    }
    
    return tvm;
}

+ (AmazonWIFCredentialsProvider *)provider
{
    [self validateCredentials];
    return provider;
}

+ (AmazonDynamoDBClient *)ddb
{
    [self validateCredentials];
    return ddb;
}

+ (Response *)validateCredentials
{
    Response *ableToGetToken = [[Response alloc] initWithCode:200 andMessage:@"OK"];
    
    if ([AmazonClientManager isLoggedIn]) {
        if (ddb == nil)
        {
            @synchronized(self)
            {
                if (ddb == nil)
                {
                    [self setupClientsWithFacebook:YES];
                }
            }
        }
    } else {
        if ([AmazonAnonymousKeyChainWrapper areCredentialsExpired]) {
            
            @synchronized(self)
            {
                if ([AmazonAnonymousKeyChainWrapper areCredentialsExpired]) {
                    
                    ableToGetToken = [[self tvm] anonymousRegister];
                    
                    if ( [ableToGetToken wasSuccessful])
                    {
                        ableToGetToken = [[self tvm] getToken];
                        
                        if ( [ableToGetToken wasSuccessful])
                        {
                            [self setupClientsWithFacebook:NO];
                        }
                    }
                }
            }
        }
        else if (ddb == nil)
        {
            @synchronized(self)
            {
                if (ddb == nil)
                {
                    [self setupClientsWithFacebook:NO];
                }
            }
        }
    }
    
    
    return ableToGetToken;
}

+ (void)setupClientsWithFacebook:(BOOL)useFacebook
{
    if (useFacebook) {

        ddb = [[AmazonDynamoDBClient alloc] initWithCredentialsProvider:provider];
    } else {
        credentials = [AmazonAnonymousKeyChainWrapper getCredentialsFromKeyChain];
        ddb = [[AmazonDynamoDBClient alloc] initWithCredentials:credentials];
    }
    ddb.endpoint = [AmazonEndpoints ddbEndpoint:US_WEST_2];
    ddb.timeout = 10;
}


+(bool)hasCredentials
{
    return TRUE;
}

+(bool)isLoggedIn
{
    return ( [AmazonWIFKeyChainWrapper username] != nil && provider != nil);
}

+(void)initClients
{
//    if (_wif != nil) {
//        [_s3 release];
//        _s3  = [[AmazonS3Client alloc] initWithCredentialsProvider:_wif];
//    }
}

+(void)wipeAllCredentials
{
    @synchronized(self)
    {
        [AmazonAnonymousKeyChainWrapper wipeCredentialsFromKeyChain];
        ddb = nil;
    }
}

+(BOOL)FBLogin:(FBSession *)session
{
    // session already open, exit
    if (session.isOpen) {
        return [AmazonClientManager CompleteFBLogin:session];
    }
    
    if (session.state != FBSessionStateCreated) {
        // Create a new, logged out session.
        session = [[FBSession alloc] init];
    }
    
    return [AmazonClientManager CompleteFBLogin:session];
    
}

+(BOOL)CompleteFBLogin:(FBSession *)session
{
    provider = [[AmazonWIFCredentialsProvider alloc] initWithRole:FB_ROLE_ARN
                                          andWebIdentityToken:session.accessTokenData.accessToken
                                                 fromProvider:@"graph.facebook.com"];
    
    // if we have an id, we are logged in
    if (provider.subjectFromWIF != nil) {
        NSLog(@"IDP id: %@", provider.subjectFromWIF);
        [AmazonWIFKeyChainWrapper storeUsername:provider.subjectFromWIF];
        [self initClients];
        
        return YES;
    }
    else {
        return NO;
    }
}


@end
