//
//  EasySetingViewController.m
//  EasyPusher
//
//  Created by yingengyue on 2017/1/10.
//  Copyright © 2017年 phylony. All rights reserved.
//

#import "EasySetingViewController.h"

@interface EasySetingViewController ()<UITextFieldDelegate>

@end

@implementation EasySetingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
//    UITextField *ipTextField = [[UITextField alloc] initWithFrame:CGRectMake(80, 64, 200.0, 30.0)];
//    ipTextField.tag = 1000;
//    ipTextField.delegate = self;
//    ipTextField.placeholder = @"EasyCMS IP";
//    ipTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigIP"];
//    [self.view addSubview:ipTextField];
//    
//    UITextField *portTextField = [[UITextField alloc] initWithFrame:CGRectMake(80, 104, 200.0, 30.0)];
//    portTextField.tag = 1001;
//    portTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"ConfigPORT"];
//    portTextField.delegate = self;
//    portTextField.placeholder = @"EasyCMS Port";
//    [self.view addSubview:portTextField];

    NSArray *placeArray = @[@"EasyCMS IP",@"EasyCMS Port",@"Device Serial",@"Device Name",@"Device Token",@"Device Tag",@"Keep Alive Interval"];
    NSArray *defaultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultConfig"];
    for (int i = 0; i < placeArray.count; i ++) {
        UITextField *text = [[UITextField alloc] initWithFrame:CGRectMake(20, 64 + 40*i, [UIScreen mainScreen].bounds.size.width - 40, 30.0)];
        text.placeholder = placeArray[i];
        text.text = defaultArray[i];
        text.delegate = self;
        text.tag = 10000 + i;
        [self.view addSubview:text];
    }
    
    UIButton *saveBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 64 + 40 * placeArray.count, [UIScreen mainScreen].bounds.size.width - 40, 40.0)];
    saveBtn.backgroundColor = [UIColor lightGrayColor];
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(saveIpAndPort) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveBtn];
    
    
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 50, 25, 40, 40)];
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
}

- (void)close:(UIButton *)sender{
    __weak typeof(self) weakSelf = self;
    UIAlertController *alt = [UIAlertController alertControllerWithTitle:nil message:@"未保存修改，是否退出设置" preferredStyle:UIAlertControllerStyleAlert];
    [alt addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         [weakSelf.delegate setFinish];
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alt addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [self presentViewController:alt animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)saveIpAndPort{
    [self.view endEditing:YES];
//    UITextField *ipConfig = (UITextField *)[self.view viewWithTag:1000];
//    UITextField *portConfig = (UITextField *)[self.view viewWithTag:1001];
    __weak typeof(self) weakSelf = self;
    NSArray *defaultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultConfig"];
    NSMutableArray *defaultArrayMu = [[NSMutableArray alloc] initWithArray:defaultArray];
    for (int i = 0; i < 7; i++) {
        UITextField *text = (UITextField *)[self.view viewWithTag:10000 + i];
        if (![text.text isEqualToString:@""]) {
            [defaultArrayMu replaceObjectAtIndex:i withObject:text.text];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:defaultArrayMu forKey:@"defaultConfig"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf.delegate setFinish];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
