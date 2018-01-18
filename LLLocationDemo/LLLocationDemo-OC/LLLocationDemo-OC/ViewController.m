//
//  ViewController.m
//  LLLocationDemo-OC
//
//  Created by lijunliang on 2017/12/5.
//  Copyright © 2017年 Kila. All rights reserved.
//

#import "ViewController.h"
#import "LLLocation/LLLocation-Swift.h"

@interface ViewController ()
@property (nonatomic, strong) LLLocationManager *manager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.manager = [[LLLocationManager alloc] init];
    [self.manager start];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
