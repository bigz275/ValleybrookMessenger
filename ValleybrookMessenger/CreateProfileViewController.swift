//
//  CreateProfileViewController.swift
//  ValleybrookMessenger
//
//  Created by Adam Zarn on 9/6/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import UIKit
import Firebase

class CreateProfileViewController: UIViewController, UITextFieldDelegate {
    
    //Outlets*******************************************************************
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var verifyPasswordTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    //Local Variables***********************************************************
    
    var comingFromLogin = true
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //Life Cycle Functions*******************************************************

    override func viewDidLoad() {
        
        let toolbarDone = UIToolbar.init()
        toolbarDone.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        let barBtnDone = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.Done
                                            ,target: self
            , action: #selector(doneButtonPressed))
        
        toolbarDone.items = [flex,barBtnDone] // You can even add cancel button too
        nameTextField.inputAccessoryView = toolbarDone
        emailTextField.inputAccessoryView = toolbarDone
        phoneTextField.inputAccessoryView = toolbarDone
        passwordTextField.inputAccessoryView = toolbarDone
        verifyPasswordTextField.inputAccessoryView = toolbarDone
        
        nameTextField.delegate = self
        emailTextField.delegate = self
        phoneTextField.delegate = self
        passwordTextField.delegate = self
        verifyPasswordTextField.delegate = self
        
        setUp(nameTextField)
        setUp(emailTextField)
        setUp(phoneTextField)
        setUp(passwordTextField)
        setUp(verifyPasswordTextField)
        
        submitButton.setTitleColor(appDelegate.darkValleybrookBlue, forState: .Normal)
        
        verifyPasswordTextField.enabled = false
        
        activityIndicatorView.hidden = true
        
        cancelButton.tintColor = appDelegate.darkValleybrookBlue
    
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if comingFromLogin {
            emailTextField.enabled = true
        } else {
            navItem.title = "Edit Profile"
            emailTextField.enabled = false
            passwordTextField.hidden = true
            verifyPasswordTextField!.hidden = true
            passwordTextField!.enabled = false
            verifyPasswordTextField!.enabled = false
            submitButton.setTitle("Submit Changes", forState: .Normal)
            
            if Methods.sharedInstance.hasConnectivity() {
                
                FirebaseClient.sharedInstance.getUserData { (users, error) -> () in
                    if let users = users {
                        let user = users[self.appDelegate.uid!] as! NSDictionary
                        self.nameTextField.text = user["name"] as? String
                        self.emailTextField.text = user["email"] as? String
                        let phone = user["phone"] as! String
                        self.phoneTextField.text = Methods.sharedInstance.formatPhoneNumber(phone)
                    } else {
                        let dataErrorAlert:UIAlertController = UIAlertController(title: "Error", message: "Your profile could not be retrieved from the server. Try again later.",preferredStyle: UIAlertControllerStyle.Alert)
                        dataErrorAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                        self.presentViewController(dataErrorAlert, animated: true, completion: nil)
                    }
                }
            } else {
                let networkConnectivityError = UIAlertController(title: "No Internet Connection", message: "Please check your connection.", preferredStyle: UIAlertControllerStyle.Alert)
                networkConnectivityError.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(networkConnectivityError, animated: false, completion: nil)
            }
        }
    }
    
    //Methods*******************************************************************
    
    func doneButtonPressed() {
        self.view.endEditing(true)
    }
    
    func setUp(object: AnyObject?) {
        object!.layer.cornerRadius = 5
        object!.layer.borderColor = appDelegate.lightValleybrookBlue.CGColor
        object!.layer.borderWidth = 1
    }
    
    func endWithError(message: String) {
        let createProfileErrorAlert = UIAlertController(title: "Error", message: "Error", preferredStyle: UIAlertControllerStyle.Alert)
        createProfileErrorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        createProfileErrorAlert.message = message
        self.presentViewController(createProfileErrorAlert, animated: true, completion: nil)
        Methods.sharedInstance.toggleActivityIndicator(self.activityIndicatorView)
    }
    
    func setDisplayName(user: FIRUser) {
        let changeRequest = user.profileChangeRequest()
        changeRequest.displayName = user.email!.componentsSeparatedByString("@")[0]
        changeRequest.commitChangesWithCompletion(){ (error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.signedIn(FIRAuth.auth()?.currentUser)
        }
    }
    
    func signedIn(user: FIRUser?) {
        
        FirebaseClient.sharedInstance.addNewUser(user!.uid, name: nameTextField.text!, email: user!.email!, phone: Methods.sharedInstance.undoPhoneNumberFormat(phoneTextField.text!))
        
        MeasurementHelper.sendLoginEvent()
        
        AppState.sharedInstance.displayName = user?.displayName ?? user?.email
        AppState.sharedInstance.photoUrl = user?.photoURL
        AppState.sharedInstance.signedIn = true
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.SignedIn, object: nil, userInfo: nil)
        let navController = self.storyboard?.instantiateViewControllerWithIdentifier("NavigationController") as! UINavigationController
        self.presentViewController(navController, animated: false, completion: nil)
        Methods.sharedInstance.toggleActivityIndicator(self.activityIndicatorView)
        
    }

    //Text Field Functions*******************************************************
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.becomeFirstResponder()
        if passwordTextField.editing || verifyPasswordTextField.editing {
            textField.secureTextEntry = true
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if passwordTextField == textField || verifyPasswordTextField == textField {
            if textField.text == "" {
                textField.secureTextEntry = false
            }
        }
        if passwordTextField.text != "" {
            verifyPasswordTextField.enabled = true
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if passwordTextField.editing || verifyPasswordTextField.editing {
            if textField.text == "" {
                textField.secureTextEntry = false
            }
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if (textField == phoneTextField) {
            let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
            let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            
            let decimalString = components.joinWithSeparator("") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.characterAtIndex(0) == (1 as unichar)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11 {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne {
                formattedString.appendString("1 ")
                index += 1
            }
            if (length - index) > 3 {
                let areaCode = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("(%@) ", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            let remainder = decimalString.substringFromIndex(index)
            formattedString.appendString(remainder)
            textField.text = formattedString as String
            return false
        } else {
            return true
        }
    }
    
    //Actions*******************************************************************
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func submitButtonPressed(sender: AnyObject) {
        
        if Methods.sharedInstance.hasConnectivity() {
        
            let unformattedPhone = Methods.sharedInstance.undoPhoneNumberFormat(phoneTextField.text!)
            
            Methods.sharedInstance.toggleActivityIndicator(self.activityIndicatorView)
            
            if comingFromLogin {
                
                if passwordTextField.text != verifyPasswordTextField.text {
                    
                    self.endWithError("The second password does not match the first.")
                    
                } else if unformattedPhone.characters.count != 10 {
                    
                    self.endWithError("Your phone number must be exactly 10 digits long.")
                    
                } else if nameTextField.text! == "" {
                    
                    self.endWithError("You must provide a name.")
                    
                } else {
                    
                    let email = emailTextField.text
                    let password = passwordTextField.text
                    FIRAuth.auth()?.createUserWithEmail(email!, password: password!) { (user, error) in
                        if let error = error {
                            let createProfileErrorAlert = UIAlertController(title: "Error", message: "Error", preferredStyle: UIAlertControllerStyle.Alert)
                            createProfileErrorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                            createProfileErrorAlert.message = error.localizedDescription
                            self.presentViewController(createProfileErrorAlert, animated: true, completion: nil)
                            Methods.sharedInstance.toggleActivityIndicator(self.activityIndicatorView)
                            return
                        }
                        self.setDisplayName(user!)
                    }
                }
                
            } else {
                
                if unformattedPhone.characters.count == 10 && nameTextField.text! != "" {
                    
                    FirebaseClient.sharedInstance.updateUserInfo(nameTextField.text!, email: emailTextField.text!, phone: unformattedPhone)
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                    
                } else {
                    if unformattedPhone.characters.count != 10 {
                        self.endWithError("Your phone number must be exactly 10 digits long.")
                    } else {
                        self.endWithError("You must provide a name.")
                    }
                }
                
            }
        } else {
            let networkConnectivityError = UIAlertController(title: "No Internet Connection", message: "Please check your connection.", preferredStyle: UIAlertControllerStyle.Alert)
            networkConnectivityError.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(networkConnectivityError, animated: false, completion: nil)
        }
        
    }
    
    @IBAction func passwordChanged(sender: AnyObject) {
        if passwordTextField.text != "" {
            verifyPasswordTextField.enabled = true
        } else {
            verifyPasswordTextField.enabled = false
        }
    }


}
