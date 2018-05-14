#import "VENCalculatorInputTextField.h"
#import "VENMoneyCalculator.h"
#import "UITextField+VENCalculatorInputView.h"

@interface VENCalculatorInputTextField ()
@property (strong, nonatomic) VENMoneyCalculator *moneyCalculator;
@end

@implementation VENCalculatorInputTextField

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpInit];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setUpInit];
}

- (void)setUpInit {
    self.locale = [NSLocale currentLocale];

    VENCalculatorInputView *inputView = [VENCalculatorInputView new];
    inputView.delegate = self;
    inputView.locale = self.locale;
    
    // @sbonilla
    // For the IPhone X, we want to put the calculator within a container view such that we add spacing to the bottom of the view.
    // Otherwise the text field's input view is just the calculator input view.
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone && (NSInteger)UIScreen.mainScreen.nativeBounds.size.height == 2436) {
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, inputView.bounds.size.width, inputView.bounds.size.height + 30.0)];
        containerView.backgroundColor = [inputView numberButtonBackgroundColor];
        [containerView addSubview:inputView];
        self.inputView = containerView;
    }
    else {
        self.inputView = inputView;
    }

    VENMoneyCalculator *moneyCalculator = [VENMoneyCalculator new];
    moneyCalculator.locale = self.locale;
    self.moneyCalculator = moneyCalculator;

    [self addTarget:self action:@selector(venCalculatorTextFieldDidEndEditing) forControlEvents:UIControlEventEditingDidEnd];
}


#pragma mark - Properties

- (void)setLocale:(NSLocale *)locale {
    _locale = locale;
    VENCalculatorInputView *inputView = (VENCalculatorInputView *)self.inputView;
    inputView.locale = locale;
    self.moneyCalculator.locale = locale;
}


#pragma mark - UITextField

- (void)venCalculatorTextFieldDidEndEditing {
    NSString *textToEvaluate = [self trimExpressionString:self.text];
    NSString *evaluatedString = [self.moneyCalculator evaluateExpression:textToEvaluate];
    if (evaluatedString) {
        self.text = evaluatedString;
    }
}


#pragma mark - VENCalculatorInputViewDelegate

- (void)calculatorInputView:(VENCalculatorInputView *)inputView didTapKey:(NSString *)key {
    if ([self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        NSRange range = [self selectedNSRange];
        if (![self.delegate textField:self shouldChangeCharactersInRange:range replacementString:key]) {
            return;
        }
    }

    [self insertText:key];
    NSString *subString = [self.text substringToIndex:self.text.length - 1];
    if ([key isEqualToString:@"+"] ||
        [key isEqualToString:@"−"] ||
        [key isEqualToString:@"×"] ||
        [key isEqualToString:@"÷"]) {
        NSString *evaluatedString = [self.moneyCalculator evaluateExpression:[self trimExpressionString:subString]];
        if (evaluatedString) {
            self.text = [NSString stringWithFormat:@"%@%@", evaluatedString, key];
        } else {
            self.text = subString;
        }
    }
    // @sbonilla
    // Added the `&& [self.text length] > 1` clause to fix crash
    // Crash occurred when entering a decimalSeparator as the first character into a blank field.
    // Caused an out of bounds exception.
    else if ([key isEqualToString:[self decimalSeparator]] && [self.text length] > 1) {
        NSString *secondToLastCharacterString = [self.text substringWithRange:NSMakeRange([self.text length] - 2, 1)];
        if ([secondToLastCharacterString isEqualToString:[self decimalSeparator]]) {
            self.text = subString;
        }
    }
}

- (void)calculatorInputViewDidTapBackspace:(VENCalculatorInputView *)calculatorInputView {
    [self deleteBackward];
}


#pragma mark - Helpers

/**
 Removes any trailing operations and decimals.
 @param expressionString The expression string to trim
 @return The trimmed expression string
 */
- (NSString *)trimExpressionString:(NSString *)expressionString {
    NSString *txt = self.text;
    while ([txt length] > 0) {
        NSString *lastCharacterString = [txt substringFromIndex:[txt length] - 1];
        if ([lastCharacterString isEqualToString:@"+"] ||
            [lastCharacterString isEqualToString:@"−"] ||
            [lastCharacterString isEqualToString:@"×"] ||
            [lastCharacterString isEqualToString:@"÷"] ||
            [lastCharacterString isEqualToString:self.decimalSeparator]) {
            txt = [txt substringToIndex:txt.length - 1];
        }
        else {
            break;
        }
    }
    return txt;
}

- (NSString *)decimalSeparator {
    return [self.locale objectForKey:NSLocaleDecimalSeparator];
}

@end
