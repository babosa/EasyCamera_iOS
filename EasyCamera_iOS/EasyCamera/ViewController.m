//
//  ViewController.m
//  EasyCapture
//
//  Created by phylony on 9/11/16.
//  Copyright © 2016 phylony. All rights reserved.
//

#import "ViewController.h"
#import "PureLayout.h"
#import "EasySetingViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "EasyResolutionViewController.h"
#import "EasyDarwinInfoViewController.h"
#import <arpa/inet.h>
#import <netdb.h>
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "g711codec.h"
// 音频
#define MIN_SIZE_PER_FRAME 2000 //每侦最小数据长度//penggy:之前2000有点小，会闪退,改为20000
#define QUEUE_BUFFER_SIZE 4 //队列缓冲个数
#define SCREEWIDTH  [UIScreen mainScreen].bounds.size.width
AudioQueueRef audioQueue = NULL;//音频播放队列
AudioQueueBufferRef outQB;//音频缓存
@interface ViewController ()<SetDelegate,EasyResolutionDelegate,ConnectDelegate,NSStreamDelegate>
{
    AudioStreamBasicDescription audioDescription;
    UIButton *startButton;
    UIButton *settingButton;
    NSString *urlName;
    NSString *statusString;
    NSInputStream *_inputStream;//对应输入流
    NSOutputStream *_outputStream;//对应输出流
    NSTimer *timing;
    NSMutableArray *cseqArray;
    int count;
    NSDictionary *pushDict;
    UITextView *logText;
    BOOL isPush;
}
@property(nonatomic, retain)NSTimer *connectTimer;
@property(nonatomic, strong)NSMutableArray *logInfoArray;
static void AudioPlayerAQInputCallback(void *input, AudioQueueRef inQ, AudioQueueBufferRef outQBs);
@end

@implementation ViewController

- (void)setFinish{
     [self connectToHost:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    cseqArray = [[NSMutableArray alloc] init];
    encoder = [[CameraEncoder alloc] init];
    encoder.delegate = self;
    [encoder initCameraWithOutputSize:CGSizeMake(480, 640)];
    
    encoder.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:encoder.previewLayer];
    AVCaptureVideoPreviewLayer *prev = encoder.previewLayer;
    [[prev connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    prev.frame = self.view.bounds;
    encoder.previewLayer.hidden = NO;
    [encoder startCapture];
    
//    startButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    startButton.translatesAutoresizingMaskIntoConstraints = NO;
////    [self.view addSubview:startButton];
//    [startButton setTitle:@"开始推流" forState:UIControlStateNormal];
//    [startButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20.0];
//    [startButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0.0];
//    [startButton autoSetDimension:ALDimensionWidth toSize:80];
//    [startButton autoSetDimension:ALDimensionHeight toSize:40];
//    startButton.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
//    [startButton addTarget:self action:@selector(startAction:) forControlEvents:UIControlEventTouchUpInside];
    
    settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    settingButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:settingButton];
    [settingButton setTitle:@"设置" forState:UIControlStateNormal];
    [settingButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:55];
    [settingButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:22.0];
    [settingButton autoSetDimension:ALDimensionWidth toSize:35];
    [settingButton autoSetDimension:ALDimensionHeight toSize:35];
//    settingButton.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
    [settingButton addTarget:self action:@selector(settingAction:) forControlEvents:UIControlEventTouchUpInside];
    [settingButton setImage:[UIImage imageNamed:@"video_record_set_off_press" ]forState:UIControlStateNormal];
    
    UIButton *changeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    changeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:changeButton];
    [changeButton setTitle:@"切换" forState:UIControlStateNormal];
    [changeButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:settingButton withOffset:-10.0];
    [changeButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20.0];
    [changeButton autoSetDimension:ALDimensionWidth toSize:46];
    [changeButton autoSetDimension:ALDimensionHeight toSize:43];
//    changeButton.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
    [changeButton addTarget:self action:@selector(toggleCamera) forControlEvents:UIControlEventTouchUpInside];
    [changeButton setImage:[UIImage imageNamed:@"icn_change_view_pressed" ]forState:UIControlStateNormal];
    
    UIButton *resolutionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    resolutionBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:resolutionBtn];
    resolutionBtn.tag = 100001;
    [resolutionBtn setTitle:@"分辨率:640*480" forState:UIControlStateNormal];
    [resolutionBtn autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:10];
    [resolutionBtn autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20.0];
    [resolutionBtn autoSetDimension:ALDimensionWidth toSize:180];
    [resolutionBtn autoSetDimension:ALDimensionHeight toSize:30];
    //    resolutionBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    [resolutionBtn addTarget:self action:@selector(showPop) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    infoBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:infoBtn];
    [infoBtn setImage:[UIImage imageNamed:@"ic_action_about"] forState:UIControlStateNormal];
    
    [infoBtn autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
    [infoBtn autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:23.0];
    [infoBtn autoSetDimension:ALDimensionWidth toSize:30];
    [infoBtn autoSetDimension:ALDimensionHeight toSize:30];
    [infoBtn addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
    
    logText = [[UITextView alloc] init];
    logText.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:logText];
    [logText autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0];
    [logText autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:5.0];
//    [logText autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20.0];
    [logText autoSetDimension:ALDimensionHeight toSize:200.0];
    [logText autoSetDimension:ALDimensionWidth toSize:SCREEWIDTH - 10];
    logText.font = [UIFont systemFontOfSize:8.0f];
    logText.backgroundColor = [UIColor clearColor];
//    logText.scrollsToTop = NO;
    logText.showsVerticalScrollIndicator = NO;
    logText.showsHorizontalScrollIndicator = NO;
    logText.editable = NO;
    logText.userInteractionEnabled = NO;
    [self.view addSubview:logText];
    
    
//    UILabel *urlLabel = [[UILabel alloc] init];
//    urlLabel.translatesAutoresizingMaskIntoConstraints = NO;
//    urlLabel.tag = 3000;
//    urlLabel.textColor = [UIColor redColor];
//    urlLabel.numberOfLines = 0;
//    urlLabel.text = statusString;
////    [self.view addSubview:urlLabel];
//    
//    [urlLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:startButton withOffset:-10.0];
//    [urlLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20.0];
//    [urlLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20.0];
    [self connectToHost:nil];
}

- (NSMutableArray *)logInfoArray{
    if (!_logInfoArray) {
        _logInfoArray = [[NSMutableArray alloc] init];
    }
    return _logInfoArray;
}

- (void)showInfo{
    EasyDarwinInfoViewController *infoVc = [[EasyDarwinInfoViewController alloc] init];
    [self presentViewController:infoVc animated:YES completion:nil];
}

- (void)showPop{
    if (encoder.running) {
        return;
    }
    EasyResolutionViewController *popVc = [[EasyResolutionViewController alloc] init];
    popVc.delegate = self;
    popVc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:popVc animated:YES completion:nil];
}

- (void)onSelecedesolution:(NSInteger)resolutionNo{
    [encoder swapResolution];
    UIButton *resolutionBtn = (UIButton *)[self.view viewWithTag:100001];
    [resolutionBtn setTitle:[NSString stringWithFormat:@"分辨率:%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"resolition"]] forState:UIControlStateNormal];
}

- (void)toggleCamera{
    [encoder swapFrontAndBackCameras];
}

- (IBAction)startAction:(id)sender
{
    if (!encoder.running)
    {
        
        [startButton setTitle:@"停止推流" forState:UIControlStateNormal];
        NSMutableString *randomNum = [[NSMutableString alloc] init];
        for(int i = 0; i < 6;i++){
            int num = arc4random() % 10;
            [randomNum appendString:[NSString stringWithFormat:@"%d",num]];
        }
        [randomNum appendString:@".sdp"];
        urlName = [randomNum copy];
        
        [encoder startCamera:urlName];
    }
    else
    {
        [startButton setTitle:@"开始推流" forState:UIControlStateNormal];
        [encoder stopCamera];
    }
}

- (void)getConnectStatus:(NSString *)status isFist:(int)tag{
    if ([status isEqualToString:@"推流中"] && !isPush) {
        isPush = YES;
       [self startPushStream:pushDict];
    }
//    __block UILabel *label = (UILabel *)[self.view viewWithTag:3000];
//    if (tag == 1) {
//        if (label) {
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    label.text = [NSString stringWithFormat:@"%@",status];
//                });
//            });
//        }else{
//            statusString = status;
//        }
//    }else{
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                label.text = [NSString stringWithFormat:@"%@\nrtsp://%@:%@/%@",status,[[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigIP"],[[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigPORT"],urlName];
//            });
//        });
//    }
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    NSString *message;
    NSArray *defaultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultConfig"];
    
    NSString *host = defaultArray[0];
    int port = [defaultArray[1] intValue];
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
        {
            message = [NSString stringWithFormat:@"Connect server[%@:%d] success\n",host,port];
        }
            break;
        case NSStreamEventHasBytesAvailable:
        {
//            message = @"有字节可读\n";
            [self readData];
        }
            break;
        case NSStreamEventHasSpaceAvailable:
        {
//            message = @"可以发送字节\n";
            //添加心跳包
            if (![self.connectTimer isValid]) {
                self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:28
                                     
                                                                     target:self selector:@selector(registerEasyCamera)
                                                                   userInfo:nil repeats:YES];
                [self.connectTimer fire];
            }
            
        }
            break;
        case NSStreamEventErrorOccurred:
        {
             message = [NSString stringWithFormat:@"Connect server[%@:%d] error\n",host,port];
            [_inputStream close];
            [_outputStream close];
            [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//            NSError * error = [aStream streamError];
//            NSString * errorInfo = [NSString stringWithFormat:@"Failed while reading stream; error '%@' (code %zd)", error.localizedDescription, error.code];
//            NSLog(@"%@",errorInfo);
        }
            break;
        case NSStreamEventEndEncountered:
        {
//            NSLog(@"连接结束");
            message = [NSString stringWithFormat:@"Connect server[%@:%d] end\n",host,port];
            [_inputStream close];
            [_outputStream close];
            [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        }
            break;
        default:
            break;
    }
    [self showLogInfo:message];
}

- (void)showLogInfo:(NSString*)message{
    if (!message) {
        return;
    }
    [self.logInfoArray addObject:message];
    if (self.logInfoArray.count > 20) {
        [self.logInfoArray removeObjectAtIndex:0];
    }
    
    NSMutableAttributedString* attributedString = [NSMutableAttributedString new];
    for (NSString* log in self.logInfoArray) {
        NSMutableAttributedString* logString = [[NSMutableAttributedString alloc] initWithString:log];
        [logString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, logString.length)];
        [logString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:9.0] range:NSMakeRange(0, logString.length)];
        [attributedString appendAttributedString:logString];
    }
    logText.attributedText = nil;
    logText.attributedText = attributedString;
    
    // scroll to bottom
    if(attributedString.length > 0) {
        NSRange bottom = NSMakeRange(attributedString.length - 1, 1);
        [logText scrollRangeToVisible:bottom];
    }
}

//注册以及心跳
- (void)registerEasyCamera {
    count ++;
    [cseqArray addObject:[NSNumber numberWithInt:count]];
    if (count % 3 == 0) {
        [self savescreenshot];
        return;
    }
    NSArray *defaultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultConfig"];
    NSString *jsonString = [NSString stringWithFormat:@"{\n\"EasyDarwin\": {\n\"Body\": {\n\"Name\": \"%@\",\n\"Serial\": \"%@\",\n\"Tag\": \"%@\",\n\"Token\": \"%@\"\n},\n\"Header\": {\n\"AppType\": \"EasyCamera\",\n\"CSeq\": \"%d\",\n\"MessageType\": \"MSG_DS_REGISTER_REQ\",\n\"TerminalType\": \"iOS\",\n\"Version\": \"1.0\"\n}\n}\n}",defaultArray[3],defaultArray[2],@"iOS",@"000000",count];
    
    NSData *data = [[self apendHttpHeader:jsonString] dataUsingEncoding:NSUTF8StringEncoding];
    [_outputStream write:data.bytes maxLength:data.length];

    NSString *host = defaultArray[0];
    int port = [defaultArray[1] intValue];
    NSString *info =[NSString stringWithFormat:@"Send MSG_DS_REGISTER_REQ %@ [%@:%d]\n",defaultArray[2],host,port];
    [self showLogInfo:info];
}

- (NSString *)apendHttpHeader:(NSString *)body{
    NSString *postString = [NSString stringWithFormat:@"POST / HTTP/1.1\r\nUser-Agent:iOS device\r\nConnection: Keep-Alive\r\nContent-Length: %zd\r\n\r\n%@",body.length,body];
    return postString;
}

- (void)savescreenshot{
    NSArray *defaultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultConfig"];
    NSData *imageData = UIImageJPEGRepresentation(encoder.screenShotImage, 0.3);
    NSString *jsonString = [NSString stringWithFormat:@"{\n\"EasyDarwin\": {\n\"Body\": {\n\"Image\": \"%@\",\n\"Serial\": \"%@\",\n\"Time\": \"%@\",\n\"Type\": \"%@\"\n},\n\"Header\": {\n\"AppType\": \"EasyCamera\",\n\"CSeq\": \"%d\",\n\"MessageType\": \"MSG_DS_POST_SNAP_REQ\",\n\"TerminalType\": \"iOS\",\n\"Version\": \"1.0\"\n}\n}\n}",[imageData base64EncodedStringWithOptions:0],defaultArray[2],@"000000",@"JPEG",count];
     NSData *data = [[self apendHttpHeader:jsonString] dataUsingEncoding:NSUTF8StringEncoding];
    [_outputStream write:data.bytes maxLength:data.length];
    NSString *info = @"Recv MSG_DS_POST_SNAP_ACK\n";
    [self showLogInfo:info];
}

- (void)startPushStream:(NSDictionary *)severDict{
    NSDictionary *postDict = @{@"EasyDarwin":@{
                               @"Body":@{
                                       @"Channel":severDict[@"Body"][@"Channel"],
                                       @"From":severDict[@"Body"][@"To"],
                                       @"Reserve":severDict[@"Body"][@"Reserve"],
                                       @"Serial":severDict[@"Body"][@"Serial"],
                                       @"Server_IP":severDict[@"Body"][@"Server_IP"],
                                       @"Server_PORT":severDict[@"Body"][@"Server_PORT"],
                                       @"To":severDict[@"Body"][@"From"],
                                       @"Via":severDict[@"Body"][@"Via"]
                                       },
                               @"Header":@{
                                       @"CSeq":severDict[@"Header"][@"CSeq"],
                                       @"MessageType":@"MSG_DS_PUSH_STREAM_ACK",
                                       @"Version":severDict[@"Header"][@"Version"],
                                       @"ErrorNum":@"200",
                                       @"ErrorString":@"Success OK"
                                       }
    }
                               };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSData *data = [[self apendHttpHeader:jsonString] dataUsingEncoding:NSUTF8StringEncoding];
    [_outputStream write:data.bytes maxLength:data.length];
    
}


#pragma mark 读了服务器返回的数据
-(void)readData{

    //建立一个缓冲区 可以放1024个字节
    uint8_t buf[32768];
    // 返回实际装的字节数
    NSInteger len = [_inputStream read:buf maxLength:sizeof(buf)];
    if (len < 1) {
        return;
    }
    // 把字节数组转化成字符串
    NSData *data = [NSData dataWithBytes:buf length:len];
    // 从服务器接收到的数据
    NSString *recStr =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *recArray = [recStr componentsSeparatedByString:@" "];
    if (recArray.count > 1 && [recArray[1] intValue] == 200) {
        NSString *jsonStr = [recStr substringFromIndex:[recStr rangeOfString:@"{"].location];
        //NSLog(@"%@",[recStr substringFromIndex:[recStr rangeOfString:@"{"].location]);
        NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tempDictReceive = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        [self analysisJson:tempDictReceive];
    }else if (recArray.count > 1 && [recArray[1] intValue] != 200){
        if ([recStr containsString:@"{"]) {
            NSString *jsonStr = [recStr substringFromIndex:[recStr rangeOfString:@"{"].location];
            //NSLog(@"%@",[recStr substringFromIndex:[recStr rangeOfString:@"{"].location]);
            NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *tempDictReceive = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
            [self analysisFailJson:tempDictReceive];
        }else{
            NSArray *jsonStr = [recStr componentsSeparatedByString:@"\n"];
            [self showLogInfo:jsonStr[0]];
        }
       
    }
    
 
    //         [self reloadDataWithText:recStr];
}

- (void)analysisFailJson:(NSDictionary *)dict{
    NSDictionary *responseDict = dict[@"EasyDarwin"];
    NSDictionary *headerDict = responseDict[@"Header"];
    //int tag = [headerDict[@"ErrorNum"] intValue];
//    NSDictionary *bodyDict = responseDict[@"Body"];
    NSString *info;
    NSString *messageType = headerDict[@"MessageType"];
    if ([messageType isEqualToString:@"MSG_DS_REGISTER_ACK"]) {
        info = @"Recv MSG_DS_REGISTER_ACK Fail";
    }else if ([messageType isEqualToString:@"MSG_DS_POST_SNAP_ACK"]){
        info = [NSString stringWithFormat:@"Recv MSG_DS_POST_SNAP_ACK ErrorNum=%d",[headerDict[@"ErrorNum"] intValue]];
    }
    [self showLogInfo:info];
}

- (void)analysisJson:(NSDictionary *)dict{
    NSDictionary *responseDict = dict[@"EasyDarwin"];
    NSDictionary *headerDict = responseDict[@"Header"];
    //int tag = [headerDict[@"ErrorNum"] intValue];
    NSDictionary *bodyDict = responseDict[@"Body"];
    NSString *info;
    NSNumber *seq =[NSNumber numberWithInt:[headerDict[@"CSeq"] intValue]];
    if ([cseqArray containsObject:seq]) {
        if ([seq intValue] == 1) {
            [self savescreenshot];
        }else{
            info = @"Recv MSG_DS_REGISTER_ACK\n";
        }
    }else{
        NSString *messageType = headerDict[@"MessageType"];
        if ([messageType isEqualToString:@"MSG_SD_PUSH_STREAM_REQ"]) {
            isPush = NO;
            [[NSUserDefaults standardUserDefaults] setObject:bodyDict[@"Server_IP"] forKey:@"ConfigIP"];
            [[NSUserDefaults standardUserDefaults] setObject:bodyDict[@"Server_PORT"] forKey:@"ConfigPORT"];
            pushDict = responseDict;
            info = [NSString stringWithFormat:@"Recv MSG_SD_PUSH_STREAM_REQ RTSP [%@:%@]\n",bodyDict[@"Server_IP"],bodyDict[@"Server_PORT"]];
            [encoder startCamera:bodyDict[@"Serial"]];
            // [self startPushStream:responseDict];
            
        }else if ([messageType isEqualToString:@"MSG_SD_STREAM_STOP_REQ"]){
            [encoder stopCamera];
            info = @"Recv MSG_SD_STREAM_STOP_REQ\n";
            [self stopPushStream:responseDict];
        }else if ([messageType isEqualToString:@"MSG_SD_CONTROL_TALKBACK_REQ"]){
            NSString *cmdString = responseDict[@"Body"][@"Command"];
            if ([cmdString isEqualToString:@"SENDDATA"]) {
                [self playAudio:responseDict[@"Body"][@"AudioData"]];
            }else if ([cmdString isEqualToString:@"START"]){
                [self initAudio];
                info = @"Recv MSG_SD_CONTROL_TALKBACK_REQ START\n";
            }else if ([cmdString isEqualToString:@"STOP"]) {
                [self stopAudio];
                info = @"Recv MSG_SD_CONTROL_TALKBACK_REQ STOP\n";
            }
            [self talkBackAck:responseDict];
        }
    }
    [self showLogInfo:info];
    
    [cseqArray removeObject:seq];
}

- (void)stopAudio{
    AudioQueueStop(audioQueue, YES);//停止
    AudioQueueDispose(audioQueue, YES);//移除缓冲区,true代表立即结束录制，false代表将缓冲区处理完再结束
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)playAudio:(NSString *)base64String{
    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
   
    char buffer[8000] = {0};
    //int size = PCM2G711a((char*)[nsdataFromBase64String bytes], buffer, (int)nsdataFromBase64String.length, 0);
   int size = G711a2PCM((char*)[nsdataFromBase64String bytes],buffer,(int)nsdataFromBase64String.length,0);
    if (size <= 0) {
        return;
    }
    memset(outQB->mAudioData,0,MIN_SIZE_PER_FRAME);
    outQB->mAudioDataByteSize = size;
    memcpy(outQB->mAudioData,buffer,outQB->mAudioDataByteSize);
    AudioQueueEnqueueBuffer(audioQueue, outQB, 0, NULL);
}

static void AudioPlayerAQInputCallback(void *input, AudioQueueRef outQ, AudioQueueBufferRef outQBs)
{
    NSLog(@"AudioPlayerAQInputCallback");
//    AudioQueueEnqueueBuffer(outQ,outQBs,0,NULL);
}

- (void)talkBackAck:(NSDictionary *)severDict{
    NSDictionary *postDict = @{@"EasyDarwin":@{
                                       @"Body":@{
                                               @"Channel":severDict[@"Body"][@"Channel"],
                                               @"From":severDict[@"Body"][@"To"],
                                               @"Reserve":severDict[@"Body"][@"Reserve"],
                                               @"Serial":severDict[@"Body"][@"Serial"],
                                               
                                               @"To":severDict[@"Body"][@"From"],
                                               @"Via":severDict[@"Body"][@"Via"],
                                               @"Protocol":severDict[@"Body"][@"Protocol"]
                                               },
                                       @"Header":@{
                                               @"CSeq":severDict[@"Header"][@"CSeq"],
                                               @"MessageType":@"MSG_DS_CONTROL_TALKBACK_ACK",
                                               @"Version":severDict[@"Header"][@"Version"],
                                               @"ErrorNum":@"200",
                                               @"ErrorString":@"Success OK"
                                               }
                                       }
                               };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSData *data = [[self apendHttpHeader:jsonString] dataUsingEncoding:NSUTF8StringEncoding];
    [_outputStream write:data.bytes maxLength:data.length];
    NSString *info = @"Send MSG_DS_CONTROL_TALKBACK_ACK\n";
    [self showLogInfo:info];

}

- (void)stopPushStream:(NSDictionary *)severDict{
    NSDictionary *postDict = @{@"EasyDarwin":@{
                               @"Body":@{
                                       @"Channel":severDict[@"Body"][@"Channel"],
                                       @"From":severDict[@"Body"][@"To"],
                                       @"Reserve":severDict[@"Body"][@"Reserve"],
                                       @"Serial":severDict[@"Body"][@"Serial"],
                                    
                                       @"To":severDict[@"Body"][@"From"],
                                       @"Via":severDict[@"Body"][@"Via"]
                                       },
                               @"Header":@{
                                       @"CSeq":severDict[@"Header"][@"CSeq"],
                                       @"MessageType":@"MSG_DS_STREAM_STOP_ACK",
                                       @"Version":severDict[@"Header"][@"Version"],
                                       @"ErrorNum":@"200",
                                       @"ErrorString":@"Success OK"
                                       }
                               }
                               };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:postDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSData *data = [[self apendHttpHeader:jsonString] dataUsingEncoding:NSUTF8StringEncoding];
    [_outputStream write:data.bytes maxLength:data.length];
    NSString *info = @"Send MSG_SD_STREAM_STOP_ACK\n";
    [self showLogInfo:info];
    
}



-(IBAction)connectToHost:(id)sender {
    NSArray *defaultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultConfig"];
    // 1.建立连接
    NSString *host = defaultArray[0];
    int port = [defaultArray[1] intValue];
    // 定义C语言输入输出流
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);

    _inputStream = (__bridge NSInputStream *)(readStream);
    _outputStream = (__bridge NSOutputStream *)(writeStream);
    // 设置代理
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    // 把输入输入流添加到主运行循环
    // 不添加主运行循环 代理有可能不工作
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    // 打开输入输出流
    [_inputStream open];
    [_outputStream open];
    CFRelease(readStream);
    CFRelease(writeStream);
}

void destroyAudio()
{
    if(audioQueue){
        AudioQueueStop(audioQueue, YES);
        AudioQueueFreeBuffer(audioQueue, outQB);
        AudioQueueDispose(audioQueue, YES);
        audioQueue = NULL;
    }
}

-(void)initAudio
{
    ///设置音频参数
    NSError *audioSessionError;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&audioSessionError];
    if(audioSessionError)
    {
        NSLog(@"AVAudioSession error setting category:%@",audioSessionError);
    }
    [audioSession setActive:YES error:&audioSessionError];
    if(audioSessionError){
        NSLog(@"AVAudioSession error activating: %@",audioSessionError);
    }
    
    audioDescription.mSampleRate = 44100;//采样率
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioDescription.mChannelsPerFrame = 2;///单声道
    audioDescription.mFramesPerPacket = 1;//每一个packet一侦数据
    audioDescription.mBitsPerChannel = 16;//每个采样点16bit量化
    audioDescription.mBytesPerFrame = (audioDescription.mBitsPerChannel/8) * audioDescription.mChannelsPerFrame;
    audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame ;
    OSStatus err = AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)(self), nil, nil, 0, &audioQueue);//使用player的内部线程播
    if(err != noErr){
        NSLog(@"AudioQueueNewOutput 不成功");
    }
    
    UInt32 val = kAudioQueueHardwareCodecPolicy_PreferSoftware;//在软解码不可用的情况下用硬解码
    err = AudioQueueSetProperty(audioQueue, kAudioQueueProperty_HardwareCodecPolicy, &val, sizeof(UInt32));
    
    err = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &outQB);
    if(err != noErr){
        NSLog(@"AudioQueueAllocateBuffer 不成功");
        AudioQueueDispose(audioQueue, TRUE);
        audioQueue = NULL;
    }
    
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    err = AudioQueueStart(audioQueue, NULL);
    if(err != noErr){
        destroyAudio();
        NSLog(@"音频播放失败, err = %d",(int)err);
    }
}


- (IBAction)settingAction:(id)sender
{
//    [startButton setTitle:@"开始推流" forState:UIControlStateNormal];
    [_inputStream close];
    [_outputStream close];
    [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [encoder stopCamera];
    EasySetingViewController *setVc = [[EasySetingViewController alloc] init];
    setVc.delegate = self;
    [self presentViewController:setVc animated:YES completion:nil];
}

- (void)dealloc{

    [_inputStream close];
    [_outputStream close];
    [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_connectTimer invalidate];
    _connectTimer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
