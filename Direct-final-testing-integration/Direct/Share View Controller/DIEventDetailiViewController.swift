//
//  DIEventDetailiViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/19/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIEventDetailViewController.swift
 *
 * This file is used to handle the user’s interaction when in Event Detail viewing
 * mode. In Direct, whenever you click on an event, you get redirected to a page
 * with additional details about that event. When on this page, you can view a
 * description of the event, as well as details such as time/location/host, etc. If
 * the event is live and the user has checked in, they may also post their own
 * media content to be displayed for other users of the application who are
 * interested in the event.
 */

import UIKit
fileprivate let sectionHeaderHeight: CGFloat = 42.0

class DIEventDetailiViewController: UIViewController {
    // set up parameters for overall content layout
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.estimatedRowHeight = self.tableView.rowHeight
            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.refreshControl = self.refreshControl
            self.tableView.registerNibCell(forClassName: DIEventDetailContentTableViewCell.className)
            self.tableView.registerNibCell(forClassName: DIEventMomentTableViewCell.className)
        }
    }
    
    /* backBtnTapped
     *
     * This function is used to handle the event when the user presses the back
     * button. The user should be redirected back to the tab where they clicked
     * on the event from.
     */
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // label indicating event status, based on relational time
    @IBOutlet weak var statusBoldLabel: UILabel!
    
    // plus button to add an event to the moment
    @IBOutlet weak var shareMomentBtn: UIButton! {
        didSet {
            guard let eve = self.event else {
                return
            }
            guard let currentUser = DIAuth.auth.current else {
                shareMomentBtn.alpha = 0.8
                return
            }
            shareMomentBtn.alpha = currentUser.isUserCheckedIn(forEvent: eve) ? 1 : 0.8
        }
    }
    
    /* shareMomentBtnTapped
     *
     * This function is used to handle the event when the user presses the “share"
     * button. In this case, we delegate to another class to create the moment and
     * provide the user with prompts about what content they wish to upload,
     * and then the content will be created and saved.
     */
    @IBAction func shareMomentBtnTapped(_ sender: UIButton) {
        sender.animateBounceView()
        guard let eve = self.event else {
            return
        }
        guard let currentUser = DIAuth.auth.current else {
            return
        }
        if currentUser.isUserCheckedIn(forEvent: eve) {
            let createEventMomentVC = DICreateEventMomentViewController.instantiateFromInstoryboard()
            createEventMomentVC.delegate = self
            createEventMomentVC.event = self.event
            DispatchQueue.main.async {
                self.present(createEventMomentVC, animated: true, completion: nil)
            }
        } else {
            let popup = Popup()
            popup.displayPopup(title: "Please check in", description: "Check in to the event to share moment", buttonTitle: "Ok", view: self)
            print("Check in to the event to share moment")
        }
    }
    
    // label displays relational time to now
    @IBOutlet weak var statusTimeLabel: UILabel!
    // button user clicks to get directions from current location to event
    @IBOutlet weak var goButton: UIButton! {
        didSet {
            self.goButton.layer.cornerRadius = self.goButton.frame.size.height / 2
            self.goButton.clipsToBounds = true
        }
    }
    
    // dot indicates whether event is live or upcoming
    @IBOutlet weak var eventStatusDotView: DIEventStatusDotView!
    
    /* goButtonTapped
     *
     * This function is used to handle the event when the user presses the “go”
     * button. In this case, the application will confirm whether the user is in the
     * general vicinity or not, and if they are, then it will allow the user to be “checked
     * in”, so that they are able to upload content to the feed of that event.
     */
    @IBAction func goButtonTapped(_ sender: UIButton) {
        //TODO: Tap should open google map and use the event location as the destination,
        // the current user location as the default.
        self.openNavigation()
    }
    
    @IBOutlet weak var eventRespondBtn: UIButton!
    
    /* eventRespondBtnTapped
     *
     * This function is used to handle the event when the user presses the “RSVP”
     * button. In this case, we should switch the state of the user’s RSVP status.
     * That is to say, if the user was previously RSVP’d to the event they should no
     * longer be, and vice versa.
     */
    @IBAction func eventRespondBtnTapped(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        guard let currentUser = DIAuth.auth.current else {
            return
        }
        guard let ev = self.event else {
            return
        }
        if ev.isUpcoming {
            //  check the user rsvp state, if haven't, then rsvp, otherwise, unrsvp
            if currentUser.isUserRsvp(forEvent: ev) {
                ev.unrsvp(completionHandler: { (e) in
                    if e != nil {
                        self.setRSVPBtnUI(status: .deactive)
                    }
                    sender.isUserInteractionEnabled = true
                    // post a notification that the upcoming UI should update
                    self.sendUpcomingUIShouldRefreshNotification()
                })
            } else {
                // RSVP for the current authenticated user
                ev.rsvp(completionHandler: { (e) in
                    if e != nil {
                        triggerFeedbackImpact()
                        self.setRSVPBtnUI(status: .active)
                    }
                    sender.isUserInteractionEnabled = true
                    // post a notification that the upcoming UI should update
                    self.sendUpcomingUIShouldRefreshNotification()
                })
            }
        } else {
            if ev.isCheckInAllowed() {
                print("let's check in")
                if currentUser.isUserCheckedIn(forEvent: ev) {
                    // uncheck-in
                    ev.unCheckIn(completionHandler: { (e) in
                        if e != nil {
                            self.setCheckInBtnUI(status: .deactive)
                        }
                        sender.isUserInteractionEnabled = true
                    })
                } else {
                    ev.checkIn(completionHandler: { (e) in
                        if e != nil {
                            triggerFeedbackImpact()
                            self.setCheckInBtnUI(status: .active)
                        }
                        sender.isUserInteractionEnabled = true
                    })
                }
            } else {
                let popup = Popup()
                sender.isUserInteractionEnabled = true
                popup.displayPopup(title: "Too far from the event", description: "Please move closer to the event location to check in", buttonTitle: "Ok", view: self)
                print("Please move closer to the event location to check in")
            }
            
        }
    }
    
    // Date
    private lazy var dateFormatter: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "EEEE, MMM d, yyyy  h:mm a"
        return format
    }()
    
    
    var event: DIEvent! {
        didSet {
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.tableView?.reloadData()
            }
        }
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(didRefresh(_:)), for: .valueChanged)
        return control
    }()
    
    func sendUpcomingUIShouldRefreshNotification() {
        let notification = Notification(name: DIApp.DINotification.UpcomingUIShouldRefresh.name)
        NotificationCenter.default.post(notification)
    }

    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        if let ev = self.event{
            self.tableView.reloadData()
            guard let currentUser = DIAuth.auth.current else {
                return
            }
            if ev.isUpcoming {
                self.adjustStatusLabelUI()
                if currentUser.isUserRsvp(forEvent: ev) {
                    self.setRSVPBtnUI(status: .active)
                } else {
                    self.setRSVPBtnUI(status: .deactive)
                }
                let startDate = Date(timeIntervalSince1970: ev.startTimeStamp ?? 0)
                self.statusTimeLabel.text = "In \(upcomingIn(toDate: startDate))"
            } else {
                self.adjustStatusLabelUI()
                if ev.isLive {
                    self.eventStatusDotView.setStyle(style: .live)
                    if currentUser.isUserCheckedIn(forEvent: ev){
                        self.setCheckInBtnUI(status: .active)
                    } else {
                        self.setCheckInBtnUI(status: .deactive)
                    }
                } else {
                    self.eventStatusDotView.setStyle(style: .ended)
                    self.eventRespondBtn.setTitle("Event Ended", for: .normal)
                    self.eventRespondBtn.setImage(nil, for: .normal)
                    self.eventRespondBtn.isUserInteractionEnabled = false
                }
                self.statusTimeLabel.text = DITime.getEndTimePrettyFormat(endTime: ev.endTimeStamp ?? 0)
            }
        }
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
    
    /* adjustStatusLabelUI
     *
     * This function is used to set the status label for the event, which is based on
     * on the relational time of the event to the current time.
     */
    private func adjustStatusLabelUI() {
        if self.event.isUpcoming {
            self.statusBoldLabel.textColor = DIApp.Style.Color.upcomingYellow
            self.statusBoldLabel.text = "UPCOMING"
        } else if self.event.isLive{
            self.statusBoldLabel.textColor = DIApp.Style.Color.liveRed
            self.statusBoldLabel.text = "LIVE"
        } else {
            self.statusBoldLabel.textColor = DIApp.Style.Color.endedGray
            self.statusBoldLabel.text = "ENDED"
        }
    }
    
    /* didRefresh
     *
     * This function is used when the page is refreshed, in which case it should reload
     * the view.
     */
    @objc func didRefresh(_ control: UIRefreshControl) {
        guard let event = self.event else {
            return
        }
        DIEvent.fetchEvent(withKey: event.id) { (event) in
            self.event = event
        }
    }
    
    // if button is set in RSVP'd/checked in state or not
    enum DIBtnStatus {
        case active
        case deactive
    }
    
    /* setRSVPBtnUI
     *
     * This function is used to set the state of the button display for a user who
     * is changing their RSVP status.
     */
    func setRSVPBtnUI(status: DIBtnStatus) {
        if status == .active {
            self.eventRespondBtn.setTitle("RSVPED", for: .normal)
            self.eventRespondBtn.setImage(#imageLiteral(resourceName: "checked-in-icon"), for: .normal)
        } else {
            self.eventRespondBtn.setTitle("RSVP", for: .normal)
            self.eventRespondBtn.setImage(#imageLiteral(resourceName: "check-in-icon"), for: .normal)
        }
    }
    
    /* setCheckInBtnUI
     *
     * This function is used to set the state of the button display for a user who
     * is changing their check in status.
     */
    func setCheckInBtnUI(status: DIBtnStatus) {
        if status == .active {
            self.eventRespondBtn.setTitle("Checked In", for: .normal)
            self.eventRespondBtn.setImage(#imageLiteral(resourceName: "checked-in-icon"), for: .normal)
        } else {
            self.eventRespondBtn.setTitle("Check In", for: .normal)
            self.eventRespondBtn.setImage(#imageLiteral(resourceName: "check-in-icon"), for: .normal)
        }
    }
    
    /* openNavigation
     *
     * This function is used to open the navigation view after the user taps the go
     * button. In this case, the Google Maps API will be opened, with directions
     * from the user’s current location to the event location.
     */
    func openNavigation() {
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
            guard let lat = event.location?.coordinate?.latitude else {
                return
            }
            guard let long = event.location?.coordinate?.longitude else {
                return
            }
            UIApplication.shared.open(URL(string: "comgooglemaps://?saddr=&daddr=\(lat),\(long)&directionsmode=driving")! as URL)
        } else {
            NSLog("Can't use com.google.maps://");
        }
    }
}

// MARK: - StoryboardInstantiable
extension DIEventDetailiViewController: StoryboardInstantiable {
    /* instantiateFromStoryboard
     *
     * This function will instantiate the view from the storyboard.
     */
    static func instantiateFromInstoryboard() -> DIEventDetailiViewController{
        return DIApp.Storyboard.main.instantiateViewController(withIdentifier: DIEventDetailiViewController.className) as! DIEventDetailiViewController
    }
}


// MARK : - UITableViewDelegate, UITableViewDataSource
extension DIEventDetailiViewController: UITableViewDelegate, UITableViewDataSource {
    /* numberOfSections
     *
     * This function is used to define how many sections will be presented.
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    /* tableView
     *
     * This function will define how many rows will be presented based on how
     * many event moments exist.
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return self.event?.moments?.count ?? 0
        } else {
            return 0
        }
    }
    
    /* tableView
     *
     * This function will load an event moment into a cell to be displayed.
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: DIEventDetailContentTableViewCell.className, for: indexPath) as! DIEventDetailContentTableViewCell
            cell.event = self.event
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: DIEventMomentTableViewCell.className, for: indexPath) as! DIEventMomentTableViewCell
            cell.moment = self.event?.moments?[indexPath.row]
            return cell
        }
        return UITableViewCell()
    }
    
    /* tableView
     *
     * This function will load the event header into the first section.
     */
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            return Bundle.main.loadNibNamed(DIGuestTableHeaderView.className, owner: self, options: nil)?.first as? DIGuestTableHeaderView
        }
        return nil
    }
    
    /* tableView
     *
     * This function will define the height for each aspect of the view.
     */
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return sectionHeaderHeight
        }
        return 0
    }
}

extension DIEventDetailiViewController: DICreateEventMomentViewControllerDelegate {
    /* didFinishAddingEventMoment
     *
     * This function will delegate to load the event moments from the database.
     */
    func didFinishAddingEventMoment(moment: DIMoment?) {
        DIEvent.fetchEvent(withKey: event.id) { (event) in
            self.event = event
        }
    }
}

