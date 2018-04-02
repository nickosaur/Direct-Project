//
//  DIProfileViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/19/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIProfileViewController.swift
 *
 * This file is used to handle the user’s interaction with the Profile tab of
 * the application. In Direct, the Profile is a place where the user can view
 * all of the events which they have attended or planned to attend, as well
 * as the events they have created themselves. The user should have the
 * option to see, in separate tabs, future events, past events, and hosted
 * events.
 */

import UIKit

// colors for different states
fileprivate let DICountDeactiveColorHex = "#D6D5D5"
fileprivate let DICountActiveColorHex = "#000000"

class DIProfileViewController: DIEventDetailPushableViewController {
    // set parameters for profile image display
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            self.profileImageView.contentMode = .scaleAspectFill
            self.profileImageView.backgroundColor = DIApp.Style.Color.grayColor
            self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height / 2
            self.profileImageView.clipsToBounds = true
        }
    }
    
    @IBOutlet weak var fullnameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.estimatedRowHeight = self.tableView.rowHeight
            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.refreshControl = self.refreshControl
            self.tableView.registerNibCell(forClassName: DIUpcomingTableViewCell.className)
            self.tableView.registerNibCell(forClassName: DIFeaturedTableViewCell.className)
        }
    }
    
    // labels for the counts under each category
    @IBOutlet weak var visitedCountLabel: UILabel!
    @IBOutlet weak var plannedCountLabel: UILabel!
    @IBOutlet weak var hostedCountLabel: UILabel!
    
    
    // visited
    @IBOutlet weak var visitedStackView: UIStackView!
    @IBOutlet weak var visitedFilterLabel: UILabel!
    @IBOutlet weak var visitedHightlightBar: UIView!
    
    // handle event when user taps visited tab
    @IBAction func visitedFilterTapped(_ sender: UITapGestureRecognizer) {
        self.currentTabIndex = 0
        self.loadVistedEvent()
    }
    
    // planned
    @IBOutlet weak var plannedStackView: UIStackView!
    @IBOutlet weak var plannedFilterLabel: UILabel!
    @IBOutlet weak var plannedHightlightBar: UIView!
    
    @IBAction func plannedFilterTapped(_ sender: UITapGestureRecognizer) {
        self.currentTabIndex = 1
        self.loadPlannedEvent()
    }
    
    // hosted
    @IBOutlet weak var hostedStackView: UIStackView!
    @IBOutlet weak var hostedFilterLabel: UILabel!
    @IBOutlet weak var hostedHightlightBar: UIView!
    
    // handle event when user presses hosted tab
    @IBAction func hostedFilterTapped(_ sender: UITapGestureRecognizer) {
        self.currentTabIndex = 2
        self.loadHostedEvent()
    }

    // handles event when user taps edit button
    @IBAction func editBtnTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let editProfileAction = UIAlertAction(title: "Edit Profile", style: .default) { _ in
            self.pushEditProfileVC()
        }
        let editSettingsAction = UIAlertAction(title: "Logout", style: .default) { _ in
            DIAuth.signout {
                let notification = Notification(name: DIApp.DINotification.AccountSignOut.name)
                NotificationCenter.default.post(notification)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(editProfileAction)
        alert.addAction(editSettingsAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    var currentTabIndex = 0
    
    // make sure event data is loaded into tableView
    var events: [DIEvent]? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // for refreshing the page
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(didRefresh(_:)), for: .valueChanged)
        return control
    }()

    // the user who is logged in
    private var currentUser: DIUser? {
        return DIAuth.auth.current
    }
    
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
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
    
    /* updateUI
     *
     * This function will refresh the UI to display the current user information. It is
     * useful after some aspect of the profile has been edited, or the user changes
     * the events they are interested in.
     */
    private func updateUI() {
        guard let currentUser = self.currentUser else {
            return
        }
        self.fullnameLabel.text = currentUser.fullname
        self.bioLabel.text = currentUser.bio
        if let profileURL = currentUser.profileImageURL {
            self.profileImageView.loadImage(fromURL: profileURL)
        }
        self.updateCounts()
        self.loadVistedEvent()
    }
    
    /* updateCounts
     *
     * This function is used to keep track of the present, past, and hosted events
     * of the user. At the top of the profile tab, the number of events in each
     * category (visited, hosted, planned) for that user will appear, and if the
     * number for any category is 0 the text color of the number will be different
     * than if it is nonzero.
     */
    private func updateCounts() {
        let visitedCount = self.currentUser?.visitedEvents.count ?? 0
        let plannedCount = self.currentUser?.rsvpEvents.count ?? 0
        let hostedCount = self.currentUser?.hostedEvents.count ?? 0
        
        self.visitedCountLabel.textColor = (visitedCount == 0) ? UIColor(hexString: DICountDeactiveColorHex) : UIColor(hexString: DICountActiveColorHex)
        self.hostedCountLabel.textColor = (hostedCount == 0) ? UIColor(hexString: DICountDeactiveColorHex) : UIColor(hexString: DICountActiveColorHex)
        self.plannedCountLabel.textColor = (plannedCount == 0) ? UIColor(hexString: DICountDeactiveColorHex) : UIColor(hexString: DICountActiveColorHex)

        self.visitedCountLabel.text = "\(visitedCount)"
        self.plannedCountLabel.text = "\(plannedCount)"
        self.hostedCountLabel.text = "\(hostedCount)"
    }
    
    /* loadVisitedEvent
     *
     * This function is used to load the view for the visited event tab on a user’s
     * profile page.
     */
    private func loadVistedEvent() {
        self.visitedFilterLabel.textColor = DIApp.Style.Color.themeBlue
        self.plannedFilterLabel.textColor = DIApp.Style.Color.deactiveColor
        self.hostedFilterLabel.textColor = DIApp.Style.Color.deactiveColor
        self.hostedHightlightBar.isHidden = true
        self.plannedHightlightBar.isHidden = true
        self.visitedHightlightBar.isHidden = false

        if let currentUser = self.currentUser {
            currentUser.fetchVisitedEvents(completionBlock: { (events) in
                self.refreshControl.endRefreshing()
                if let events = events {
                    self.events = events
                }
            })
        }
    }

    /* loadPlannedEvent
     *
     * This function is used to load the view for the planned event tab on a user’s
     * profile page.
     */
    private func loadPlannedEvent() {
        self.plannedFilterLabel.textColor = DIApp.Style.Color.themeBlue
        self.visitedFilterLabel.textColor = DIApp.Style.Color.deactiveColor
        self.hostedFilterLabel.textColor = DIApp.Style.Color.deactiveColor

        self.hostedHightlightBar.isHidden = true
        self.visitedHightlightBar.isHidden = true
        self.plannedHightlightBar.isHidden = false

        if let currentUser = self.currentUser {
            currentUser.fetchRSVPEvents(completionBlock: { (events) in
                self.refreshControl.endRefreshing()
                if let events = events {
                    self.events = events.sorted(by: { (e1, e2) -> Bool in
                        return e1.startTimeStamp ?? 0 < e2.startTimeStamp ?? 0
                    })
                }
            })
        }
    }
    
    /* loadHostedEvent
     *
     * This function is used to load the view for the hosted event tab on a user’s
     * profile page.
     */
    private func loadHostedEvent() {
        self.plannedFilterLabel.textColor = DIApp.Style.Color.deactiveColor
        self.visitedFilterLabel.textColor = DIApp.Style.Color.deactiveColor
        self.hostedFilterLabel.textColor = DIApp.Style.Color.themeBlue
        self.plannedHightlightBar.isHidden = true
        self.visitedHightlightBar.isHidden = true
        self.hostedHightlightBar.isHidden = false

        if let currentUser = self.currentUser {
            currentUser.fetchHostedEvents(completionBlock: { (events) in
                self.refreshControl.endRefreshing()
                if let events = events {
                    self.events = events
                }
            })
        }
    }
    
    /* didRefresh
     *
     * This function is used to handle the event when the user refreshes the page.
     * It will update the UI to reflect the tab the user is currently viewing.
     */
    @objc private func didRefresh(_ control: UIRefreshControl) {
        self.currentTabIndex = 0
        self.currentUser?.refreshProfile(completionHanlder: { (_) in
            self.updateUI()
        })
    }
    
    /* pushEditSettingsVC
     *
     * This function is used when the user pushes the edit settings option. It will
     * change the view to display the editing page.
     */
    private func pushEditSettingsVC() {
        let editSettingsVC = DISettingsViewController.instantiateFromInstoryboard()
        editSettingsVC.delegate = self
        editSettingsVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(editSettingsVC, animated: true)
    }
    
    /* pushEditProfileVC
     *
     * This function is used when the user pushes the edit profile option. It will
     * change the view to display the editing page.
     */
    private func pushEditProfileVC() {
        let editProfileVC = DIEditProfileViewController.instantiateFromInstoryboard()
        editProfileVC.delegate = self
        editProfileVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(editProfileVC, animated: true)
    }
}

extension DIProfileViewController: StoryboardInstantiable {
    /* instantiateFromStoryboard
     *
     * This function will instantiate the view from the storyboard.
     */
    static func instantiateFromInstoryboard() -> DIProfileViewController{
        return DIApp.Storyboard.profile.instantiateViewController(withIdentifier: DIProfileViewController.className) as! DIProfileViewController
    }
}

extension DIProfileViewController: UITableViewDelegate, UITableViewDataSource {
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
        var cell: DIEventCell!
        switch currentTabIndex {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: DIFeaturedTableViewCell.className, for: indexPath) as! DIFeaturedTableViewCell
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: DIUpcomingTableViewCell.className, for: indexPath) as! DIUpcomingTableViewCell
        }
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

extension DIProfileViewController: DIEditProfileViewControllerDelegate {
    /* didFinishUpdatingProfile
     *
     * This function is used to reload the profile page settings after the user has
     * finished editing their settings.
     */
    func didFinishUpdatingProfile(currentUser: DIUser?) {
        self.fullnameLabel.text = currentUser?.fullname
        if let profileURL = currentUser?.profileImageURL {
            self.profileImageView.loadImage(fromURL: profileURL)
        }
    }
}

extension DIProfileViewController: DISettingsViewControllerDelegate {
    func didFinishUpdatingSettings(currentUser: DIUser?) {
        // TODO
    }
}

