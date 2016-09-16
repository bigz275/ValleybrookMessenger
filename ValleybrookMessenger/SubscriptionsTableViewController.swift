//
//  SubscriptionsTableViewController.swift
//  ValleybrookMessenger
//
//  Created by Adam Zarn on 9/6/16.
//  Copyright © 2016 Adam Zarn. All rights reserved.
//

import UIKit
import Firebase

class SubscriptionsTableViewController: UIViewController {
    
    //Outlets*******************************************************************

    @IBOutlet weak var editProfileButton: UIBarButtonItem!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    //Alerts********************************************************************
    
    let dataErrorAlert:UIAlertController = UIAlertController(title: "Error", message: "Data could not be retrieved from the server. Try again later.",preferredStyle: UIAlertControllerStyle.Alert)
    
    //Local Variables***********************************************************
    
    var groupsDict: [String:Bool] = [:]
    var groupKeys: [String] = []
    var subscribedToGroup: [Bool] = []
    
    //Life Cycle Functions*******************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataErrorAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        myTableView.hidden = true
        Methods.sharedInstance.toggleActivityIndicator(self.activityIndicatorView)
        
        myTableView.allowsSelection = false
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        barButton.title = "Logged in as \(appDelegate.email!)"
        barButton.enabled = false
        barButton.tintColor = appDelegate.darkValleybrookBlue
        
        if appDelegate.admin {
            barButton.title = "Manage Groups as Administrator"
            barButton.enabled = true
        }
        
        logoutButton.tintColor = appDelegate.darkValleybrookBlue
        editProfileButton.tintColor = appDelegate.darkValleybrookBlue
        
    }
    
    override func viewWillAppear(animated: Bool) {
        myTableView.hidden = true
        Methods.sharedInstance.toggleActivityIndicator(self.activityIndicatorView)
        updateGroups()
    }
    
    //Methods*******************************************************************
    
    func updateGroups() {
        
        FirebaseClient.sharedInstance.getGroupData { (groups, error) -> () in
            if let groups = groups {
                for group in groups {
                    let key = group.key as! String
                    if group.value is String {
                        self.groupsDict[key] = false
                    } else {
                        let emails = group.value["Emails"]!!.allValues as! [String]
                        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                        if emails.contains(appDelegate.email!) {
                            self.groupsDict[key] = true
                        } else {
                            self.groupsDict[key] = false
                        }
                    }
                }
            } else {
                self.presentViewController(self.dataErrorAlert, animated: true, completion: nil)
            }
            
            Methods.sharedInstance.toggleActivityIndicator(self.activityIndicatorView)
            self.myTableView.hidden = false
            self.myTableView.reloadData()
        }
    }
    
    //Table View Functions*******************************************************
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! CustomSubscriptionCell
        
        groupKeys = []
        subscribedToGroup = []
        
        let sortedGroupKeys = Array(groupsDict.keys).sort(<)
        
        for key in sortedGroupKeys {
            groupKeys.append(key)
            subscribedToGroup.append(groupsDict[key]!)
        }
        
        cell.setCell(groupKeys[indexPath.row], subscribed: subscribedToGroup[indexPath.row])
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 45.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsDict.count
    }
    
    //Actions*******************************************************************
    
    @IBAction func logoutButtonPressed(sender: AnyObject) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            AppState.sharedInstance.signedIn = false
            let loginVC = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
            self.presentViewController(loginVC, animated: false, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: \(signOutError)")
        }
        
    }
    
    @IBAction func manageGroupsButtonPressed(sender: AnyObject) {
        let groupsVC = storyboard?.instantiateViewControllerWithIdentifier("GroupsTableViewController") as! GroupsTableViewController
        self.navigationController?.pushViewController(groupsVC, animated: false)
        
    }
    
    @IBAction func editProfileButtonPressed(sender: AnyObject) {
        let createProfileVC = self.storyboard?.instantiateViewControllerWithIdentifier("CreateProfileViewController") as! CreateProfileViewController
        createProfileVC.comingFromLogin = false
        self.presentViewController(createProfileVC, animated: false, completion: nil)
    }

    
}
