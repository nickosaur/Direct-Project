//
//  DIUpcomingViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIUpcomingViewController.swift
 *
 * This file is used to handle the user’s interaction with the upcoming tab
 * of the application. In Direct, the upcoming tab is a feed of events which
 * are yet to happen. The user should be able to scroll down a list
 * of events and view preview videos/photos posted by the creators of the
 * events, as well as see the titles. Upon clicking on an event, they can
 * see a more detailed view. They also have the option on this page to add
 * their own events through pressing an “Add Event” button.
 */

import UIKit

class DIUpcomingViewController: DIEventDetailPushableViewController {
    // set parameters for each aspect of the view
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.estimatedRowHeight = self.tableView.rowHeight
            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.refreshControl = self.refreshControl
            self.tableView.registerNibCell(forClassName: DIUpcomingTableViewCell.className)
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

    // reload view if no events
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
        self.loadEvent()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData(_:)), name: DIApp.DINotification.UpcomingUIShouldRefresh.name, object: nil)
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
    
    /* loadEvent
     *
     * This will get all upcoming events and save them so they can be loaded
     * for displaying.
     */
    func loadEvent() {
        // load 10 each fetch, gradually increasing the distance, usingO chronological order
        // for example:
        // start with radius equals to 5, sort all the events from this fetch by starting time (this might return more posts than we want,
        // use a DIEventFetchingManager to keep track of how many availabe events do we have)
        // continue to load using radius equals to 5 see, whether there is any, if not, increase the radius to 10, repeat the process
        
        DIEvent.fetchEvents  { (events) in
            if let events = events {
                self.events = events.filter({ (e) -> Bool in
                    return e.isUpcoming
                }).sorted(by: { (e1, e2) -> Bool in
                    return e1.startTimeStamp ?? 0 < e2.startTimeStamp ?? 0
                })
            }
        }
//        DIEvent.fetchEventNearby(radius: 300, sortOption: .upcoming) { (events) in
//            if let events = events {
//                self.events = events.filter({ (e) -> Bool in
//                    return e.isUpcoming
//                })
//            }
//        }
    }
    
    /* didRefresh
     *
     * This function is used when the page is refreshed, in which case it should reload
     * the view.
     */
    @objc func didRefresh(_ control: UIRefreshControl) {
       self.loadEvent()
    }
    
    @objc func reloadData(_ notification: Notification) {
        self.loadEvent()
    }
}


extension DIUpcomingViewController: StoryboardInstantiable {
    /* instantiateFromStoryboard
     *
     * This function will instantiate the view from the storyboard.
     */
    static func instantiateFromInstoryboard() -> DIUpcomingViewController{
        return DIApp.Storyboard.upcoming.instantiateViewController(withIdentifier: DIUpcomingViewController.className) as! DIUpcomingViewController
    }
}

extension DIUpcomingViewController: UITableViewDelegate, UITableViewDataSource {
    /* numberOfSections
     *
     * This function is used to define how many sections will be presented.
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /* tableView
     *
     * This function will define the number of rows based on the number of events to
     * be displayed.
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events?.count ?? 0
    }
    
    /* tableView
     *
     * This function will load an event into a cell to be displayed.
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DIUpcomingTableViewCell.className, for: indexPath) as! DIUpcomingTableViewCell
        cell.event = self.events?[indexPath.row]
        return cell
    }
    
    /* tableView
     *
     * This function will load the details of the event when the event is selected.
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let event = self.events?[indexPath.row] else {
            return
        }
        self.pushEventDetailVC(withEvent: event)
    }
}

// MARK : - DICreateEventViewControllerDelegate
extension DIUpcomingViewController: DICreateEventViewControllerDelegate {
    /* didFinishAddingEvent
     *
     * This function handles the logic after an event is added.
     */
    func didFinishAddingEvent(_ event: DIEvent?) {
        if let event = event {
            self.pushEventDetailVC(withEvent: event)
        }
    }
}
