//
//  GFContactRetriever.swift
//  GFContactsRetriever
//
//  Created by Gualtiero Frigerio on 29/08/2018.
//

import Foundation
import Contacts

/// GFContactRetriever is a class containing a static function to retrive user contacts
/// and return them as an array of dictionaries, making it easy to pass them to an HTML file
/// or to display them with a native UI
/// Requires  Contacts framework
@available(iOS 9.0, *)
public class GFContactsRetriever {
    
    static let defaultKeys = [CNContactFamilyNameKey,
                              CNContactGivenNameKey,
                              CNContactEmailAddressesKey,
                              CNContactPostalAddressesKey,
                              CNContactImageDataKey,
                              CNContactPhoneNumbersKey]
    
    /// utility function to get the string value for each field in CNContact
    /// - Parameter field: The field in CNContact
    /// - Returns: The optional value of the field in CNContacs
    static func valueForContactField(_ field:Any) -> Any? {
        if let fieldString = field as? String {
            return fieldString
        }
        else if let data = field as? Data {
            return data.base64EncodedString() // convert image data to base64
        }
        else if let array = field as? Array<Any> {
            var returnArray:[Any] = []
            for object in array {
                if let value = valueForContactField(object) {
                    returnArray.append(value)
                }
            }
            return returnArray
        }
        else { // is a CNLabeledValue
            if let labeledValue = field as? CNLabeledValue<NSString> {
                let value = labeledValue.value as Any // force cast to Any to check the type
                
                if let valueString = value as? String {
                    return valueString
                }
                else if let valuePostalAddress = value as? CNPostalAddress {
                    var addressDictionary:[String:String] = [:]
                    addressDictionary[CNPostalAddressStateKey] = valuePostalAddress.state
                    addressDictionary[CNPostalAddressCountryKey] = valuePostalAddress.country
                    addressDictionary[CNPostalAddressCityKey] = valuePostalAddress.city
                    addressDictionary[CNPostalAddressStreetKey] = valuePostalAddress.street
                    addressDictionary[CNPostalAddressPostalCodeKey] = valuePostalAddress.postalCode
                    return addressDictionary
                }
                else if let valueNumber = value as? CNPhoneNumber {
                    return valueNumber.stringValue
                }
                else if let valueSocial = value as? CNSocialProfile {
                    var socialDictionary:[String:String] = [:]
                    socialDictionary[CNSocialProfileServiceKey] = valueSocial.service
                    socialDictionary[CNSocialProfileUsernameKey] = valueSocial.username
                    socialDictionary[CNSocialProfileURLStringKey] = valueSocial.urlString
                    socialDictionary[CNSocialProfileUserIdentifierKey] = valueSocial.userIdentifier
                    return socialDictionary
                }
                else if let messagingValue = value as? CNInstantMessageAddress {
                    var messagingDictionary:[String:String] = [:]
                    messagingDictionary[CNInstantMessageAddressUsernameKey] = messagingValue.username
                    messagingDictionary[CNInstantMessageAddressServiceKey] = messagingValue.service
                    return messagingDictionary
                }
            }
        }
        return nil
    }
    
    /// Retrieves all the user contacts and return them as an array of dictionaries
    /// - Parameters:
    ///   - fields: Specify which fields to get from contacss
    ///   - completion: The completion handler with an array of dictionaries
    public static func getContacts(fields:[String], completion:@escaping (_ success:Bool, _ results:[[String:Any]]) ->Void) {
        
        let contactStore = CNContactStore()
        contactStore.requestAccess(for: CNEntityType.contacts) { (granted, error) in
            guard granted == true else {
                print("cannot have access to user contacts")
                completion(false, [])
                return
            }
            
            var contactsToReturn:[[String:Any]] = []
            
            let predicate = CNContact.predicateForContactsInContainer(withIdentifier: contactStore.defaultContainerIdentifier())
            let keys = fields
            do {
                let allCNContacts:[CNContact] = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
                
                for contact in allCNContacts {
                    var newContact:[String:Any] = [:]
                    for key in keys {
                        if  let fieldValue = contact.value(forKey: key),
                            let stringValue = valueForContactField(fieldValue){
                            newContact[key] = stringValue
                        }
                    }
                    contactsToReturn.append(newContact)
                }
                completion(true, contactsToReturn)
            }
            catch {
                print("error while retrieving contacts")
                completion(false, [])
            }
        }
    }

    /// Convenience method to get the default fields
    /// - Parameter completion: The completion handler with a Bool value for success and the array of contacts
    public static func getContacts(completion:@escaping (_ success:Bool, _ results:[[String:Any]]) ->Void) {
        getContacts(fields: defaultKeys, completion: completion)
    }
}
