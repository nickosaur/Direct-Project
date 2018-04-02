//
//  DIMediaManager.swift
//  Direct
//
//  Created by Kesong Xie on 10/24/17.
//  Copyright © 2017 ___Direct___. All rights reserved.
//

/* DIMediaManager.swift
 *
 * This class is used to manage uploaded video content. When a user uploads
 * a video, it should be stored in the database, and there should be a thumbnail
 * generated from the video which can be displayed in lieu of the video in case
 * the content is unable to load for a user at some point during use of the app.
 */

import UIKit
import AVFoundation

// limitations on media size
fileprivate let maxThumbnailSize = CGSize(width: 600.0, height: 600.0)

class DIMediaManager {
    
    /* saveVideo
     *
     * This function is used to save a video and a thumbnail cover image to firebase
     * storage. It returns the downloaded paths for the saved items.
     */
    // MARK: - Public interface
    class func saveVideo(assetURL: URL, completionHandler: @escaping (DIVideoModel?) -> Void) {
        if let videoData = try? Data(contentsOf: assetURL) {
            let avasset = AVAsset(url: assetURL)
            guard let thumbnailCoverData = DIMediaManager.generateThumbnailImage(fromAsset: avasset) else {
                return
            }
            let videoModel = DIVideoModel(data: videoData, thumbnailData: thumbnailCoverData)
            // sync would upload the asset to the firebase
            videoModel.sync(completionBlock: { (videoModel) in
                // once the video is saved, use the path as the video url
                completionHandler(videoModel)
            })
        }
    }
    
    /* getVideoOrientationFromAsset
     *
     * This function is used to retrieve a stored video in its proper orientation.
     */
    // MARK: - Private interface
    class func getVideoOrientationFromAsset(avasset: AVAsset) -> UIImageOrientation?{
        guard let videoTrack = avasset.tracks(withMediaType: AVMediaType.video).first else {
            print("asset track is empty")
            return nil
        }
        let size = videoTrack.naturalSize
        let txf = videoTrack.preferredTransform
        if size.width == txf.tx && size.height == txf.ty {
            return UIImageOrientation.left // UIInterfaceOrientationLandscapeLeft
        } else if txf.tx == 0 && txf.ty == 0 {
            return UIImageOrientation.right //UIInterfaceOrientationLandscapeRight
        } else if txf.tx == 0 && txf.ty == size.width {
            return UIImageOrientation.down //UIInterfaceOrientationPortraitUpsideDown
        } else {
            return UIImageOrientation.up //UIInterfaceOrientationPortrait
        }
    }
    
    
    /* generateThumbnailImage
     *
     * This function will get the thumbnail image data to be used as the video
     * cover.
     */
    private class func generateThumbnailImage(fromAsset asset: AVAsset) -> Data? {
        //get a thumbnail from the video
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        if let cgImage = try? imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil){
            return UIImageJPEGRepresentation(UIImage(cgImage: cgImage), 0.8)
        }
        return nil
    }
    
    /* createRandomFileName
     *
     * This function is used to create a random temporary directory.
     */
    private class func createRandomFileName(withExtension ext: String) -> String{
        let filename = UUID().uuidString.appending(ext)
        return NSTemporaryDirectory().appending(filename)
    }
    
    /* resizeImage
     *
     * This function is used to resize a given image
     */
    private class func resizeImage(image: UIImage, resizeTo size: CGSize) -> UIImage? {
        let hasAlpha = false
        let scale: CGFloat = 1.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}
