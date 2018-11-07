//
//  TableViewController.h
//  MultipeerConnectivity
//
//  Created by Deepal Patel on 07/11/18.
//  Copyright © 2018 Deepal Patel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *textMessage;

@property (strong, nonatomic) IBOutlet UIButton *btnSend;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIButton *source;


@end
