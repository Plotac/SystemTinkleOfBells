//
//  ViewController.m
//  SystemTinkleOfBells
//
//  Created by Ja on 2019/7/11.
//  Copyright © 2019 Ja. All rights reserved.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#define kEnglishKey  @"name-English"
#define kChineseKey  @"name-Chinese"

//以下两个路径均为真机路径
NSString *const kAlertTonesURL = @"/System/Library/PrivateFrameworks/ToneLibrary.framework/AlertTones/Modern";
NSString *const kSoundsURL = @"/System/Library/Audio/UISounds";

static NSString *const kNormalCell = @"kNormalCell";

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) NSMutableArray *sounds;

@property (nonatomic,assign) UInt32 curSoundID;

@property (nonatomic,strong) NSIndexPath *selectedPath;

@end

#warning 请使用真机调试！！！！！！
/*
 本demo中的铃声均取于iOS12.3.2中的系统提醒铃声，并未包含系统电话铃声
 TinkleOfBells.plist中的数据也取自于iOS12.3.2 但不包含所有 iPhone-设置-声音与触感-短信铃声-提醒铃声 中的铃声，只是部分。 有几个铃声并未拿到。
 
 以后系统升级，苹果新增提醒铃声后，plist文件中的数据要相应增加。
 */
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"系统提醒铃声";
    
    self.curSoundID = -1;
    
    self.sounds = [NSMutableArray arrayWithArray:[self getSystemSounds]];
    [self configTableView];
    self.navigationItem.rightBarButtonItem = [self configRightBarItem];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sounds.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kNormalCell forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    for (UIView *subView in cell.contentView.subviews) {
        [subView removeFromSuperview];
    }
    
    NSString *name_Chinese = @"";
    NSString *name_English = @"";
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"TinkleOfBells" ofType:@"plist"];
    NSArray *tinkleBells = [NSArray arrayWithContentsOfFile:plistPath];
    NSDictionary *dict = [tinkleBells objectAtIndex:indexPath.row];
    name_Chinese = [dict objectForKey:kChineseKey];
    name_English = [dict objectForKey:kEnglishKey];
    
    UILabel *chineseLab = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, 120, 50)];
    chineseLab.textColor = [UIColor blackColor];
    chineseLab.font = [UIFont systemFontOfSize:15];
    chineseLab.text = name_Chinese;
    [cell.contentView addSubview:chineseLab];
    
    UILabel *englishLab = [[UILabel alloc]initWithFrame:CGRectMake(15 + 120 + 10, 0, 240, 50)];
    englishLab.textColor = [UIColor lightGrayColor];
    englishLab.font = [UIFont systemFontOfSize:15];
//    englishLab.text = name_English;//从写死的plist文件取
    englishLab.text = [[self.sounds objectAtIndex:indexPath.row] lastPathComponent];//从系统文件取
    [cell.contentView addSubview:englishLab];
    
    if ([indexPath isEqual:self.selectedPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.curSoundID != -1) {
        AudioServicesDisposeSystemSoundID(self.curSoundID);
    }
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[self.sounds objectAtIndex:indexPath.row], &soundID);
    AudioServicesPlayAlertSound(soundID);
    self.curSoundID = soundID;
    self.selectedPath = indexPath;
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 40)];
    headerView.backgroundColor = [UIColor colorWithRed:220/256.0 green:220/256.0 blue:220/256.0 alpha:1];
    
    UILabel *cn_titleLab = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, 100, 20)];
    cn_titleLab.text = @"中文名称";
    cn_titleLab.font = [UIFont systemFontOfSize:14];
    cn_titleLab.textColor = [UIColor blackColor];
    [headerView addSubview:cn_titleLab];
    
    UILabel *en_titleLab = [[UILabel alloc]initWithFrame:CGRectMake(10 + 100 + 10, 10, 100, 20)];
    en_titleLab.text = @"英文名称";
    en_titleLab.font = [UIFont systemFontOfSize:14];
    en_titleLab.textColor = [UIColor lightGrayColor];
    en_titleLab.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:en_titleLab];
    
    return headerView;
}

#pragma mark -
- (void)rightBarButtonItemAction {
    if (self.curSoundID != -1) {
        AudioServicesDisposeSystemSoundID(self.curSoundID);
    }
}

#pragma mark - Private
- (NSArray*)getSystemSounds {
    NSFileManager *fileManage = [NSFileManager defaultManager];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSMutableArray *sounds = @[].mutableCopy;
    
    NSURL *directorURL1 = [NSURL URLWithString:kAlertTonesURL];
    NSDirectoryEnumerator *enumerator1 = [fileManage enumeratorAtURL:directorURL1 includingPropertiesForKeys:keys options:0 errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
        return YES;
    }];
    for (NSURL *url in enumerator1) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {}
        else if (![isDirectory boolValue]) {
            [sounds addObject:url];
        }
    }
    
    NSURL *directorURL2 = [NSURL URLWithString:kSoundsURL];
    NSDirectoryEnumerator *enumerator2 = [fileManage enumeratorAtURL:directorURL2 includingPropertiesForKeys:keys options:0 errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
        return YES;
    }];
    for (NSURL *url in enumerator2) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {}
        else if (![isDirectory boolValue]) {
            [sounds addObject:url];
        }
    }
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"TinkleOfBells" ofType:@"plist"];
    NSArray *tinkleBells = [NSArray arrayWithContentsOfFile:plistPath];
    
    NSMutableArray *values = @[].mutableCopy;
    for (NSDictionary *dic in tinkleBells) {
        [values addObject:[dic objectForKey:kEnglishKey]];
    }
    
    NSMutableArray *sortSounds = @[].mutableCopy;
    for (NSString *value in values) {
        for (NSURL *url in sounds) {
            if ([[[[url lastPathComponent] componentsSeparatedByString:@"."] firstObject] isEqualToString:value]) {
                [sortSounds addObject:url];
                NSLog(@"%@",url.lastPathComponent);
                break;
            }
        }
    }
    
    return [NSArray arrayWithArray:sortSounds];
}

- (void)configTableView {
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.rowHeight = 50;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kNormalCell];
    [self.view addSubview:self.tableView];
}

- (UIBarButtonItem*)configRightBarItem {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, 0, 45, 35);
    [btn setTitle:@"停止播放" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(rightBarButtonItemAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:btn];
    return rightBarButtonItem;
}

@end
