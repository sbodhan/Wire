//
//  FullPreviewViewController.m
//  Wire
//
//  Created by DetroitLabs on 7/7/16.
//  Copyright © 2016 Srinivas Bodhanampati. All rights reserved.
//

#import "FullPreviewViewController.h"

@interface FullPreviewViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imagePassedImageView;

@end

@implementation FullPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_imagePassedImageView setImage:_imagePassed];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissViewPressed:(id)sender {
    
    [self dismissViewControllerAnimated:TRUE completion:nil];
}


@end
