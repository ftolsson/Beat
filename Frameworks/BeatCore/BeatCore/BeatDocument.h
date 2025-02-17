//
//  BeatDocument.h
//  BeatCore
//
//  Created by Lauri-Matti Parppei on 20.2.2023.
//

#import <Foundation/Foundation.h>
#import <BeatParsing/BeatParsing.h>

@protocol BeatDocumentDelegate
- (NSAttributedString*)attributedString;
@end

NS_ASSUME_NONNULL_BEGIN

@interface BeatDocument : NSObject

@property (nonatomic) BeatDocumentSettings* settings;

@end

NS_ASSUME_NONNULL_END
