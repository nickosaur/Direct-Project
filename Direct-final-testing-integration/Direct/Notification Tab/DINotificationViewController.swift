//
//  DINotificationViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/28/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DINotificationViewController.swift
 *
 * This file is used to handle the user’s interaction with the Notification tab
 * of the application. In Direct, the notification tab will display to a user the
 * list of their notifications, which may pertain to events which they have
 * expressed interest in or to users whom they have subscribed to.
 */

import UIKit

class DINotificationViewController: DIEventDetailPushableViewController {
    // set up parameters for overall content layout
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.estimatedRowHeight = self.tableView.rowHeight
            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.refreshControl = self.refreshControl
            self.tableView.registerNibCell(forClassName: DINotificationTableViewCell.className)
        }
    }
    
    /* addEventButtonTapped
     *
     * This function is used to handle the event where the user presses the
     * “Add Event” button. In this case, the user will be redirected to a prompt to
     * create their event.
     */
    @IBAction func addEventButtonTapped(_ sender: UIButton) {
        sender.animateBounceView()
        if let createEventVC = DIApp.Storyboard.main.instantiateViewController(withIdentifier: DICreateEventViewController.className) as? DICreateEventViewController {
            createEventVC.delegate = self
            self.present(createEventVC, animated: true, completion: nil)
        }
    }
    
    // for refreshing the page
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(didRefresh(_:)), for: .valueChanged)
        return control
    }()
    
    // load notifications if they haven't been loaded yet
    var notifications: [DINotification]? {
        didSet {
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }
    
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadNotification()
        
    }

    /* loadNotification
     *
     * This will get all recent notifications that were sent to the user and save them
     * so they can be loaded for displaying.
     */
    func loadNotification() {
        DINotification.fetchNotification { (notifications) in
            if let notifications = notifications {
                self.notifications = notifications.sorted(by: { (n1, n2) -> Bool in
                    return n1.deliverTimestamp ?? 0 > n2.deliverTimestamp ?? 0
                })
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    /* didRefresh
     *
     * This function is used to handle the event when the user refreshes the page.
     * It will update the UI to reflect the current state the tab should be in.
     */
    @objc func didRefresh(_ control: UIRefreshControl) {
        self.loadNotification()
    }
}

extension DINotificationViewController: StoryboardInstantiable {
    /* instantiateFromStoryboard
     *
     * This function will instantiate the view from the storyboard.
     */
    static func instantiateFromInstoryboard() -> DINotificationViewController{
        return DIApp.Storyboard.notification.instantiateViewController(withIdentifier: DINotificationViewController.className) as! DINotificationViewController
    }
}

extension DINotificationViewController: UITableViewDelegate, UITableViewDataSource {
    /* numberOfSections
     *
     * This function is used to define how many sections will be presented.
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /* tableView
     *
     * This function will add information to the cell pertaining to an event
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notifications?.count ?? 0
    }
    
    /* tableView
     *
     * This function will load a notification into a cell to be displayed.
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DINotificationTableViewCell.className, for: indexPath) as! DINotificationTableViewCell
        cell.notification = self.notifications?[indexPath.row]
        return cell
    }
    
    /* tableView
     *
     * This function will load a notification into a cell to be displayed.
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let event = self.notifications?[indexPath.row].event else {
            return
        }
        self.pushEventDetailVC(withEvent: event)
    }
}

// MARK : - DICreateEventViewControllerDelegate
extension DINotificationViewController: DICreateEventViewControllerDelegate {
    func didFinishAddingEvent() {
        // TODO: Handle the logic after adding event
    }
}

