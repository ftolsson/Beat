//
//  BeatTextIO.m
//  BeatCore
//
//  Created by Lauri-Matti Parppei on 18.2.2023.
//

#import "BeatTextIO.h"
#import <TargetConditionals.h>
#import <BeatParsing/BeatParsing.h>
#import "BeatUserDefaults.h"

@implementation BeatTextIO

-(instancetype)initWithDelegate:(id<BeatTextIODelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

/**
 Main method for adding text to editor view.  Forces added text to be parsed, but does NOT invoke undo manager.
 Don't use this for adding text, but go through the intermediate methods instead, `addString`, `removeString` etc.
 */
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString*)string
{
    BXTextView* textView = self.delegate.getTextView;
    
    // If range is over bounds (this can happen with certain undo operations for some reason), let's fix it
    if (range.length + range.location > _delegate.text.length) {
        NSInteger length = _delegate.text.length - range.location;
        range = NSMakeRange(range.location, length);
    }
    
#if TARGET_OS_IOS
    // Text view fires up shouldChangeTextInRange only when the text is changed by the user.
    // When replacing stuff directly in the view, we need to call it manually.
    if ([self textView:_delegate.textView shouldChangeTextInRange:range replacementText:string]) {
        UITextRange* textRange = [_formatting getTextRangeFor:range];
        [textView replaceRange:textRange withText:string];
        [self textViewDidChange:_delegate.textView];
    }
#else
    if ([self.delegate textView:textView shouldChangeTextInRange:range replacementString:string]) {
        [textView replaceCharactersInRange:range withString:string];
        [self.delegate textDidChange:[NSNotification notificationWithName:@"" object:nil]];
    }
#endif
}

static bool _skipAutomaticLineBreaks = false;
- (void)addString:(NSString*)string atIndex:(NSUInteger)index {
    [self addString:string atIndex:index skipAutomaticLineBreaks:false];
}
- (void)addString:(NSString*)string atIndex:(NSUInteger)index skipAutomaticLineBreaks:(bool)skipLineBreaks
{
    _skipAutomaticLineBreaks = skipLineBreaks;
    [self replaceCharactersInRange:NSMakeRange(index, 0) withString:string];
    _skipAutomaticLineBreaks = false;
    
    [[_delegate.undoManager prepareWithInvocationTarget:self] removeString:string atIndex:index];
}

- (void)removeString:(NSString*)string atIndex:(NSUInteger)index
{
    [self replaceCharactersInRange:NSMakeRange(index, string.length) withString:@""];
    [[_delegate.undoManager prepareWithInvocationTarget:self] addString:string atIndex:index];
}

- (void)replaceRange:(NSRange)range withString:(NSString*)newString
{
    // Remove unnecessary line breaks
    newString = [newString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    
    // Replace with undo registration
    NSString *oldString = [_delegate.text substringWithRange:range];
    [self replaceCharactersInRange:range withString:newString];
    [[_delegate.undoManager prepareWithInvocationTarget:self] replaceString:newString withString:oldString atIndex:range.location];
}

- (void)replaceString:(NSString*)string withString:(NSString*)newString atIndex:(NSUInteger)index
{
    // Replace with undo registration
    NSRange range = NSMakeRange(index, string.length);
    [self replaceCharactersInRange:range withString:newString];
    [[_delegate.undoManager prepareWithInvocationTarget:self] replaceString:newString withString:string atIndex:index];
}

- (void)removeRange:(NSRange)range
{
    NSString *string = [_delegate.text substringWithRange:range];
    [self replaceCharactersInRange:range withString:@""];
    [[_delegate.undoManager prepareWithInvocationTarget:self] addString:string atIndex:range.location];
}

- (void)moveStringFrom:(NSRange)range to:(NSInteger)position actualString:(NSString*)string
{
    _delegate.moving = YES;
    NSString *oldString = [_delegate.text substringWithRange:range];
    
    NSString *stringToMove = string;
    NSInteger length = _delegate.text.length;
    
    if (position > length) position = length;
    
    [self replaceCharactersInRange:range withString:@""];
    
    NSInteger newPosition = position;
    if (range.location < position) {
        newPosition = position - range.length;
    }
    if (newPosition < 0) newPosition = 0;
    
    [self replaceCharactersInRange:NSMakeRange(newPosition, 0) withString:stringToMove];
    
    NSRange undoingRange;
    NSInteger undoPosition;
    
    if (range.location > position) {
        undoPosition = range.location + stringToMove.length;
        undoingRange = NSMakeRange(position, stringToMove.length);
    } else {
        undoingRange = NSMakeRange(newPosition, stringToMove.length);
        undoPosition = range.location;
    }
    
    [[_delegate.undoManager prepareWithInvocationTarget:self] moveStringFrom:undoingRange to:undoPosition actualString:oldString];
    [_delegate.undoManager setActionName:@"Move Scene"];
    
    _delegate.moving = NO;
}

- (void)moveStringFrom:(NSRange)range to:(NSInteger)position
{
    NSString *stringToMove = [_delegate.text substringWithRange:range];
    [self moveStringFrom:range to:position actualString:stringToMove];
}

- (NSRange)globalRangeFromLocalRange:(NSRange*)range inLineAtPosition:(NSUInteger)position
{
    return NSMakeRange(range->location + position, range->length);
}

- (void)moveScene:(OutlineScene*)sceneToMove from:(NSInteger)from to:(NSInteger)to
{
    // FOLLOWING CODE IS A MESS. Dread lightly.
    // Thanks for the heads up, past me, but I'll just dive right in
    
    // NOTE FROM BEAT 1.1 r4:
    // The scenes know if they miss omission begin / terminator. The trouble is, I have no idea how to put that information into use without dwelving into an endless labyrinth of string indexes... soooo... do it later?
    
    // On to the very dangerous stuff :-) fuck me :----)
    NSRange range = NSMakeRange(sceneToMove.position, sceneToMove.length);
    NSString *string = [_delegate.text substringWithRange:range];
    
    NSInteger omissionStartsAt = NSNotFound;
    NSInteger omissionEndsAt = NSNotFound;
    
    if (sceneToMove.omitted) {
        // We need to find out where the omission begins & ends
        NSInteger idx = [_delegate.parser.lines indexOfObject:sceneToMove.line];
        if (idx == NSNotFound) return; // Shouldn't happen
        
        if (idx > 0) {
            // Look for start of omission, but break when encountering an outline item
            for (NSInteger i = idx - 1; i >= 0; i++) {
                Line *prevLine = _delegate.parser.lines[i];
                if (prevLine.isOutlineElement) break;
                else if (prevLine.omitOut && [prevLine.string rangeOfString:@"/*"].location != NSNotFound) {
                    omissionStartsAt = prevLine.position + [prevLine.string rangeOfString:@"/*"].location;
                    break;
                }
            }
            
            // Look for end of omission
            for (NSInteger i = idx + 1; i < _delegate.parser.lines.count; i++) {
                Line *nextLine = _delegate.parser.lines[i];
                if (nextLine.type == heading || nextLine.type == section) break;
                else if (nextLine.omitIn && [nextLine.string rangeOfString:@"*/"].location != NSNotFound) {
                    omissionEndsAt = nextLine.position + [nextLine.string rangeOfString:@"*/"].location + 2;
                }
            }
        }
        
        
        // Recreate range to represent the actual range with omission symbols
        // (if applicable)
        NSInteger loc = (omissionStartsAt == NSNotFound) ? sceneToMove.position : omissionStartsAt;
        NSInteger len = (omissionEndsAt == NSNotFound) ? (sceneToMove.position + sceneToMove.length) - loc : omissionEndsAt - loc;
        
        range = (NSRange){ loc, len };
        
        string = [_delegate.text substringWithRange:range];
        
        // Add omission markup if needed
        if (omissionStartsAt == NSNotFound) string = [NSString stringWithFormat:@"\n/*\n\n%@", string];
        if (omissionEndsAt == NSNotFound) string = [string stringByAppendingString:@"\n*/\n\n"];
        
        // Normal omitted blocks end with */, so add some line breaks if needed
        if ([[string substringFromIndex:string.length - 2] isEqualToString:@"*/"]) string = [string stringByAppendingString:@"\n\n"];
    }
    
    // Create a new outline before trusting it
    NSArray *outline = [self.delegate getOutlineItems];
    
    // When an item is dropped at the end, its target index will be +1 from the last item
    bool moveToEnd = false;
    if (to >= outline.count) {
        to = outline.count - 1;
        moveToEnd = true;
    }
    
    // Scene before which this scene will be moved, if not moved to the end
    OutlineScene *sceneAfter;
    if (!moveToEnd) sceneAfter = [outline objectAtIndex:to];
    
    NSInteger position = (!moveToEnd) ? sceneAfter.position : _delegate.text.length;
    
    // Add some line breaks if needed
    if (position != 0) {
        Line * lineAtPosition = [_delegate.parser lineAtPosition:position - 1];
        if (lineAtPosition.type != empty) {
            [self addString:@"\n\n" atIndex:position skipAutomaticLineBreaks:true];
            position += 2;
        }
    }
    
    [self moveStringFrom:range to:position actualString:string];
    
    // If needed, add extra line breaks at end
    if (string.length > 0 && [string characterAtIndex:string.length - 1] != '\n') {
        [self addString:@"\n\n" atIndex:position+string.length skipAutomaticLineBreaks:true];
    }
}

- (void)removeTextOnLine:(Line*)line inLocalIndexSet:(NSIndexSet*)indexSet {
    __block NSUInteger offset = 0;
    [indexSet enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
        // Remove beats on any line
        NSRange globalRange = [self globalRangeFromLocalRange:&range inLineAtPosition:line.position];
        [self removeRange:(NSRange){ globalRange.location - offset, globalRange.length }];
        offset += range.length;
    }];
}

#pragma mark - Additional editor convenience stuff

/// Checks if we should add additional line breaks. Returns `true` if line breaks were added.
/// **Warning:** Do **NOT** add a *single* line break here, because you'll end up with an infinite loop.
- (bool)shouldAddLineBreaks:(Line*)currentLine range:(NSRange)affectedCharRange
{
    if (_skipAutomaticLineBreaks) {
        // Some methods can opt out of this behavior. Reset the flag once it's been used.
        _skipAutomaticLineBreaks = false;
        return NO;
    }
    
    // Don't add a dual line break if shift is pressed
    NSUInteger currentIndex = [_delegate.parser indexOfLine:currentLine];
    
    // Handle lines with content
    if (currentLine.string.length > 0 && !(NSEvent.modifierFlags & NSEventModifierFlagShift)) {
        // Add double breaks for outline element lines
        if (currentLine.isOutlineElement || currentLine.isAnyDialogue) {
            [self addString:@"\n\n" atIndex:affectedCharRange.location];
            return YES;
        }
        
        // Action lines need to perform some checks
        else if (currentLine.type == action) {
            // Perform a double-check if there is a next line
            if (currentIndex + 1 < _delegate.parser.lines.count && currentIndex != NSNotFound) {
                Line* nextLine = _delegate.parser.lines[currentIndex + 1];
                if (nextLine.string.length == 0) {
                    // If it *might* be a character cue, skip this behavior.
                    if (currentLine.string.onlyUppercaseUntilParenthesis) return NO;
                    // Otherwise add dual line break
                    [self addString:@"\n\n" atIndex:affectedCharRange.location];
                    return YES;
                }
            } else {
                [self addString:@"\n\n" atIndex:affectedCharRange.location];
                return YES;
            }
        }
    }
    else if (currentLine.string.length == 0) {
        Line *prevLine = [_delegate.parser previousLine:currentLine];
        Line *nextLine = [_delegate.parser nextLine:currentLine];
        
        // Add a line break above and below when writing something in between two dialogue blocks
        if ((prevLine.isDialogueElement || prevLine.isDualDialogueElement) && prevLine.string.length > 0 && nextLine.isAnyCharacter) {
            [self addString:@"\n\n" atIndex:affectedCharRange.location];
            _delegate.getTextView.selectedRange = NSMakeRange(affectedCharRange.location + 1, 0);
            return YES;
        }
    }
    
    return NO;
}

- (bool)shouldJumpOverParentheses:(NSString*)replacementString range:(NSRange)affectedCharRange
{
    // Jump over matched parentheses
    if ([replacementString isEqualToString:@")"] || [replacementString isEqualToString:@"]"]) {
        if (affectedCharRange.location < _delegate.text.length) {
            unichar currentCharacter = [_delegate.text characterAtIndex:affectedCharRange.location];
            if ((currentCharacter == ')' && [replacementString isEqualToString:@")"]) ||
                (currentCharacter == ']' && [replacementString isEqualToString:@"]"])) {
                [_delegate setSelectedRange:NSMakeRange(affectedCharRange.location + 1, 0)];
                return YES;
            }
        }
    }
    
    return NO;
}

- (void)matchParenthesesIn:(NSRange)affectedCharRange string:(NSString*)replacementString
{
    /**
     This method finds a matching closure for parenthesis, notes and omissions.
     It works by checking the entered symbol and if the previous symbol in text
     matches its counterpart (like with *, if the previous is /, terminator is appended.
     */
    
    if (replacementString.length > 1) return;;
    
    static NSDictionary *matches;
    if (matches == nil) matches = @{
        @"(" : @")",
        @"[[" : @"]]",
        @"/*" : @"*/",
        @"<<" : @">>",
        @"{{" : @"}}"
    };
    
    // Find match for the parenthesis symbol
    NSString *match = nil;
    for (NSString* key in matches.allKeys) {
        NSString *lastSymbol = [key substringWithRange:NSMakeRange(key.length - 1, 1)];
        
        if ([replacementString isEqualToString:lastSymbol]) {
            match = key;
            break;
        }
    }
    
    if (matches[match] == nil) {
        // No match for this parenthesis
        return;
    }
    else if (match.length > 1) {
        if (affectedCharRange.location == 0) return;
        
        // Check for dual symbol matches, and don't allow them if the previous character doesn't match
        unichar characterBefore = [_delegate.text characterAtIndex:affectedCharRange.location-1];
        if (characterBefore != [match characterAtIndex:0]) {
            return;
        }
    }
    
    [self addString:matches[match] atIndex:affectedCharRange.location];
    [_delegate setSelectedRange:affectedCharRange];
}

- (BOOL)shouldAddContdIn:(NSRange)affectedCharRange string:(NSString*)replacementString
{
    Line *currentLine = _delegate.currentLine;
    NSInteger lineIndex = [_delegate.parser indexOfLine:currentLine] - 1;
    
    // Don't add CONT'D when not editing this line
    if (!NSLocationInRange(lineIndex, NSMakeRange(0, _delegate.parser.lines.count))) return NO;
        
    NSString *charName = currentLine.characterName;
        
    while (lineIndex > 0) {
        Line * prevLine = _delegate.parser.lines[lineIndex];
        
        // Stop at headings
        if (prevLine.type == heading) break;
        
        if (prevLine.type == character) {
            // Stop if the previous character is not the current one
            if (![prevLine.characterName isEqualToString:charName]) break;
            
            // This is the character. Put in CONT'D and a line break and return NO
            NSString *contd = [BeatUserDefaults.sharedDefaults get:BeatSettingScreenplayItemContd];
            NSString *contdString = [NSString stringWithFormat:@" (%@)\n", contd];
            
            if (![currentLine.string containsString:[NSString stringWithFormat:@"(%@)", contd]]) {
                [self addString:contdString atIndex:currentLine.position + currentLine.length];
                return YES;
            }
        }
        
        lineIndex--;
    }

    return NO;
}


@end
