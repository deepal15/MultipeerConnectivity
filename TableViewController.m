//
//  TableViewController.m
//  MultipeerConnectivity
//
//  Created by Deepal Patel on 07/11/18.
//  Copyright © 2018 Deepal Patel. All rights reserved.
//

#import "TableViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "MessageCell.h"
#import "ProgressCell.h"
#import "ImageCell.h"
#define kSessionService @"Room"
#import "AppDelegate.h"


@interface TableViewController () <MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSStreamDelegate>

@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCPeerID *peerId;
@property (strong, nonatomic) NSMutableArray *arrayForTable;
@property (strong, nonatomic) NSMutableDictionary *dictionary;
@property (strong, nonatomic) NSProgress *progress;
@property (strong, nonatomic) ProgressCell *cell;
@property (strong, nonatomic) NSString *token;
@end

@implementation TableViewController


- (void)viewDidLoad {
    
    self.arrayForTable = [[NSMutableArray alloc] init];
    self.dictionary = [[NSMutableDictionary alloc] init];
    if (@available(iOS 11.0, *)) {
        [self.tableView contentInsetAdjustmentBehavior];
    } else {
        [self setAutomaticallyAdjustsScrollViewInsets:YES];
    }
    
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self.textMessage setDelegate:self];
    [self.btnSend addTarget:self action:@selector(messageToSession) forControlEvents:UIControlEventTouchUpInside];
    [self.source addTarget:self action:@selector(postNSData) forControlEvents:UIControlEventTouchUpInside];
    
    [super viewDidLoad];
    
    [self createSession];
    [self startBrowsing];
    [self startAdvertising];
    
}

- (void)createSession
{
    SecIdentityRef secRef = [self makeCertificate];
    self.peerId = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice]name]];
    self.session = [[MCSession alloc] initWithPeer:self.peerId securityIdentity:nil encryptionPreference:MCEncryptionNone];
    
    self.peerId = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice]name]];
    self.session = [[MCSession alloc] initWithPeer:self.peerId securityIdentity:[NSArray arrayWithObject:(__bridge id)(secRef)] encryptionPreference:MCEncryptionNone];
}


- (void)startBrowsing
{
    self.browser = [[MCNearbyServiceBrowser alloc]initWithPeer:self.peerId serviceType:kSessionService];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
}


#pragma mark - Browser delegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary<NSString *,NSString *> *)info
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.session setDelegate:self];
        [self.browser invitePeer:peerID toSession:self.session withContext:nil timeout:10];
        NSLog(@"\n\n_________\n Invitation send");
    });
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"\n\n__________\n Lost Peer : %@", peerID);
    });
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"\n\n__________\n Browser did not start : %@", [error localizedDescription]);
}


#pragma mark - Advertiser delegate

- (void)startAdvertising
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc]init];
    
    [dictionary setValue:@"User1" forKey:@"user"];
    self.advertiser = [[MCNearbyServiceAdvertiser alloc]initWithPeer:self.peerId discoveryInfo:dictionary serviceType:kSessionService];
    self.advertiser.delegate = self;
    [self.advertiser startAdvertisingPeer];
}


- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nullable))invitationHandler
{
    invitationHandler(YES, self.session);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"\n\n__________\n Received invitation from Peer : %@", peerID);
    });

}


- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"\n\n__________\n Advertiser did not start : %@", [error localizedDescription]);
}


#pragma mark - Session delegate


- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (state == MCSessionStateConnected)
        {
            NSLog(@"\n\n Connected....");
        }
        else if (state == MCSessionStateConnecting)
        {
            NSLog(@"\n\n Connecting....");
        }
        else if (state == MCSessionStateNotConnected)
        {
            NSLog(@"\n\n Not Connected....");
        }
    });
}


- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSString *receivedData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
    });
    self.dictionary = [NSMutableDictionary new];
    [self.dictionary setObject:receivedData forKey:@"postData"];
    [self.dictionary setObject:[peerID displayName] forKey:@"from"];
    [self.dictionary setObject:@"text" forKey:@"type"];
    [self.arrayForTable addObject:self.dictionary];
    NSLog(@"\n\n__________\n Received data : %@", receivedData);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.arrayForTable count]-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
}


- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler {
    NSLog(@"\n\n_________\n Received certificate from PeerId %@", peerID);
    certificateHandler(YES);
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    NSLog(@"\n\n %f**********", [progress fractionCompleted]);
    self.dictionary = [NSMutableDictionary new];
    [self.dictionary setObject:@"progress" forKey:@"type"];
    [self.arrayForTable addObject:self.dictionary];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
    [progress addObserver:self forKeyPath:@"cancelled" options:NSKeyValueObservingOptionNew context:NULL];
    [progress addObserver:self forKeyPath:@"completedUnitCount" options:NSKeyValueObservingOptionNew context:NULL];
}




- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
    [self.arrayForTable removeLastObject];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *copyPath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], resourceName];
    if (![[NSFileManager defaultManager] copyItemAtPath:[localURL path] toPath:copyPath error:nil])
    {
        NSLog(@"%@", [error localizedDescription]);
    }
    else {
        // Get a URL for the path we just copied the resource to
        [self reloadAtcurrectSessionIndexPathWithName:[peerID displayName] withReceivedData:copyPath type:@"data"];
        
        
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    [aStream open];
    
    NSLog(@"%@", aStream);
}


- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    stream.delegate = self;
    [stream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [stream open];
    
}


#pragma mark - UITextFieldDelegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

#pragma mark - UIButton delegate

- (void)messageToSession {
    
    NSError *error;
    NSString *data = [self.textMessage text];
    NSData *postData = [data dataUsingEncoding:NSUTF8StringEncoding];
    [self.session sendData:postData toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    [self reloadAtcurrectSessionIndexPathWithName:[[UIDevice currentDevice] name] withReceivedData:self.textMessage.text type:@"text"];
    
    
    [self.textMessage setText:@""];
    [self.view endEditing:YES];
    NSLog(@"\n\n Message sent");
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


- (SecIdentityRef)makeCertificate
{
    SecIdentityRef identity = nil;
    NSData *PKCS12Data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Certificates" ofType:@"p12"]];
    
    CFDataRef inPKCS12Data = (__bridge CFDataRef)PKCS12Data;
    CFStringRef password = CFSTR("Mind@123");
    const void *keys[] = { kSecImportExportPassphrase };//kSecImportExportPassphrase };
    const void *values[] = { password };
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    OSStatus securityError = SecPKCS12Import(inPKCS12Data, options, &items);
    CFRelease(options);
    CFRelease(password);
    if (securityError == errSecSuccess) {
        NSLog(@"Success opening p12 certificate. Items: %ld", CFArrayGetCount(items));
        CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
        identity = (SecIdentityRef)CFDictionaryGetValue(identityDict, kSecImportItemIdentity);
        return identity;
    } else {
        NSLog(@"Error opening Certificate.");
        return identity;
    }
    return nil;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.arrayForTable count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([[[self.arrayForTable objectAtIndex:indexPath.row]objectForKey:@"type"]isEqualToString:@"text"]) {
        
        NSString *cellIdentifier;
        
        if ([[[self.arrayForTable objectAtIndex:indexPath.row] objectForKey:@"from"]isEqualToString:[[UIDevice currentDevice]name]])
            cellIdentifier = @"message";
        else
            cellIdentifier = @"message_reverse";
        
        
        MessageCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.lblMessage.text = [[self.arrayForTable objectAtIndex:indexPath.row] objectForKey:@"postData"];
        cell.lblFrom.text = [[self.arrayForTable objectAtIndex:indexPath.row] objectForKey:@"from"];
        
        return cell;
    }
    else if ([[[self.arrayForTable objectAtIndex:indexPath.row]objectForKey:@"type"]isEqualToString:@"data"]) {
        
        NSString *cellIdentifier;
        
        if ([[[self.arrayForTable objectAtIndex:indexPath.row] objectForKey:@"from"]isEqualToString:[[UIDevice currentDevice]name]])
            cellIdentifier = @"image";
        else
            cellIdentifier = @"image_reverse";
        
        ImageCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.imageViewData.image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[[self.arrayForTable objectAtIndex:indexPath.row] objectForKey:@"postData"]]]];
        cell.lblFrom.text = [[self.arrayForTable objectAtIndex:indexPath.row] objectForKey:@"from"];
        return cell;
    }
    else if ([[[self.arrayForTable objectAtIndex:indexPath.row]objectForKey:@"type"]isEqualToString:@"progress"]) {
        
        NSString *cellIdentifier;
        
        if ([[[self.arrayForTable objectAtIndex:indexPath.row] objectForKey:@"from"]isEqualToString:[[UIDevice currentDevice]name]])
            cellIdentifier = @"progress";
        else
            cellIdentifier = @"progress_reverse";
        
        ProgressCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        self.cell = cell;
        return cell;
    }
    return nil;
    
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}


- (void)postNSData {
    
    BOOL idom = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? YES : NO;
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [imagePicker setDelegate:self];
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Send file" message:@"" preferredStyle:(idom)? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
    UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction *photos = [UIAlertAction actionWithTitle:@"Photos" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [controller addAction:camera];
    [controller addAction:photos];
    [controller addAction:cancel];
    
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - UIImageDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    
    NSData *pngData = UIImageJPEGRepresentation(imageToSave, 1.0);
    
    NSDateFormatter *inFormat = [NSDateFormatter new];
    [inFormat setDateFormat:@"yyMMdd-HHmmss"];
    NSString *imageName = [NSString stringWithFormat:@"image-%@.png", [inFormat stringFromDate:[NSDate date]]];
    NSString *filePathShare = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    filePathShare = [filePathShare stringByAppendingPathComponent:imageName];
    NSLog(@"%d",[pngData writeToFile:filePathShare atomically:YES]);
    
    self.dictionary = [NSMutableDictionary new];
    [self.dictionary setObject:@"data" forKey:@"type"];
    [self.dictionary setObject:[[UIDevice currentDevice]name] forKey:@"from"];
    [self.dictionary setObject:filePathShare forKey:@"postData"];
    [self.arrayForTable addObject:self.dictionary];
    
    self.dictionary = [NSMutableDictionary new];
    [self.dictionary setObject:@"progress" forKey:@"type"];
    [self.dictionary setObject:[[UIDevice currentDevice]name] forKey:@"from"];
    [self.arrayForTable addObject:self.dictionary];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
    [self shareWithPeers:filePathShare];
    
}



- (void)shareWithPeers:(NSString *)path {
    
    NSProgress *progress;
    
    [self.btnSend setEnabled:NO];
    [self.source setEnabled:NO];
    
    for (MCPeerID *peerID in [self.session connectedPeers])
    {
        progress = [self.session sendResourceAtURL:[NSURL fileURLWithPath:path] withName:[path lastPathComponent] toPeer:peerID withCompletionHandler:^(NSError * _Nullable error) {
          
            if (error) {
                NSLog(@"%@", [error localizedDescription]);
            }
            else {
                [self.arrayForTable removeLastObject];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.btnSend setEnabled:YES];
                    [self.source setEnabled:YES];
                    [self.tableView reloadData];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.arrayForTable count]-1 inSection:0];
                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                });
            }
        }];
        
    }
    [progress addObserver:self forKeyPath:@"cancelled" options:NSKeyValueObservingOptionNew context:NULL];
    [progress addObserver:self forKeyPath:@"completedUnitCount" options:NSKeyValueObservingOptionNew context:NULL];
    
}


#pragma mark - Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSProgress *progress = object;
    NSLog(@"%f", [progress fractionCompleted]);
   dispatch_async(dispatch_get_main_queue(), ^{
        [self.cell.progressView setProgress:[progress fractionCompleted]];
    });
    
    if ([keyPath isEqualToString:@"cancelled"]) {
        
    }
    else if ([keyPath isEqualToString:@"completedUnitCount"]) {
        
        if (progress.completedUnitCount == progress.totalUnitCount) {
            
        }
    }
}




- (void)reloadAtcurrectSessionIndexPathWithName:(NSString *)name withReceivedData:(NSString *)receivedData type:(NSString *)type  {
    self.dictionary = [NSMutableDictionary new];
    [self.dictionary setObject:receivedData forKey:@"postData"];
    [self.dictionary setObject:name forKey:@"from"];
    [self.dictionary setObject:type forKey:@"type"];
    [self.arrayForTable addObject:self.dictionary];
   
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.arrayForTable count]-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
}


#pragma mark - NSOperationDelegate

- (void)operationDidFinishWithResponse:(NSString *)response {
    self.token = response;
    [self createSession];
    [self startBrowsing];
    [self startAdvertising];
}

- (void)operationDidEncounteredErrorWithDomain:(NSError *)error {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:[error localizedDescription] message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [controller addAction:action];
    [self presentViewController:controller animated:YES completion:nil];
}

@end

