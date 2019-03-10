//
//  ViewController.m
//  RelayServer-macOS
//
//  Created by Igor Lira on 3/9/19.
//  Copyright © 2019 Igor Lira. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <NSTableViewDataSource>



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 2;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return @"cu";
}

@end
