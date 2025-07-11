//
//  EventListViewController.swift
//  OmetriaSample
//
//  Created by Cata on 9/1/20.
//  Copyright © 2020 Ometria. All rights reserved.
//

import Foundation
import UIKit
import Ometria


enum EventType: String, CaseIterable {
    case basketUpdated
    case basketViewed
    case checkoutStarted
    case orderCompleted
    case productListingViewed
    case productViewed
    case homeScreenViewed
    case screenViewedExplicit
    case profileIdentifiedByEmail
    case profileIdentifiedByEmailAndStoreId
    case profileIdentifiedById
    case profileIdentifiedByIdAndStoreId
    case profileIdentifiedByEmailAndCustomerId
    case profileIdentifiedByEmailCustomerIdAndStoreId
    case profileDeidentified
    case updateStoreId
    case resetStoreId
    case custom
    case flush
    case clear
}

class EventListViewController: UITableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return EventType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
        cell.textLabel?.text = EventType.allCases[indexPath.row].rawValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let eventType = EventType.allCases[indexPath.row]
        triggerEvent(eventType)
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func triggerEvent(_ eventType: EventType) {
        switch eventType {
        
        case .basketUpdated:
            Ometria.sharedInstance().trackBasketUpdatedEvent(basket: createSampleBasket())
        
        case .basketViewed:
            Ometria.sharedInstance().trackBasketViewedEvent()
            
        case .checkoutStarted:
            Ometria.sharedInstance().trackCheckoutStartedEvent(orderId: "sample_order_id")
        
        case .orderCompleted:
            Ometria.sharedInstance().trackOrderCompletedEvent(orderId: "sample_order_id", basket: createSampleBasket())
        
        case .productListingViewed:
            Ometria.sharedInstance().trackProductListingViewedEvent(listingType: "category", listingAttributes: ["categoryID": "sampleCategoryID"])
        
        case .productViewed:
            Ometria.sharedInstance().trackProductViewedEvent(productId: "sample_product_id")
        
        case .homeScreenViewed:
            Ometria.sharedInstance().trackHomeScreenViewedEvent()
        
        case .screenViewedExplicit:
            Ometria.sharedInstance().trackScreenViewedEvent(screenName: "sample_screen_name")
        
        case .profileIdentifiedByEmail:
            Ometria.sharedInstance().trackProfileIdentifiedEvent(email: "sample@profile.com")
            
        case .profileIdentifiedById:
            Ometria.sharedInstance().trackProfileIdentifiedEvent(customerId: "sample_customer_id")
            
        case .profileIdentifiedByIdAndStoreId:
            Ometria.sharedInstance().trackProfileIdentifiedEvent(customerId: "sample_customer_id", storeId: "sample_store_id_customer")
            
        case .profileIdentifiedByEmailAndStoreId:
            Ometria.sharedInstance().trackProfileIdentifiedEvent(email: "sample@profile.com", storeId: "sample_store_id_email")
        
        case .profileIdentifiedByEmailAndCustomerId:
            Ometria.sharedInstance().trackProfileIdentifiedEvent(customerId: "sample_customer_id", email: "sample@profile.com")

        case .profileIdentifiedByEmailCustomerIdAndStoreId:
            Ometria.sharedInstance().trackProfileIdentifiedEvent(customerId: "sample_customer_id", email: "sample@profile.com", storeId: "sample_store_id_email")

        case .profileDeidentified:
            Ometria.sharedInstance().trackProfileDeidentifiedEvent()
            
        case .updateStoreId:
            Ometria.sharedInstance().updateStoreId(storeId: "sample_store_id_update")
            
        case .resetStoreId:
            Ometria.sharedInstance().updateStoreId(storeId: nil)
        
        case .custom:
            Ometria.sharedInstance().trackCustomEvent(customEventType: "custom_event", additionalInfo: ["sampleField": "sampleValue"])
            
        case .flush:
            Ometria.sharedInstance().flush()
            
        case .clear:
            Ometria.sharedInstance().clear()
        }
    }
    
    func createSampleBasket() -> OmetriaBasket {
        let myItem = OmetriaBasketItem(productId: "product-1",
                                       variantId: "variant-product-1",
                                       sku: "sku-product-1",
                                       quantity: 1,
                                       price: 12.0)
        let myItems = [myItem]
        let myBasket = OmetriaBasket(id: "basket-id", totalPrice: 12.0, currency: "USD", items: myItems, link: "http://sample.link.com")
        
        return myBasket
    }
}
