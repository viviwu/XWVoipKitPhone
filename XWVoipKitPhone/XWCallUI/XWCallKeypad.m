//
//  XWCallKeypad.m
 
#import "XWCallKeypad.h"

@interface XWCallKeypad ()
{
    CGFloat _sWidth;
    CGFloat _sHeight;
}
@property (nonatomic, strong)NSMutableArray * keys;
@end

@implementation XWCallKeypad

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    _sWidth=frame.size.width;
    _sHeight=frame.size.height;
    if (self) {
        _keys=[NSMutableArray array];
    }
    return self;
}

-(void)creatKeys
{
    int j=0;
    
    for (int i=0; i<3; i++) {
        for (int k=0; k<4; k++) {
            j++;
            UIImage *img=_keys[j];
            UIButton * btn =[UIButton buttonWithType:UIButtonTypeCustom];
            [btn setImage:img forState:UIControlStateNormal];
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
