#import "SceneDelegate.h"
#import "MainListTableViewController.h"
@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
    
    // ** latest iteration of doing away with storyboards
    // ** learned the hard way by not properly understanding Swift coding samples
    // ** do not create a new scene, the scene is passed in
    // ** then create the window usingh initWithWindowScene instead of initWithFrame
    // ** you have to case the scene to a UIWindowScene
    // ** if you don't do all this, it will work but keyboard input to text boxes will not
    // hierarchy: UINavigationController -> UITableViewController
    
    UINavigationController *rootNAV;
   // UIWindowScene *ws;
                                
       rootNAV = [[UINavigationController alloc] init];
    
    //ws = [[UIWindowScene alloc] initWithSession:session connectionOptions:connectionOptions];
     //  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
      
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *) scene];
       self.window.rootViewController = rootNAV;
       self.window.backgroundColor = [UIColor whiteColor];
       [self.window makeKeyAndVisible];
    
    MainListTableViewController *tmp = [[MainListTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
      [rootNAV pushViewController:tmp animated:NO];
    
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}


@end
