1\. Why integrate Ometria in a mobile app?
------------------------------------------

Ometria helps your marketing department understand and better engage with your customers by delivering personalised emails and push notifications.

The app has two key objectives:

1. Getting information about customers (what do they like?)
2. Reaching out to customers (saying the right thing to the right people).

For your mobile app, this means:

1. Tracking customer behaviour through events - handled by Ometria.
2. Sending and displaying push notifications - **requires the app developers**.

2\. Before you begin
----------------------

See [Setting up your mobile app with Firebase credentials](https://support.ometria.com/hc/en-gb/articles/360013658478-Setting-up-your-mobile-app-with-Firebase-credentials) in the Ometria help centre and follow the steps there to get an API key.

3\. Install the library
-----------------------

The easiest way to get Ometria into your iOS project is by using [CocoaPods](https://cocoapods.org/).

1. If you are using CocoaPods for the first time, install CocoaPods using `gem install cocoapods` in terminal. Otherwise, go to step 3.
2. Run `pod setup` to create a local CocoaPods spec mirror.
3. Create a Podfile in your Xcode project directory by running `pod init` in your terminal, edit the Podfile generated and add the following line: `pod 'Ometria'`.
4. Run `pod install` in your Xcode project directory. CocoaPods should download and install the library, and create a new Xcode workspace. Open this workspace in Xcode or typing `open *.xcworkspace` in your terminal.

4\. Initialise the library
--------------------------
To initialise Ometria, you need to enter the API key from **2. Before you begin**.

The best place to do this is in [application(_:didFinishLaunchingWithOptions:)](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIApplicationDelegate_Protocol/#//apple_ref/occ/intfm/UIApplicationDelegate/application:didFinishLaunchingWithOptions:).

Initialise the library by adding **import Ometria** and then calling **Ometria.initialize(apiToken:)** with your API key as its argument.

Once you've called this method once, you can access your instance throughout the rest of your application with **sharedInstance()**.

Ometria uses [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging) to send push notifications to the mobile devices.

To do this, add ‘Firebase/Messaging’ as a dependency of Ometria. 

* If you installed the library via CocoaPods it is automatically installed. 
* If you added Ometria manually in your project, you should [install the Firebase SDK](https://firebase.google.com/docs/cloud-messaging/ios/client) separately.

After initialising Ometria, do the same for [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/ios/client). 

Once complete you will have something like this:

```swift
import Ometria

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Ometria.initialize(apiToken: "OMETRIA_API_TOKEN")
    FirebaseApp.configure()
    return
}
```
Ometria logs any errors encountered during runtime by default. 

You can enable advanced logging if you want more information on what’s happening in the background. Just add the following line after initialising the library:

```swift
Ometria.sharedInstance().isLoggingEnabled = true
```
5\. Event tracking guide
------------------------
You need to be aware of your users’ behaviour on your platforms in order to understand them. Some behaviour is automatically detectable, other events need work from the app developer to track.

Many of these methods have analogous events in a server-to-server API called the [Ometria Data API](https://support.ometria.com/hc/en-gb/articles/360011511017-Data-API-introduction), and through a separate JavaScript API.

**Be aware:** If your business already integrates with Ometria in any way, it is very important that the values sent here correspond to those in other integrations.

E.g., the customer identified event takes a customer ID - that ID must be the same here as it is in the data API. 

The events are merged on Ometria's side into one big cross-channel view of your customer behaviour, which will otherwise get very messy.

### Manually tracked events

Once the SDK is initialised, you can track an event by calling its dedicated method:

```swift
let myItem = OmetriaBasketItem(
        productId: "product-1",
        sku: "sku-product-1",
        quantity: 1,
        price: 12.0)
let myItems = [myItem]
let myBasket = OmetriaBasket(totalPrice: 12.0, currency: "USD", items: myItems)

Ometria.sharedInstance().trackBasketUpdatedEvent(basket: myBasket)
```

#### Profile identified

An app user has just identified themselves, i.e. logged in.

```swift
trackProfileIdentifiedEvent(customerId: String)
```

Their **customer ID** is their **user ID** in your database.

Sometimes a user only supplies their email address without fully logging in or having an account. In that case, Ometria can profile match based on email:

```swift
trackProfileIdentifiedEvent(email: String)
```

Having a **customerId** makes profile matching more robust. 

It’s not mutually exclusive with sending an email event; for optimal integration you should send either event as soon as you have the information.
These two events are pivotal to the functioning of the SDK, so make sure you send them as early as possible.

#### Profile deidentified

Undo a profileIdentified event.

Use this if a user logs out, or otherwise signals that this device is no longer attached to the same person.

```swift
trackProfileDeidentifiedEvent()
```

#### Product viewed

A visitor clicks/taps/views/highlights or otherwise shows interest in a product. 

E.g. the visitor searches for a term and selects one of the product previews from a set of results, or browses a category of clothes, and clicks on a specific shirt to see a bigger picture. 

This event is about capturing interest from the visitor for this product.

```swift
trackProductViewedEvent(productId: String)
```

#### Wishlist events

The visitor has added this product to their wishlist:

```swift
trackWishlistAddedToEvent(productId: String)
```

... or removed it:

```swift
trackWishlistRemovedFromEvent(productId: String)
```

#### Basket viewed

The visitor has viewed a dedicated page, screen or modal with the contents of the shopping basket:

```swift
trackBasketViewedEvent()
```
#### Basket updated

The visitor has changed their shopping basket:

```swift
trackBasketUpdatedEvent(basket: OmetriaBasket)
```

This event takes the full current basket as a parameter - not just the updated parts. 

This helps recover from lost or out of sync basket events: the latest update is always authoritative.


#### Checkout started

The user has started the checkout process.

```swift
trackCheckoutStartedEvent(orderId: String)
```

#### Order Completed

The order has been completed and paid for:

```swift
trackOrderCompletedEvent(orderId: String, basket: OmetriaBasket)
```

#### Deep link opened

Based on the implementation status of interaction with notifications that contain deep links, this event can be automatically tracked or not. 

The default implementation automatically logs a deep link opened event every time the user interacts with a notification that has a deep link. This is possible because we know that the default implementation will open the link in a browser. 

If you chose to handle deep links yourself (using the guide for [Handling interaction with notifications that contain URLs](#handling_interaction_with_notifications_that_contain_urls)), then you should manually track this event when you have enough information regarding the screen (or other destination) that the app will open.

```swift
trackDeepLinkOpenedEvent(link: String, screenName: String)
```

#### View home page

The visitor views the ‘home page’ or landing screen of your app.

```swift
trackHomeScreenViewedEvent()
```

#### View list of products

The visitor clicks/taps/views/highlights or otherwise shows interest in a product listing. This kind of screen includes search results, listings of products in a group, category, collection or any other screen that presents a list of products.

E.g., A store sells clothing, and the visitor taps on "Women's Footwear" to see a list of products in that category, or they search for "blue jumper" and see a list of products in that category.

This event should be triggered on:

* search results
* category lists
* any similar screens

```swift
trackProductListingViewedEvent(listingType: String?, listingAttributes: [String: Any]?)
```

#### Screen viewed

Tracking a visitor’s independent screen views helps us track their engagement with the app, as well as where they are in a journey. 

An analogous event on a website would be to track independent page views.

The common eCommerce screens all have their own top-level event: basket viewed, list of products viewed, etc. 

Your app may have a specific type of page that is useful for marketers to track engagement with. 

E.g. if you’re running a promotion, and viewing a specific screen indicates interest in the promotion, which marketing might later want to follow up on. 

To track these custom screens, use the _Screen viewed_ event:

```swift
trackScreenViewedEvent(screenName: String, additionalInfo: [String: Any])
```

#### Custom events

Your app might have specific flows or pages that are of interest to the marketing team.

E.g. Marketing might want to send an email or notification to any user who signed up for a specific promotion, or interacted with a button or specific element of the app. 

If you send a custom event corresponding to that action, they will be able to trigger an [automation campaign](https://support.ometria.com/hc/en-gb/articles/360011378398-Automation-campaigns-overview) on it.

Check with the marketing team about the specifics, and what they might need. Especially if they're already using Ometria for email, they will know about automation campaigns and custom events.

```swift
trackCustomEvent(customEventType: String, additionalInfo: [String: Any]?)
```

### `OmetriaBasket`

An object that describes the contents of a shopping basket.

#### Properties

* `currency`: (`String`, required) - A string representing the currency in ISO currency format. e.g. `"USD"`, `"GBP"`
* `price`: (`float`, required) - A float value representing the pricing.
* `items`: (`Array[OmetriaBasketItem]`) - An array containing the item entries in this basket.

### `OmetriaBasketItem`

An object that describes the contents of a shopping basket. 

It can have its own price and quantity based on different rules and promotions that are being applied.

#### Properties

* `productId`: (`String`, required) - A string representing the unique identifier of this product.
* `sku`: (`String`, optional) - A string representing the stock keeping unit, which allows identifying a particular item.
* `quantity`: (`Int`, required) - The number of items that this entry represents.
* `price`: (`Float`, required) - Float value representing the price for one item. The currency is established by the OmetriaBasket containing this item

### Automatically tracked events

The following events are automatically tracked by the SDK. 

Linking and initialising the SDK is enough to take advantage of these; no further integration is required.

| Event| Description| 
| ------------- |:-------------:| 
| **Application installed** | The app was just installed. Usually can't be sent when the app is _actually_ installed, but instead only sent the first time the app is launched. | 
| **Application launched** | Someone has just launched the app.|
| **Application foregrounded** | The app was already launched, but it was in the background. It has just been brought to the foreground.|
| **Application backgrounded** | The app was in active use and has just been sent to the background. |
| **Push token refreshed** | The push token generated by Firebase has been updated. |
| **Notification received** | A Push notification was received by the system. |
| **Notification interacted** | The user has just clicked on / tapped on / opened a notification. |
| **Error occurred** | An error occurred on the client side. We try to detect any problems with actual notification payload on our side, so we don't expect any errors which need to be fed back to end users. |

### Flush tracked events

In order to reduce power and bandwidth consumption, the Ometria library doesn’t send the events one by one unless you request it to do so. 

Instead, it composes batches of events that are periodically sent to the backend during application runtime. 

You can request the library to send all remaining events to the backend whenever you want by calling:

```swift
Ometria.sharedInstance().flush()
```

The library will automatically call this method every time the application is brought to foreground or sent to background.

### Clear tracked events

You can completely clear all the events that have been tracked and not yet flushed. 

To do this, call the following method:

```swift
Ometria.sharedInstance().clear()
```

6\. Push notifications guide
----------------------------

When correctly set up, Ometria can send personalised notifications for your mobile application. 

Follow these steps:

1. Enable your app to receive push notifications by creating an appId and enabling the push notifications entitlement.
2. Set up a [Firebase](https://firebase.google.com/docs/cloud-messaging) account and connect it to Ometria.
3. Enable Cloud Messaging on your Firebase account and provide your application’s **SSL push certificate**.
4. Configure push notifications in your application.
5. Add a **Notification Service Extension** to your app in order to enable receiving rich content notifications.

### Configure push notifications in your application

Before continuing, you must have already configured:

* The Ometria SDK
* Firebase

Once you managed to properly create or modify your application to support push notifications, you can move on to configure everything in your AppDelegate like so:

```swift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Ometria.initialize(apiToken: "OMETRIA_API_TOKEN")
        FirebaseApp.configure()
        configurePushNotifications()

        return true
    }

    func configurePushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) {
            [weak self] (granted, error) in

            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
        }
        UIApplication.shared.registerForRemoteNotifications()
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard #available(iOS 12.0, *), settings.authorizationStatus == .provisional ||
            settings.authorizationStatus == .authorized else {
                return
            }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Reaching Did register for remote notifications")
        // handle your own device token handling here
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Reaching Did receive notification response")
        // handle how your app reacts to receiving a push notification while it is running in foreground
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Reaching Will present notification")
        // handle how you want your notification to be presented while the app is running in foreground
    }
}
```

The Ometria SDK will automatically source all the required tokens and provide them to the backend. 

This way your app will start receiving notifications from Ometria. Handling those notifications while the app is running in the foreground is up to you.

### Handling interaction with notifications that contain URLs

Ometria allows you to send URLs alongside your push notifications and allows you to handle them on the device. 

By default, the Ometria SDK automatically handles any interaction with push notifications that contain URLs by opening them in a browser.

However, it enables developers to handle those URLs as they see fit (e.g. take the user to a specific screen in the app).

To get access to those interactions and the URLs, implement the `OmetriaNotificationInteractionDelegate`. 

There is only one method that is required, and it will be triggered every time the user taps on a notification that has a deepLink action URL. 
This is what it would look like in code:

```swift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate,  OmetriaNotificationInteractionDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Ometria.initialize(apiToken: "OMETRIA_API_TOKEN")
        Ometria.sharedInstance().notificationInteractionDelegate = self

        return true
    }

    // This method will be called each time the user interacts with a notification from Ometria
    // which contains a deepLinkURL. Write your own custom code in order to
    // properly redirect the app to the screen that should be displayed.
    func handleDeepLinkInteraction(_ deepLink: URL) {
        print("url: \(deepLink)")
    }
}
```

### Enabling rich content notifications

Starting with iOS 12.0, Apple enabled regular applications to receive and display notifications that contain media content such as images. 

Ometria uses this feature to further enhance your application, but it requires you to add a new target extension that intercepts all push notifications containing 'mutable-content: 1' in the payload.

To do this, go to **File > New > Target**, and select **Notification Service Extension > Next**.

![](https://raw.githubusercontent.com/wiki/Ometria/ometria.ios_sdk/images/notification_service_extension.png)

A new item displays in your target list:

![](https://raw.githubusercontent.com/wiki/Ometria/ometria.ios_sdk/images/project_targets.png)

Next, make sure that the Ometria SDK is also available to this new target by updating your podfile to include your newly added target and specify Ometria as a dependency. 

**Warning**: If you try to run pod install and then build the extension, you will get some compilation errors. 

Since we are trying to run Ometria on an extension, there are several methods in the SDK that are not supported, although not being used. 

To silence those errors and get everything functional you will have to update your podfile ending up with something like this:

```ruby
 platform :ios, '10.0'

target 'OmetriaSample' do
  use_frameworks!

  pod 'Ometria', :path => '../../SDK'

  target 'OmetriaSampleNotificationService' do
    pod 'Ometria', :path => '../../SDK'
  end

  end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'Ometria'
      target.build_configurations.each do |config|
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
      end
    end
  end
end
```

Once you’ve done this, you can run your application and the extension you have just created.

To finalise the implementation and allow Ometria to intercept notifications, open the `NotificationService` class and replace the content with the following:

```swift
import UserNotifications
import Ometria

class NotificationService: OmetriaNotificationServiceExtension {

}
```

Now you can receive notifications from Ometria and you are also able to see the images that are attached to your notifications.


7\. Universal Links Guide
----------------------------

Ometria sends personalized emails with urls that point back to your website. In order to open these urls inside your application, make sure you follow this guide.  


### Enable the Associated Domains entitlement for your application

To do this, select your project in Xcode, and go to **Targets > Your application Target > Signing & Capabilities**, and add the **Associated Domains** capability.

![](https://raw.githubusercontent.com/wiki/Ometria/ometria.ios_sdk/images/target_capabilities.png)

Once enabled, input your Ometria tracking domain (used for emails) like below.
This will ensure that when your customers click on links in Ometria emails, your app opens instead of the browser.
(Note that this does not associate your website's domain with the app, only the tracking domain.)

![](https://raw.githubusercontent.com/wiki/Ometria/ometria.ios_sdk/images/associated_domain.png)

### Create an apple-app-site-association file and send it to your Ometria contact.

The apple-app-site-association file is used to create a relationship between a domain and your app. You can [find more info about it here](https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html) but for the purpose of this guide we will go with the most basic example which should look like this:

```javascript
{
    "applinks": {
        "details": [
            {
                "appID": "<Your_team_identifier>.<Your_bundle_id>",
                "paths": ["*"]
            }
        ]
    }
}
```

Save it and name it "apple_app_site_association" (notice that no extension has been used, although it's just a normal
JSON file). Then send it to your Ometria contact - we will upload this for you so that it will be available behind the
tracking domain.

Once you are done, you should be able to successfully open your app by selecting a URL received from Ometria.

### Process universal links inside the app

The final step is to process the URLs in your app and take the user to the appropriate sections of the app. Note that
you need to implement the mapping between your website's URLs and the screens of your app. See also [this document](https://support.ometria.com/hc/en-gb/articles/4402644059793-Linking-push-notifications-to-app-screens).

If you are dealing with normal URLs pointing to your website, you can decompose it into different path components and parameters. This will then allow you to source the required information to navigate through to the correct screen in your app.
However, Ometria emails contain obfuscated tracking URLs, and these need to be converted back to the original URL, pointing to your website, before you can map the URL to an app screen. To do so, the SDK provides a method called `processUniversalLink`:

```swift
func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if let url = userActivity.webpageURL {
        // you can check here whether the URL is one that you can handle without converting it back
        Ometria.sharedInstance().processUniversalLink(url) { (url, error) in
            if let url = url {
                // you can now handle the retrieved url as you would any other url from your website
            } else {
                // an error may have occurred
            }
        }
    }
}
```
**Warning**: The method above runs asynchronously. Depending on the internet speed on the device, the processing time can vary. For best results, you could implement a loading state that is displayed while the URL is being processed.

If you have done everything correctly, the app should now be able to open universal links and allow you to handle them inside the app.
