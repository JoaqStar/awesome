//
//  BeamViewController.m
//  awesome
//
//  Created by Joaquin Brown on 11/26/13.
//  Copyright (c) 2013 Joaquin Brown. All rights reserved.
//

#import "BeamViewController.h"
#import <MapKit/MapKit.h>
#import "DataManager.h"
#import "Tools.h"

@interface BeamViewController () <CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) CLLocation *currentLocation;
@property (nonatomic, strong) UIImageView *pinView;
@property (nonatomic, strong) DataManager *dataManager;
@property (nonatomic, strong) UIPickerView *timePickerView;
@property (nonatomic, strong) UIActionSheet *timePickerSheet;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval seconds;
@property (nonatomic, strong) Location *lastLocation;

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIButton *startButton;
@property (nonatomic, weak) IBOutlet UIButton *stopButton;
@property (nonatomic, weak) IBOutlet UIButton *remainingTimeButton;
@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *setLocationLabel;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *refreshButton;

@end

@implementation BeamViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.dataManager = [DataManager sharedManager];

    [self.view setBackgroundColor:[Tools getBackgroundColor]];
    
    self.pinView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MapPin"]];
    
    [self setUpTimePickerSheet];
    
    self.lastLocation = [self.dataManager getLastLocation];
    
    if (self.lastLocation)
    {
        [self setUpTimer];
        [self onTick];
        [self mapViewIsEnabled:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Move pin to middle of map (should adjust for different size iphones
    CGPoint center;
    if (self.view.frame.size.height > 500) {
        center = CGPointMake(160, 212.5);
    } else {
        center = CGPointMake(160, 168.5);
    }
    self.pinView.center = center;
    [self.view addSubview:self.pinView];
    
    if (self.lastLocation) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:NO];
        [self.mapView setShowsUserLocation:NO];
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = [self.lastLocation.latitude floatValue];
        coordinate.longitude = [self.lastLocation.longitude floatValue];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
        [self.mapView setRegion:region animated:NO];
    } else {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
        [self.mapView setShowsUserLocation:YES];
    }
}

-(void) setUpTimer
{
    [self.startButton setHidden:YES];
    [self.stopButton setHidden:NO];
    [self mapViewIsEnabled:NO];
    
    [self.remainingTimeButton setHidden:YES];
    self.remainingTimeLabel.text = [self.remainingTimeButton titleForState:UIControlStateNormal];
    [self.remainingTimeLabel setHidden:NO];
    [self.setLocationLabel setText:@"Location is set for:"];
    [self.mapView setShowsUserLocation:NO];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                  target: self
                                                selector:@selector(onTick)
                                                userInfo: nil repeats:YES];
}

-(void) mapViewIsEnabled:(BOOL)enabled
{
    [self.mapView setZoomEnabled:enabled];
    [self.mapView setPitchEnabled:enabled];
    [self.mapView setScrollEnabled:enabled];
    [self.mapView setRotateEnabled:enabled];
    [self.refreshButton setEnabled:enabled];
}

-(void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    NSLog(@"User location is %@", userLocation.location);
    self.currentLocation = [userLocation.location copy];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.currentLocation.coordinate, 1000, 1000);
    [self.mapView setRegion:region animated:YES];
    [self.mapView setShowsUserLocation:NO];
}

#pragma mark - Time Duration Methods
- (void)setUpTimePickerSheet
{
    self.timePickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(10,30,300,150)];
    self.timePickerView.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
    self.timePickerView.delegate = self;
    self.timePickerView.dataSource = self;
    self.timePickerView.showsSelectionIndicator = YES;
    self.timePickerView.backgroundColor = [UIColor clearColor];
    [self.timePickerView selectRow:1 inComponent:1 animated:YES];
    [self.remainingTimeButton setTitle:@"1 hour" forState:UIControlStateNormal];
    self.seconds = 60 * 60;
    
    self.timePickerSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    [self.timePickerSheet addSubview:self.timePickerView];
    
    UIToolbar *tools=[[UIToolbar alloc]initWithFrame:CGRectMake(0, 0,320,40)];
    [self.timePickerSheet addSubview:tools];
    
    UIBarButtonItem *doneButton=[[UIBarButtonItem alloc]initWithTitle:@"Ok" style:UIBarButtonItemStyleBordered target:self action:@selector(doneButtonClicked)];
    doneButton.imageInsets=UIEdgeInsetsMake(200, 6, 50, 25);
    UIBarButtonItem *CancelButton=[[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonClicked)];
    
    UIBarButtonItem *flexSpace= [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *array = [[NSArray alloc]initWithObjects:CancelButton,flexSpace,flexSpace,doneButton,nil];
    
    [tools setItems:array];
    
    //picker title
    UILabel *lblPickerTitle=[[UILabel alloc]initWithFrame:CGRectMake(60,8, 200, 25)];
    lblPickerTitle.text=@"Select duration";
    lblPickerTitle.backgroundColor=[UIColor clearColor];
    lblPickerTitle.textColor=[UIColor darkGrayColor];
    lblPickerTitle.textAlignment=NSTextAlignmentCenter;
    lblPickerTitle.font=[UIFont boldSystemFontOfSize:15];
    [tools addSubview:lblPickerTitle];
}

- (IBAction)changeTime:(id)sender
{
    [self.timePickerSheet showFromRect:CGRectMake(0,480, 320,215) inView:self.view animated:YES];
    [self.timePickerSheet setBounds:CGRectMake(0,0, 320, 345)];
}

-(void) doneButtonClicked
{
    int timeValue = (int)[self.timePickerView selectedRowInComponent:0] + 1;
    NSString *timeType;
    if ([self.timePickerView selectedRowInComponent:1] == 0) {
        if (timeValue == 1) {
            timeType = @"minute";
        } else {
            timeType = @"minutes";
        }
        self.seconds = timeValue * 60;
    } else {
        if (timeValue == 1) {
            timeType = @"hour";
        } else {
            timeType = @"hours";
        }
        self.seconds = timeValue * 60 * 60;
    }
    [self.remainingTimeButton setTitle:[NSString stringWithFormat:@"%d %@", timeValue, timeType] forState:UIControlStateNormal];
    
    [self.timePickerSheet dismissWithClickedButtonIndex:0 animated:YES];
}

-(void) cancelButtonClicked
{
    
    [self.timePickerSheet dismissWithClickedButtonIndex:0 animated:YES];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
{
    
    return 2;
    
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
{
    if (component == 0) {
        return 60;
    } else {
        return 2;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return [NSString stringWithFormat:@"%d", (int)row+1];
    } else {
        if (row == 0) {
            return @"minutes";
        } else {
            return @"hours";
        }
    }
}

#pragma mark - Start and Stop methods
- (IBAction)startButtonPressed:(id)sender
{
     NSDate *stopDate = [[NSDate date] dateByAddingTimeInterval:self.seconds];
    
    CLLocationCoordinate2D center = self.mapView.centerCoordinate;
    CLLocation *location = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
    
    self.lastLocation = [self.dataManager setLocation:location.coordinate untilStopDate:stopDate];
    
    [self setUpTimer];
}

- (IBAction)refreshButtonPressed:(id)sender
{
    [self.mapView setShowsUserLocation:NO];
    [self.mapView setShowsUserLocation:YES];
}

- (IBAction)stopButtonPressed:(id)sender
{
    if([self.dataManager deleteLastLocation]) {
        [self.startButton setHidden:NO];
        [self.stopButton setHidden:YES];
        [self mapViewIsEnabled:YES];
        
        [self.timer invalidate];
        
        [self.remainingTimeLabel setHidden:YES];
        [self.remainingTimeButton setTitle:self.remainingTimeButton.titleLabel.text forState:UIControlStateNormal];
        [self.remainingTimeButton setHidden:NO];
        [self.setLocationLabel setText:@"Set Location for:"];
        [self.mapView setShowsUserLocation:YES];
    }
}

- (void)onTick
{
    NSDate *date1 = self.lastLocation.stopDate;
    NSDate *date2 = [NSDate date];
    
    NSTimeInterval secondsBetween = [date1 timeIntervalSinceDate:date2];
    
    if (secondsBetween <= 0) {
        [self stopButtonPressed:nil];
    } else if (secondsBetween == 1) {
        self.remainingTimeLabel.text = @"1 second";
    } else if (secondsBetween < 60) {
        self.remainingTimeLabel.text = [NSString stringWithFormat:@"%d seconds", (int)secondsBetween];
    } else if (secondsBetween < 60*60) {
        int minutes = secondsBetween/60;
        if (minutes == 1) {
            self.remainingTimeLabel.text = @"1 minute";
        } else {
            self.remainingTimeLabel.text = [NSString stringWithFormat:@"%d minutes", minutes];
        }
    } else  {
        int hours = secondsBetween/(60*60);
        if (hours == 1) {
            self.remainingTimeLabel.text = @"1 hour";
        } else {
            self.remainingTimeLabel.text = [NSString stringWithFormat:@"%d hours", hours];
        }
    }
}

#pragma mark - Memory Management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
