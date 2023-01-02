//
//  BeatEditorDelegate.h
//  
//
//  Created by Lauri-Matti Parppei on 8.4.2021.
//

#import <TargetConditionals.h>
#import "BeatEditorMode.h"

#if TARGET_OS_IOS
    #import <UIKit/UIKit.h>
    #define BXFont UIFont
    #define BXChangeType UIDocumentChangeKind
    #define BXDocTextView BeatUITextView
    #define BXWindow UIWindow
    #define BXPrintInfo UIPrintInfo
#else
    #import <Cocoa/Cocoa.h>
    #define BXFont NSFont
    #define BXChangeType NSDocumentChangeType
    #define BXDocTextView NSTextView
    #define BXWindow NSWindow
    #define BXPrintInfo NSPrintInfo
#endif

#import <BeatParsing/BeatParsing.h>

#if !TARGET_OS_IOS
@class BeatPrintView;
@class BeatPaginator;
#else
@class BeatUITextView;
#endif

@class ContinuousFountainParser;
@class Line;
@class OutlineScene;
@class BeatDocumentSettings;

@protocol BeatEditorView
- (void)reloadInBackground;
- (void)reloadView;
- (bool)visible;
@end

@protocol BeatEditorDelegate <NSObject>

#if !TARGET_OS_IOS
@property (weak, readonly) BXWindow* documentWindow;
@property (nonatomic, readonly) bool typewriterMode;
@property (nonatomic, readonly) bool disableFormatting;
@property (nonatomic, readonly) BeatPaginator *paginator;

// TODO: Remove this when native export is implemented
@property (nonatomic) bool nativeRendering;
#endif

@property (nonatomic, readonly) bool documentIsLoading;

@property (nonatomic, readonly, weak) OutlineScene *currentScene;
@property (nonatomic) bool printSceneNumbers;
@property (nonatomic, readonly) bool showSceneNumberLabels;

@property (nonatomic) BeatPaperSize pageSize;

@property (readonly) ContinuousFountainParser *parser;

@property (nonatomic, readonly) CGFloat magnification;
@property (nonatomic) CGFloat inset;
@property (nonatomic, readonly) CGFloat documentWidth;

@property (nonatomic) NSMutableDictionary *characterGenders;
@property (nonatomic) NSString *revisionColor;
@property (nonatomic) bool revisionMode;
@property (atomic) BeatDocumentSettings *documentSettings;
@property (nonatomic, weak, readonly) BXDocTextView *textView;

@property (nonatomic, readonly) NSUndoManager *undoManager;

@property (readonly, nonatomic) BXFont *courier;
@property (readonly, nonatomic) BXFont *boldCourier;
@property (readonly, nonatomic) BXFont *boldItalicCourier;
@property (readonly, nonatomic) BXFont *italicCourier;

@property (nonatomic, readonly) bool characterInput;
@property (nonatomic) Line* characterInputForLine;

@property (nonatomic, readonly) bool headingStyleBold;
@property (nonatomic, readonly) bool headingStyleUnderline;

@property (nonatomic, readonly) bool showRevisions;
@property (nonatomic, readonly) bool showTags;

@property (strong, nonatomic, readonly) BXFont *sectionFont;
@property (strong, nonatomic, readonly) NSMutableDictionary *sectionFonts;
@property (strong, nonatomic, readonly) BXFont *synopsisFont;

@property (nonatomic) NSInteger mode;
@property (nonatomic, readonly) bool hideFountainMarkup;

@property (atomic) NSAttributedString *attrTextCache;

@property (nonatomic) BeatExportSettings* exportSettings;

#if !TARGET_OS_IOS
@property (strong, nonatomic) NSMutableArray<BeatPrintView*>* printViews;
- (CGFloat)sidebarWidth;
#endif

#if !TARGET_OS_IOS
- (NSPrintInfo*)printInfo;
- (id)document;
- (void)releasePrintDialog;
- (NSAttributedString*)getAttributedText;
#else
- (id)documentForDelegation;
- (UIPrintInfo*)printInfo;
#endif

- (NSString*)fileNameString;

- (void)setPrintSceneNumbers:(bool)value;

- (NSMutableArray*)scenes;
- (NSMutableArray*)getOutlineItems;
- (NSMutableArray<Line*>*)lines;
- (NSString*)text;
- (NSArray*)linesForScene:(OutlineScene*)scene;
- (void)addString:(NSString*)string atIndex:(NSUInteger)index;
- (void)removeString:(NSString*)string atIndex:(NSUInteger)index;
- (void)replaceRange:(NSRange)range withString:(NSString*)newString;
- (void)replaceString:(NSString*)string withString:(NSString*)newString atIndex:(NSUInteger)index;

- (Line*)currentLine;
- (NSInteger)lineTypeAt:(NSInteger)index;

- (void)setSelectedRange:(NSRange)range;
- (NSRange)selectedRange;
- (NSArray*)getOutline; // ???

- (void)moveScene:(OutlineScene*)sceneToMove from:(NSInteger)from to:(NSInteger)to;

- (void)addStoryline:(NSString*)storyline to:(OutlineScene*)scene;
- (void)removeStoryline:(NSString*)storyline from:(OutlineScene*)scene;
- (void)setColor:(NSString *) color forScene:(OutlineScene *) scene;
- (bool)caretAtEnd;

- (bool)isDark;

- (void)showLockStatus;
- (bool)contentLocked;

// This determines if the text has changed since last query
- (bool)hasChanged;
- (NSArray*)markers;

// Check editor mode
- (bool)editorTabVisible;

- (void)updateQuickSettings;

- (void)scrollToLine:(Line*)line;
- (void)scrollToRange:(NSRange)range;
- (void)scrollToRange:(NSRange)range callback:(void (^)(void))callbackBlock;

// Document compatibility
-(void)updateChangeCount:(BXChangeType)change;
-(void)updatePreview;
-(void)forceFormatChangesInRange:(NSRange)range;
- (void)refreshTextViewLayoutElements;
- (void)refreshTextViewLayoutElementsFrom:(NSInteger)location;
- (void)renderBackgroundForLine:(Line*)line clearFirst:(bool)clear;
- (void)renderBackgroundForLines;
- (void)renderBackgroundForRange:(NSRange)range;
- (BXFont*)sectionFontWithSize:(CGFloat)size;

- (void)formatAllLines;

- (void)registerEditorView:(id)view;

- (void)textDidChange:(NSNotification *)notification;
- (void)returnToEditor;
- (void)toggleMode:(BeatEditorMode)mode;
@optional - (IBAction)toggleCards:(id)sender;

#if TARGET_OS_IOS
    - (CGFloat)fontSize;
#endif

@optional - (NSDictionary*)runningPlugins;

@end
/*
 
 tää viesti on varoitus
 tää viesti on
 varoitus
 
 tästä hetkestä
 ikuisuuteen
 tästä hetkestä
 ikuisuuteen
 
 se vaara
 on yhä läsnä
 vaikka me oomme lähteneet
 se vaara on
 yhä läsnä
 
 */
