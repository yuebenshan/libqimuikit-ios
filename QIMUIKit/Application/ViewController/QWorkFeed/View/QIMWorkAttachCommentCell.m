//
//  QIMWorkAttachCommentCell.m
//  QIMUIKit
//
//  Created by lilu on 2019/3/11.
//

#import "QIMWorkAttachCommentCell.h"
#import "QIMWorkMomentLabel.h"
#import "QIMWorkCommentModel.h"
#import "QIMEmotionManager.h"
#import "QIMWorkMomentParser.h"

@interface QIMWorkAttachCommentCell () <QIMAttributedLabelDelegate>

@end

@implementation QIMWorkAttachCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView = nil;
        self.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.selectedBackgroundView = nil;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    
    // 名字视图
    _nameLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, 50, 20)];
    _nameLab.font = [UIFont boldSystemFontOfSize:14.0];
    _nameLab.textColor = [UIColor qim_colorWithHex:0x00CABE];
    _nameLab.backgroundColor = [UIColor clearColor];
    _nameLab.userInteractionEnabled = YES;
    [self.contentView addSubview:_nameLab];
    UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickHead:)];
    [_nameLab addGestureRecognizer:tapGesture2];
    
    //点赞按钮
    _likeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_likeBtn setTitleColor:[UIColor qim_colorWithHex:0x999999] forState:UIControlStateNormal];
    [_likeBtn setTitleColor:[UIColor qim_colorWithHex:0x999999] forState:UIControlStateSelected];
    _likeBtn.layer.cornerRadius = 13.5f;
    _likeBtn.layer.masksToBounds = YES;
    [_likeBtn.titleLabel setFont:[UIFont systemFontOfSize:11]];
    [_likeBtn setImageEdgeInsets:UIEdgeInsetsMake(0.0, -10, 0.0, 0.0)];
    [_likeBtn addTarget:self action:@selector(didLikeComment:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_likeBtn];
    
    // 正文视图
    _contentLabel = [[QIMWorkMomentLabel alloc] init];
    _contentLabel.font = [UIFont systemFontOfSize:14];
    _contentLabel.linesSpacing = 20.0f;
    _contentLabel.delegate = self;
    _contentLabel.textColor = [UIColor qim_colorWithHex:0x333333];
    [self.contentView addSubview:_contentLabel];
}

- (void)setCommentModel:(QIMWorkCommentModel *)commentModel {
    if (commentModel.commentUUID.length <= 0) {
        return;
    }
    _commentModel = commentModel;;
    BOOL isAnonymousComment = commentModel.isAnonymous;
    if (isAnonymousComment == NO) {
        
        //实名评论
        NSString *commentFromUserId = [NSString stringWithFormat:@"%@@%@", commentModel.fromUser, commentModel.fromHost];
        _nameLab.text = [NSString stringWithFormat:@"%@：", [[QIMKit sharedInstance] getUserMarkupNameWithUserId:commentFromUserId]];
        [_nameLab sizeToFit];
    } else {
        //匿名评论
        NSString *anonymousName = commentModel.anonymousName;
        self.nameLab.text = [NSString stringWithFormat:@"%@：", anonymousName];
        self.nameLab.textColor = [UIColor qim_colorWithHex:0x999999];
    }
    CGFloat rowHeight = 0;
    
    BOOL isChildComment = (commentModel.parentCommentUUID.length > 0) ? YES : NO;
    BOOL toisAnonymous = commentModel.toisAnonymous;
    NSString *replayNameStr = @"";
    NSString *replayStr = @"";
    if (isChildComment) {
        if (toisAnonymous) {
            NSString *toAnonymousName = commentModel.toAnonymousName;
            replayNameStr = [NSString stringWithFormat:@"回复%@：", toAnonymousName];
            replayStr = [NSString stringWithFormat:@"[obj type=\"reply\" value=\"%@\"]",replayNameStr];
        } else {
            NSString *toUser = commentModel.toUser;
            NSString *toUserHost = commentModel.toHost;
            if (toUser.length > 0) {
                
            }
            NSString *toUserId = [NSString stringWithFormat:@"%@@%@", toUser, toUserHost];
            NSString *toUserName = [[QIMKit sharedInstance] getUserMarkupNameWithUserId:toUserId];
            replayNameStr = [NSString stringWithFormat:@"回复%@：", toUserName];
            replayStr = [NSString stringWithFormat:@"[obj type=\"reply\" value=\"%@\"]",replayNameStr];
        }
    } else {
        replayNameStr = [NSString stringWithFormat:@""];
    }
    
    NSString *likeString  = [NSString stringWithFormat:@"%@%@", replayStr, commentModel.content];
    _likeBtn.frame = CGRectMake(SCREEN_WIDTH - 70 - self.leftMargin, 0, 60, 15);
    NSInteger likeNum = commentModel.likeNum;
    [_likeBtn setTitle:[NSString stringWithFormat:@"%ld 赞", likeNum] forState:UIControlStateNormal];
    _likeBtn.centerY = self.nameLab.centerY;
    
    QIMMessageModel *msg = [[QIMMessageModel alloc] init];
    msg.message = [[QIMEmotionManager sharedInstance] decodeHtmlUrlForText:likeString];
    msg.messageId = commentModel.commentUUID;
    
    QIMTextContainer *mainTextContainer = [QIMWorkMomentParser textContainerForMessage:msg fromCache:YES withCellWidth:self.likeBtn.left - self.nameLab.left withFontSize:14 withFontColor:[UIColor qim_colorWithHex:0x333333] withNumberOfLines:6];
    CGFloat textH = mainTextContainer.textHeight;
    self.contentLabel.textContainer = mainTextContainer;
    [self.contentLabel setFrameWithOrign:CGPointMake(self.nameLab.left, self.nameLab.bottom + 6) Width:(self.likeBtn.left - self.nameLab.left)];

    _commentModel.rowHeight = _contentLabel.bottom + 12;
}

- (void)didLikeComment:(UIButton *)sender {
    BOOL likeFlag = !sender.selected;
    [[QIMKit sharedInstance] likeRemoteCommentWithCommentId:self.commentModel.commentUUID withSuperParentUUID:self.commentModel.superParentUUID withMomentId:self.commentModel.postUUID withLikeFlag:likeFlag withCallBack:^(NSDictionary *responseDic) {
        if (responseDic.count > 0) {
            NSLog(@"点赞成功");
            BOOL islike = [[responseDic objectForKey:@"isLike"] boolValue];
            NSInteger likeNum = [[responseDic objectForKey:@"likeNum"] integerValue];
            if (islike) {
                sender.selected = YES;
                [sender setTitle:[NSString stringWithFormat:@"%ld", likeNum] forState:UIControlStateSelected];
            } else {
                sender.selected = NO;
                if (likeNum > 0) {
                    [sender setTitle:[NSString stringWithFormat:@"%ld", likeNum] forState:UIControlStateNormal];
                } else {
                    [sender setTitle:@"顶" forState:UIControlStateNormal];
                }
            }
        } else {
            NSLog(@"点赞失败");
        }
    }];
}

// 点击头像
- (void)clickHead:(UITapGestureRecognizer *)gesture {
    if (self.commentModel.isAnonymous == NO) {
        NSString *userId = [NSString stringWithFormat:@"%@@%@", self.commentModel.fromUser, self.commentModel.fromHost];
        [QIMFastEntrance openUserCardVCByUserId:userId];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

// 点击代理
- (void)attributedLabel:(QIMAttributedLabel *)attributedLabel textStorageClicked:(id<QIMTextStorageProtocol>)textStorage atPoint:(CGPoint)point {
    if ([textStorage isMemberOfClass:[QIMLinkTextStorage class]]) {
        QIMLinkTextStorage *storage = (QIMLinkTextStorage *) textStorage;
        if (![storage.linkData length]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"页面有问题" message:@"输入的url有问题" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alertView show];
        } else {
            [QIMFastEntrance openWebViewForUrl:storage.linkData showNavBar:YES];
        }
    } else {
        
    }
}

// 长按代理 有多个状态 begin, changes, end 都会调用,所以需要判断状态
- (void)attributedLabel:(QIMAttributedLabel *)attributedLabel textStorageLongPressed:(id<QIMTextStorageProtocol>)textStorage onState:(UIGestureRecognizerState)state atPoint:(CGPoint)point {
    
}

@end