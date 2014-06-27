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

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

/**
 * Vending maching for anonymous log in
 */

#define TOKEN_VENDING_MACHINE_URL    @"awesomonymous-env.elasticbeanstalk.com"
#define USE_SSL                      NO

/**
 * Role that user will assume after logging in.
 * This role should have appropriate policy to restrict actions to only required
 * services and resources.
 */
#define FB_ROLE_ARN @"arn:aws:iam::234023849645:role/AwesomeFBUser"

#define IDP_NOT_ENABLED_MESSAGE      @"This provider is not enabled, please refer to Constants.h to enabled this provider"
#define CREDENTIALS_ALERT_MESSAGE    @"Please update the Constants.h file with your Facebook or Google App settings."
#define ACCESS_KEY_ID                @"USED_ONLY_FOR_TESTING"  // Leave this value as is.
#define SECRET_KEY                   @"USED_ONLY_FOR_TESTING"  // Leave this value as is.

#define USERS_TABLE                  @"AwesomeUsers"
#define USERS_KEY                    @"userId"
#define USERS_VERSIONS               @"version"

#define LOCATIONS_TABLE              @"AwesomeLocations"
#define LOCATIONS_HASH_KEY           @"locationKey"
#define LOCATIONS_RANGE_KEY          @"userId"
#define LOCATIONS_VERSIONS           @"version"

#define AWESOME_TABLE                @"AwesomeTable"
#define AWESOME_HASH_KEY             @"myUserId"
#define AWESOME_RANGE_KEY            @"rangeKey"
#define AWESOME_VERSIONS             @"version"


@interface Constants:NSObject {
}

+(UIAlertView *)credentialsAlert;
+(UIAlertView *)errorAlert:(NSString *)message;
+(UIAlertView *)expiredCredentialsAlert;

@end
