/*
 * Copyright 2010-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

#import "Utilities.h"

#import <AWSDynamoDB/AWSDynamoDB.h>
#import "AmazonClientManager.h"

@implementation Utilities

/**
 * Check for existance of tables and create them if necessary
 * Returns YES when tables are active
 * Returns NO if there was an error
 */
+(BOOL)setupTables
{
    // verify that TVM has been updated
    if ([TOKEN_VENDING_MACHINE_URL isEqualToString:@"CHANGEME.elasticbeanstalk.com"] || ([AmazonClientManager ddb] == nil) ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Credentials" message:CREDENTIALS_ALERT_MESSAGE delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return NO;
    }

    //Create Table
    DynamoDBCreateTableRequest *ctr = [DynamoDBCreateTableRequest new];
    ctr.tableName = USERS_TABLE;

    DynamoDBKeySchemaElement *hashKey = [DynamoDBKeySchemaElement new];
    hashKey.attributeName = USERS_KEY;
    hashKey.keyType = @"HASH";
    [ctr addKeySchema:hashKey];

    DynamoDBAttributeDefinition *hashAttDef = [DynamoDBAttributeDefinition new];
    hashAttDef.attributeName = USERS_KEY;
    hashAttDef.attributeType = @"S";
    [ctr addAttributeDefinition:hashAttDef];

    DynamoDBProvisionedThroughput *provisionedThroughput = [DynamoDBProvisionedThroughput new];
    provisionedThroughput.readCapacityUnits  = [NSNumber numberWithInt:10];
    provisionedThroughput.writeCapacityUnits = [NSNumber numberWithInt:5];
    ctr.provisionedThroughput = provisionedThroughput;

    NSLog(@"Trying to create table");
    
    AmazonDynamoDBClient *tempdb = [AmazonClientManager ddb];
    
    DynamoDBCreateTableResponse *ctResponse = [tempdb createTable:ctr];
    if(ctResponse.error == nil)
    {
        NSLog(@"Created %@", ctResponse.tableDescription.tableName);
    }
    else
    {
        NSException *exception = [ctResponse.error.userInfo objectForKey:@"exception"];

        if([exception isKindOfClass:[DynamoDBResourceInUseException class]])
        {
            NSLog(@"Table already created");
        }
        else
        {
            NSLog(@"Problem creating table, %@", ctResponse.error);
            return NO;
        }
    }

    //Create Table
    ctr = [DynamoDBCreateTableRequest new];
    ctr.tableName = LOCATIONS_TABLE;
    
    hashKey = [DynamoDBKeySchemaElement new];
    hashKey.attributeName = LOCATIONS_HASH_KEY;
    hashKey.keyType = @"HASH";
    [ctr addKeySchema:hashKey];
    hashAttDef = [DynamoDBAttributeDefinition new];
    hashAttDef.attributeName = LOCATIONS_HASH_KEY;
    hashAttDef.attributeType = @"N";
    [ctr addAttributeDefinition:hashAttDef];

//    DynamoDBKeySchemaElement *rangeKey = [DynamoDBKeySchemaElement new];
//    rangeKey.attributeName = LOCATIONS_RANGE_KEY;
//    rangeKey.keyType = @"RANGE";
//    [ctr addKeySchema:rangeKey];
//    DynamoDBAttributeDefinition *rangeAttDef = [DynamoDBAttributeDefinition new];
//    rangeAttDef.attributeName = LOCATIONS_RANGE_KEY;
//    rangeAttDef.attributeType = @"S";
//    [ctr addAttributeDefinition:rangeAttDef];
    
    provisionedThroughput = [DynamoDBProvisionedThroughput new];
    provisionedThroughput.readCapacityUnits  = [NSNumber numberWithInt:10];
    provisionedThroughput.writeCapacityUnits = [NSNumber numberWithInt:5];
    ctr.provisionedThroughput = provisionedThroughput;
    
    NSLog(@"Creating Locations table");
    
    ctResponse = [tempdb createTable:ctr];
    if(ctResponse.error == nil)
    {
        NSLog(@"Created %@", ctResponse.tableDescription.tableName);
    }
    else
    {
        NSException *exception = [ctResponse.error.userInfo objectForKey:@"exception"];
        
        if([exception isKindOfClass:[DynamoDBResourceInUseException class]])
        {
            NSLog(@"Table already created");
        }
        else
        {
            NSLog(@"Problem creating table, %@", ctResponse.error);
            return NO;
        }
    }

    //Create Table
    ctr = [DynamoDBCreateTableRequest new];
    ctr.tableName = AWESOME_TABLE;
    
    hashKey = [DynamoDBKeySchemaElement new];
    hashKey.attributeName = AWESOME_HASH_KEY;
    hashKey.keyType = @"HASH";
    [ctr addKeySchema:hashKey];
    hashAttDef = [DynamoDBAttributeDefinition new];
    hashAttDef.attributeName = AWESOME_HASH_KEY;
    hashAttDef.attributeType = @"S";
    [ctr addAttributeDefinition:hashAttDef];
    
    DynamoDBKeySchemaElement *rangeKey = [DynamoDBKeySchemaElement new];
    rangeKey.attributeName = AWESOME_RANGE_KEY;
    rangeKey.keyType = @"RANGE";
    [ctr addKeySchema:rangeKey];
    DynamoDBAttributeDefinition *rangeAttDef = [DynamoDBAttributeDefinition new];
    rangeAttDef.attributeName = AWESOME_RANGE_KEY;
    rangeAttDef.attributeType = @"S";
    [ctr addAttributeDefinition:rangeAttDef];
    
    provisionedThroughput = [DynamoDBProvisionedThroughput new];
    provisionedThroughput.readCapacityUnits  = [NSNumber numberWithInt:10];
    provisionedThroughput.writeCapacityUnits = [NSNumber numberWithInt:5];
    ctr.provisionedThroughput = provisionedThroughput;
    
    NSLog(@"Creating Awesome table");
    
    ctResponse = [tempdb createTable:ctr];
    if(ctResponse.error == nil)
    {
        NSLog(@"Created %@", ctResponse.tableDescription.tableName);
    }
    else
    {
        NSException *exception = [ctResponse.error.userInfo objectForKey:@"exception"];
        
        if([exception isKindOfClass:[DynamoDBResourceInUseException class]])
        {
            NSLog(@"Table already created");
        }
        else
        {
            NSLog(@"Problem creating table, %@", ctResponse.error);
            return NO;
        }
    }
    
    [Utilities waitForTable:USERS_TABLE toTransitionToStatus:@"ACTIVE"];
    [Utilities waitForTable:LOCATIONS_TABLE toTransitionToStatus:@"ACTIVE"];
    [Utilities waitForTable:AWESOME_TABLE toTransitionToStatus:@"ACTIVE"];
    
    return YES;
}

/**
 * Wait for a table to transition to a given state (i.e. ACTIVE)
 */
+(void)waitForTable:(NSString *)tableName toTransitionToStatus:(NSString *)toStatus
{
    NSString *status =@"";

    do {
        if (status.length > 0) {
            [NSThread sleepForTimeInterval:15];
        }
        DynamoDBDescribeTableRequest *request = [[DynamoDBDescribeTableRequest alloc] initWithTableName:tableName];
        DynamoDBDescribeTableResponse *response = [[AmazonClientManager ddb] describeTable:request];

        status = response.table.tableStatus;

    } while (![status isEqualToString:toStatus]);
}

/**
 * Generate a unique ID that can be used for objects
 */
+(NSString *)getUUID
{
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);

    return uuidString;
}

@end
