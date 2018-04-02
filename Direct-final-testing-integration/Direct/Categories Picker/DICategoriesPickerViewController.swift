//
//  DICategoriesPickerViewController.swift
//  Direct
//
//  Created by Kesong Xie on 10/30/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DICategoriesPickerViewController.swift
 *
 * This file is used to handle user input when the user wishes to begin/continue
 * selecting categories for an event or for their own personal preferences. In
 * Direct, the user is provided with a limited number of options for categories
 * which they may select from. They are allowed to pick as many or as few
 * options from this list as they desire, and the information for selections will
 * be stored in the database for future reference.
 */

import UIKit

// set parameters for cell display
fileprivate let DICollectionViewCellMargin: CGFloat = 30.0
fileprivate let DICollectionViewCellHeight: CGFloat = 48
fileprivate let DINumberOfCellPerRow: Int = 2

// change the view when the user finishes selecting categories
protocol DICategoriesPickerViewControllerdelegate: class {
    func didFinishSelectingCategories(viewController:DICategoriesPickerViewController, categories: [String])
}

class DICategoriesPickerViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            self.collectionView.alwaysBounceVertical = true
            self.collectionView.allowsMultipleSelection = true
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.collectionView.registerNibCell(forClassName: DICategoryCollectionViewCell.className)
        }
    }
    
    /* closeBtnTapped
     *
     * This function will handle the event when the user presses the close button,
     * indicating that they no longer wish to proceed with category selection.
     */
    @IBAction func closeBtnTapped(_ sender: UIButton) {
        if let navigationVC = self.navigationController {
            navigationVC.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // button to close the category picking view
    @IBOutlet weak var closeBtn: UIButton! {
        didSet {
            self.closeBtn.isHidden = self.hideCloseButton
        }
    }
    
    // set the label of the screen title
    @IBOutlet weak var pickerTitleLabel: UILabel! {
        didSet {
            self.pickerTitleLabel.text = self.pickerTitle
        }
    }
    
    /* doneBtnTapped
     *
     * This function will handle the case when the user presses the done button,
     * indicating that they have finished selecting categories and would like for
     * these preferences to be saved.
     */
    @IBAction func doneBtnTapped(_ sender: UIButton) {
        self.selectedCategories = []
        if let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems {
            for indexPath in selectedIndexPaths {
                self.selectedCategories.append(self.categories[indexPath.row])
            }
        }
        self.delegate?.didFinishSelectingCategories(viewController: self, categories: self.selectedCategories)
    }
    
    // button to indicate user has finished updating preferences
    @IBOutlet weak var doneBtn: UIButton! {
        didSet {
            self.doneBtn.becomeRoundedButton()
            self.doneBtn.setTitle(self.doneBtnTitle, for: .normal)
        }
    }
    
    weak var delegate: DICategoriesPickerViewControllerdelegate?
    
    // all categories allowed by application
    let categories: [String] = DIApp.supportedCategories
    // categories chosen by user
    var selectedCategories: [String] = []
    // whether the close button is displayed
    var hideCloseButton: Bool = false
    // name of the page
    var pickerTitle: String = "Event categories"
    // label for done button
    var doneBtnTitle: String = "Done"
    
    /* viewDidLoad
     *
     * This function is used for the initialization of the view.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        // pre-select
        for cat in self.selectedCategories {
            guard let row = self.categories.index(of: cat) else {
                continue
            }
            let indexpath = IndexPath(row: row, section: 0)
            self.collectionView.selectItem(at: indexpath, animated: true, scrollPosition: .centeredHorizontally)
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

}

extension DICategoriesPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    /* numberOfSections
     *
     * This function is used to define how many sections will be presented.
     */
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /* collectionView
     *
     * This function is used to retrieve the number of available categories.
     */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.categories.count
    }
    
    /* collectionView
     *
     * This function is used to create the display of categories.
     */
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DICategoryCollectionViewCell.className, for: indexPath) as! DICategoryCollectionViewCell
        cell.categoryText = self.categories[indexPath.row]
        return cell
    }
    
  
}

extension DICategoriesPickerViewController: UICollectionViewDelegateFlowLayout {
    /* collectionView
     *
     * This function defines the cell dimensions for the collection view.
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (self.view.frame.size.width - 3 * DICollectionViewCellMargin) / 2
        let cellHeight = DICollectionViewCellHeight
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    /* collectionView
     *
     * This function defines the cell margins for the view.
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return DICollectionViewCellMargin
    }
    
    /* collectionView
     *
     * This function defines the overall view of the collection.
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, DICollectionViewCellMargin, 0, DICollectionViewCellMargin)
    }
}

// MARK: - StoryboardInstantiable
extension DICategoriesPickerViewController: StoryboardInstantiable {
    /* instantiateFromStoryboard
     *
     * This function will instantiate the view from the storyboard.
     */
    static func instantiateFromInstoryboard() -> DICategoriesPickerViewController {
        return DIApp.Storyboard.main.instantiateViewController(withIdentifier: DICategoriesPickerViewController.className) as! DICategoriesPickerViewController
    }
}


