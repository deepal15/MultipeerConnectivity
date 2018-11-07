//
//  TableViewCell.h
//  MultipeerConnectivity
//
//  Created by Deepal Patel on 07/11/18.
//  Copyright © 2018 Deepal Patel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *lblMessage;

@property (strong, nonatomic) IBOutlet UILabel *lblFrom;

@end
