//
//  iMateData.h
//  iMateTest
//
//  Created by hxsmart on 12-10-15.
//
//

#import <Foundation/Foundation.h>

typedef enum {
	MATEReceivedDataIsValid = 0,
	MATEReceivedDataIsInvalid,
	MATEReceivedDataIsFault
} MateReceivedDataStatus;

@interface iMateData : NSObject

@property MateReceivedDataStatus receivedDataStatus;

@property (strong, nonatomic) NSMutableData *receivedPackData;
@property (strong, nonatomic) NSData *sendData;
@property (strong, nonatomic) NSData *receivedData;
@property Byte returnCode;
@property Byte receivedSequenceNumber;

- (void)reset;
- (NSData *)packSendData;
- (MateReceivedDataStatus)unpackReceivedData;
- (void)appendReceiveData:(NSData *)receivedSubData;

- (NSInteger)getReturnCode;
- (NSString *)getErrorString;
- (int)getReceiveDataLength;

@end
