//
//  DIHomeViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/22/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIHomeViewController.swift
 *
 * This file is used to handle the user’s interaction with the home screen
 * of the application. In Direct, the home screen is a feed of events which
 * are currently taking place. The user should be able to scroll down a list
 * of events and view preview videos/photos posted by the creators of the
 * events, as well as see the titles. Upon clicking on an event, they can
 * see a more detailed view. They also have the option on this page to add
 * their own events through pressing an “Add Event” button.
 */

import UIKit

class DIHomeViewController: DIEventDetailPushableViewController {
    
    private let initialRequestRadius: Double = 5.0
    
    // set the characteristics for the view layout
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.estimatedRowHeight = self.tableView.rowHeight
            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.refreshControl = self.refreshControl
            self.tableView.registerNibCell(forClassName: DIFeaturedTableViewCell.className)
            self.tableView.registerNibCell(forClassName: DIPhotoTypeEventTableViewCell.className)
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
    
    // loads events if they haven’t been loaded yet
    var events: [DIEvent]? {
        didSet {
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }
    
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(openEventDetailFromNotification(_:)), name: DIApp.DINotification.OpenEventDetailFromRemoteNotification.name, object: nil)
        self.loadEvent()
    }
    
    /* viewDidAppear
     *
     * This function is used for the presentation of the view.
     */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    /* didReceiveMemoryWarning
     *
     * This function releases memory used by the view controller when there is a low
     * amount of available memory.
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* openEventDetailFromNotification
     *
     * This function is used in the case that the user entered the app through
     * pressing a notification. In this case, they should be immediately redirected
     * to the details of the event which the notification pertained to.
     */
    @objc func openEventDetailFromNotification(_ notification: Notification) {
        if let event = notification.userInfo?[DIApp.DINotification.OpenEventDetailFromRemoteNotification.eventInfoKey] as? DIEvent {
            self.pushEventDetailVC(withEvent: event)
        }
    }
    
    /* loadEvent
     *
     * This will get all the current events and save them so they can be loaded
     * for displaying.
     */
    func loadEvent() {
        let currentLocation = DILocationManager.getCurrentLocation()
        DIEvent.fetchEvents { (events) in
            if let events = events {
                let endedEvents = events.filter({ (e) -> Bool in
                    return !e.isUpcoming && !e.isLive
                })
                    
                let liveEvents = events.filter({ (e) -> Bool in
                    return e.isLive
                }).sorted(by: { (e1, e2) -> Bool in
                    if let currentLocation = currentLocation {
                        return (e1.location?.clLocation?.distance(from: currentLocation) ?? 0) < (e2.location?.clLocation?.distance(from: currentLocation) ?? 0)
                    } else {
                        return true
                    }
                })
                self.events = liveEvents + endedEvents
            }
        }
    }
    
    /* didRefresh
     *
     * This function is used to handle the event when the user refreshes the page.
     * It will update the UI to reflect the tab the user is currently viewing.
     */
    @objc func didRefresh(_ control: UIRefreshControl) {
       self.loadEvent()
    }
}

/* instantiateFromStoryboard
 *
 * This function will instantiate the view from the storyboard.
 */
// MARK: - StoryboardInstantiable
extension DIHomeViewController: StoryboardInstantiable {
    static func instantiateFromInstoryboard() -> DIHomeViewController {
        return DIApp.Storyboard.home.instantiateViewController(withIdentifier: DIHomeViewController.className) as! DIHomeViewController
    }
}


// MARK : - UITableViewDelegate, UITableViewDataSource
extension DIHomeViewController: UITableViewDelegate, UITableViewDataSource {
    /* numberOfSections
     *
     * This function is used to define how many sections will be presented.
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /* tableView
     *
     * This function will define how many rows will be presented based on how
     * many events exist.
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events?.count ?? 0
    }
    
    /* tableView
     *
     * This function will load an event into a cell to be displayed.
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let event = self.events?[indexPath.row] else {
            return UITableViewCell()
        }
        var cell: DIEventCell!
        if event.isVideoEvent {
            cell = tableView.dequeueReusableCell(withIdentifier: DIFeaturedTableViewCell.className, for: indexPath) as! DIFeaturedTableViewCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: DIPhotoTypeEventTableViewCell.className, for: indexPath) as! DIPhotoTypeEventTableViewCell
        }
        cell.event = event
        return cell
    }
    
    /* tableView
     *
     * This function will add information to the cell pertaining to an event
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let event = self.events?[indexPath.row] else {
            return
        }
        self.pushEventDetailVC(withEvent: event)
    }
}

/* didFinishAddingEvent
 *
 * This function will delegate to load the events from the database.
 */
// MARK : - DICreateEventViewControllerDelegate
extension DIHomeViewController: DICreateEventViewControllerDelegate {
    func didFinishAddingEvent(_ event: DIEvent?) {
        if let event = event {
            self.loadEvent()
            self.pushEventDetailVC(withEvent: event)
        }
    }
}



